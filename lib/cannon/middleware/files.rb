module Cannon
  module Middleware
    class Files
      def initialize(app)
        @app = app
        @base_path = build_base_path
        @signature = nil
      end

      def run(request, response, next_proc)
        reload_cache if outdated_cache?

        if @public_path_array.include? request.path
          file, content_type = *file_and_content_type("#{@base_path}#{request.path}")
          response.header('Content-Type', content_type)
          response.send(file)
          response.flush
        else
          next_proc.call
        end
      end

    private

      def file_and_content_type(filepath)
        if @app.cache[:files].include?(filepath)
          @app.cache[:files][filepath]
        else
          @app.cache[:files][filepath] = read_file_and_content_type(filepath)
        end
      end

      def read_file_and_content_type(filepath)
        [IO.binread(filepath), Cannon.mime_type(filepath)]
      end

      def build_base_path
        @app.config.public_path =~ /^\// ? @app.config.public_path : "#{Cannon.root}/#{@app.config.public_path}"
      end

      def outdated_cache?
        if @app.config.reload_on_request
          @signature != public_path_signature
        else
          @signature.nil?
        end
      end

      def reload_cache
        @signature = public_path_signature
        @public_path_array = build_public_path_array
        @app.cache[:files] = {}
      end

      def public_path_signature
        Dir.glob("#{@base_path}/**/*").map do |name|
          [name, File.mtime(name)].to_s
        end.inject(Digest::SHA512.new) do |digest, x|
          digest.update x
        end.to_s
      end

      def build_public_path_array
        Dir.glob("#{@base_path}/**/*").reject { |file| File.directory?(file) }.collect do |name|
          name.gsub(/^#{@base_path}/, '')
        end
      end
    end
  end
end
