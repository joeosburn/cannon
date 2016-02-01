module Cannon
  module Middleware
    class Files
      include PathCache

      def initialize(app)
        @app = app

        self.cache = :files
        self.base_path = build_base_path
      end

      def run(request, response, next_proc)
        return next_proc.call if request.handled?

        reload_cache if outdated_cache?

        if path_array.include? request.path
          file, content_type = *file_and_content_type("#{base_path}#{request.path}")
          response.header('Content-Type', content_type)
          response.send(file)
          request.handle!
        end

        next_proc.call
      end

    private

      def build_base_path
        @app.config.public_path =~ /^\// ? @app.config.public_path : "#{@app.runtime.root}/#{@app.config.public_path}"
      end
    end
  end
end
