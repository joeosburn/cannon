require 'pry'
require 'lspace/eventmachine'

module Cannon
  # Base cannon app class
  class App
    extend Forwardable

    attr_reader :routes, :subapps

    delegate ip_address: :runtime, port: :runtime, root: :runtime

    def initialize(port: nil, ip_address: nil)
      @subapps = {}
      @mounted_on = nil
      @runtime ||= Runtime.new(File.dirname(caller[2].split(':')[0]), ip_address, port)
      $LOAD_PATH << root
    end

    def mount(app, at:)
      @subapps[at] = app
      app.mount_on(self)
    end

    def console
      command_set = Pry::CommandSet.new {}
      Pry.start binding, commands: command_set
    end

    def config
      @config ||= Config.new
    end

    def mount_on(app)
      @mounted_on = app
    end

    def runtime
      @mounted_on ? @mounted_on.runtime : @runtime
    end

    def cache
      runtime.cache
    end

    def logger
      runtime.logger
    end

    def handle_error(error, request, response)
      request.handle
      log_error(error)
      send_response_error(response, error)
      request.finish
    end

    def handle(request, response)
      subapps.each do |mounted_at, subapp|
        request.attempt_mount(mounted_at) do
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
