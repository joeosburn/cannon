module Cannon
  module Middleware
    # Middleware for handlng raw binary file sending
    class Files
      include FileCache

      def initialize(app)
        @app = app
      end

      def run(request, response, next_proc)
        if valid_file_request?(request)
          file, content_type = *file_and_content_type("#{base_path}#{request.path}")
          response.header('Content-Type', content_type) if content_type
          response.send(file)
          request.handle
        end

        next_proc.call
      end

      private

      def valid_file_request?(request)
        path_array.include?(request.path)
      end

      def cache_key
        :files
      end

      def path_array
        @path_array ||= build_path_array
      end

      def base_path
        @base_path ||= prepared_config_public_path
      end

      def build_path_array
        Dir.glob("#{base_path}/**/*").reject { |file| File.directory?(file) }.collect do |name|
          name.gsub(/^#{base_path}/, '')
        end
      end

      def prepared_config_public_path
        config_public_path_relative? ? @app.config[:public_path] : absolute_config_public_path
      end

      def config_public_path_relative?
        @app.config[:public_path] =~ %r{^\/}
      end

      def absolute_config_public_path
        "#{@app.runtime.root}/#{@app.config[:public_path]}"
      end
    end
  end
end
