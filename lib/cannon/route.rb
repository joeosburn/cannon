module Cannon
  class Route
    attr_reader :path, :actions, :redirect, :method

    def initialize(path, app:, method:, actions: nil, redirect: nil, cache:)
      @path = build_path(path)
      @method, @app, @redirect = method.to_s.upcase, app, redirect
      @actions = actions || []
      @route_action = build_route_action(@actions.dup)
      @cache = cache
    end

    def add_route_action(action)
      @route_action.last_action.callback = RouteAction.new(@app, action: action, route: self, callback: nil)
    end

    def matches?(request)
      return false unless method == 'ALL' || request.method == method

      matches = self.path.match(request.path)
      if matches.nil?
        false
      else
        @params.each_with_index { |key, index| request.params[key.to_sym] = matches.captures[index] }
        true
      end
    end

    def cache?
      @cache
    end

    def handle(request, response, finish_proc)
      request.handle!

      if redirect
        response.permanent_redirect(redirect)
      elsif @route_action
        begin
          @route_action.run(request, response, finish_proc)
        rescue => error
          @app.logger.error error.message
          @app.logger.error error.backtrace.join("\n")
          response.internal_server_error(title: error.message, content: error.backtrace.join('<br/>'))
          finish_proc.call
        end
      end
    end

    def to_s
      "Route: #{path}"
    end

  private

    def build_path(path)
      path = '/' + path unless path =~ /^\// # ensure path begins with '/'
      @params = []

      if path.include? ':'
        param_path_to_regexp(path)
      else
        /^#{path.gsub('/', '\/')}$/
      end
    end

    def param_path_to_regexp(path)
      /^#{path.split('/').map { |part| normalize_path_part(part) }.join('\/')}$/
    end

    def normalize_path_part(part)
      if part =~ /^:(.+)/
        @params << $1
        '([^\/]+)'
      else
        part
      end
    end

    def build_route_action(actions, callback: nil)
      return callback if actions.size < 1

      route_action = RouteAction.new(@app, action: actions.pop, route: self, callback: callback)
      build_route_action(actions, callback: route_action)
    end
  end
end
