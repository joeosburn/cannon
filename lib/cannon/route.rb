module Cannon
  class Route
    attr_writer :cache
    attr_reader :path, :method
    attr_accessor :actions, :redirect

    def initialize(path, actions, app:)
      @path = build_path(path)
      @app = app
      @route_action = build_route_action(actions)
      @cache = true
    end

    def method=(new_method)
      @method = new_method.to_s.upcase
    end

    def add_route_action(action)
      @route_action.last_action.callback = RouteAction.new(@app, action: action, route: self, callback: nil)
    end

    def matches?(request)
      matched_method?(request.method) && matched_path?(request.path)
    end

    def cache?
      @cache
    end

    def handle(request, response, finish_proc)
      request.handle!

      if redirect
        response.permanent_redirect(redirect)
      elsif @route_action
        populate_request_params(request)
        @route_action.run(request, response, finish_proc)
      end
    end

    def populate_request_params(request)
      matches = matched_path(request.path)

      index = 0
      while index < @params.size
        request.params[@params[index].to_sym] = matches.captures[index]
        index += 1
      end
    end

    def to_s
      "Route: #{path}"
    end

  private

    def matched_method?(request_method)
      method == 'ALL' || request_method == method
    end

    def matched_path?(path)
      matched_path(path) != nil
    end

    def matched_path(path)
      # cache the matched path so that we don't have to keep re-matching it
      if @last_matched_path != path
        @matched_path = self.path.match(path)
        @last_matched_path = path
      end

      @matched_path
    end

    def build_path(path)
      path = '/' + path unless path =~ /^\// # ensure path begins with '/'
      path.gsub!('/', '\/')

      @params = path.scan(/:[a-zA-Z0-9_]+/).map { |param| param[1..-1] }
      @params.each { |param| path.gsub!(":#{param}", '([^\/]+)') }

      /^#{path}$/
    end

    def build_route_action(actions, callback: nil)
      return callback if actions.size < 1

      route_action = RouteAction.new(@app, action: actions.pop, route: self, callback: callback)
      build_route_action(actions, callback: route_action)
    end
  end
end
