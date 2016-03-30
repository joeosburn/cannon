module Cannon
  module Middleware
    class Files
      include PathCache

      attr_accessor :path_array

      def initialize(app)
        @app = app

        self.cache_key = :files
        self.base_path = build_base_path
        self.path_array = build_path_array
      end

      def run(request, response, next_proc)
        return next_proc.call if request.handled?

        if path_array.include? request.path
          file, content_type = *file_and_content_type("#{base_path}#{request.path}")
          response.header('Content-Type', content_type) if content_type
          response.send(file)
          request.handle!
        end

        next_proc.call
      end

    private

      def build_path_array
        Dir.glob("#{base_path}/**/*").reject { |file| File.directory?(file) }.collect do |name|
          name.gsub(/^#{base_path}/, '')
        end
      end

      def build_base_path
        @app.config.public_path =~ /^\// ? @app.config.public_path : "#{@app.runtime.root}/#{@app.config.public_path}"
      end
    end
  end
end
