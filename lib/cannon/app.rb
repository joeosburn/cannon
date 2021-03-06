require 'lspace/eventmachine'

module Cannon
  # Base cannon app class
  class App
    extend Forwardable

    attr_reader :subapps, :runtime

    delegate root: :runtime
    delegate logger: :runtime
    delegate cache: :runtime

    def initialize
      @runtime ||= Runtime.new(File.dirname(caller[2].split(':')[0]))
      $LOAD_PATH << root
    end

    def middleware
      @middleware ||= Middlewares.new(self, config[:middleware])
    end

    def config
      @config ||= Config.new
    end

    def mount(subapp, at:)
      ware = middleware.unshift('Subapp').first
      ware.subapp = subapp
      ware.mount_point = at
      subapp.mount_on(self)
    end

    def mount_on(app)
      @runtime = app.runtime
    end

    def handle_error(error, request, response)
      request.handle
      log_error(error)
      send_response_error(response, error)
    end

    def handle(request, response, finish_proc = nil)
      request.app = self
      response.app = self

      finish_proc ||= -> { response.not_found }

      MiddlewareRunner.new(middleware, request, response, finish_proc).run
    end

    private

    def send_response_error(response, error)
      response.internal_server_error(title: error.message, content: error.backtrace.join('<br/>'))
      response.flush
    end

    def log_error(error)
      logger.error error.message
      logger.error error.backtrace.join("\n")
    end
  end
end
