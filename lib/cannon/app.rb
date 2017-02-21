require 'lspace/eventmachine'

module Cannon
  # Base cannon app class
  class App
    extend Forwardable

    attr_reader :routes, :subapps, :runtime

    delegate root: :runtime
    delegate logger: :runtime
    delegate cache: :runtime

    def initialize
      @runtime ||= Runtime.new(File.dirname(caller[2].split(':')[0]))
      $LOAD_PATH << root
    end

    def config
      @config ||= Config.new
    end

    def mount(app, at:)
      subapps[at] = app
      app.mount_on(self)
    end

    def mount_on(app)
      @runtime = app.runtime
    end

    def subapps
      @subapps ||= {}
    end

    def handle_error(error, request, response)
      request.handle
      log_error(error)
      send_response_error(response, error)
    end

    def handle(request, response)
      request.app = self
      response.app = self

      subapps.each do |mount_point, subapp|
        request.at_mount_point(mount_point) do
          subapp.handle(request, response)
        end
      end
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
