require 'filemagic'

module Cannon
  module Middleware
    class Files
      def initialize(app)
        @app = app
        @base_path = "#{Dir.getwd}/#{@app.public_path}"
        @signature = ''
      end

      def run(request, response)
        reload_cache if outdated_cache?

        if @public_path_array.include? request.path
          file_path = "#{@base_path}#{request.path}"
          content_type = FileMagic.new(FileMagic::MAGIC_MIME).file(file_path)
          response.header('Content-Type', content_type)
          response.send(IO.binread(file_path), status: :ok)
        end
      end

    private

      def outdated_cache?
        @signature != public_path_signature
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