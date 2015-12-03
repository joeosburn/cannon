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
        reload_cache if outdated_cache?

        if path_array.include? request.path
          file, content_type = *file_and_content_type("#{base_path}#{request.path}")
          response.header('Content-Type', content_type)
          response.send(file)
          response.flush
        else
          next_proc.call
        end
      end

    private

      def build_base_path
        @app.config.public_path =~ /^\// ? @app.config.public_path : "#{Cannon.root}/#{@app.config.public_path}"
      end
    end
  end
end
