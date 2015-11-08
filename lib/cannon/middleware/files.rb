module Cannon
  module Middleware
    class Files
      def initialize(app)
        @app = app
        @base_path = "#{Cannon.root}/#{@app.public_path}"
        @signature = nil
      end

      def run(request, response)
        reload_cache if outdated_cache?

        if @public_path_array.include? request.path
          file_path = "#{@base_path}#{request.path}"
          content_type = Cannon.mime_types.type_for(file_path.split('/').last).first
          response.header('Content-Type', content_type)
          response.send(IO.binread(file_path))
          response.flush
          false
        end
      end

    private

      def outdated_cache?
        if Cannon.env.production?
          @signature.nil?
        else
          @signature != public_path_signature
        end
      end

      def reload_cache
        @public_path_array = build_public_path_array
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
