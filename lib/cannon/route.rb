module Cannon
  class Route
    attr_reader :path, :actions, :redirect

    def initialize(app, path:, actions: nil, redirect: nil)
      path = '/' + path unless path =~ /^\// # ensure path begins with '/'

      @app, @path, @redirect = app, path, redirect
      @actions = actions || []
      @route_action = build_route_action(@actions.dup)
    end

    def matches?(path)
      self.path == path
    end

    def handle(request, response)
      if redirect
        response.permanent_redirect(redirect)
      elsif @route_action
        begin
          @route_action.run(request, response)
        rescue => error
          puts error.message
          puts error.backtrace
          response.internal_server_error(title: error.message, content: error.backtrace.join('<br/>'))
        end
      end
    end

    def to_s
      "Route: #{path}"
    end

  private

    def build_route_action(actions, callback: nil)
      return callback if actions.size < 1

      route_action = RouteAction.new(@app, action: actions.pop, callback: callback)
      build_route_action(actions, callback: route_action)
    end
  end

  class RouteAction
    include EventMachine::Deferrable

    def initialize(app, action:, callback:)
      @app, @action, @callback = app, action, callback
    end

    def run(request, response)
      if @action.is_a? Proc
        puts 'Action: Inline'
        @action.call(request, response)
      else
        puts "Action: #{@action}"
        @app.app_binding.send(@action, request, response)
      end
      
      if response.flushed?
        fail
      else
        setup_callback
        succeed(request, response)
      end
    end

  private

    def setup_callback
      set_deferred_status nil
      callback do |request, response|
        @callback.run(request, response) unless @callback.nil?
      end
    end
  end
end
