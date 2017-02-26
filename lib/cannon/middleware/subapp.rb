module Cannon
  module Middleware
    # Middleware template for subapps
    class Subapp
      attr_accessor :mount_point, :subapp

      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        return next_proc.call if request.handled?

        if request.path =~ /^#{mount_point}/
          request.mount_at(mount_point)
          subapp.handle(request, response, -> { request.unmount; next_proc.call })
        else
          next_proc.call
        end
      end
    end
  end
end
