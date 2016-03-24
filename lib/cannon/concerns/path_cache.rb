require 'mime/types'

module PathCache
  def self.included(base)
    base.send(:attr_accessor, :base_path, :cache)
    base.send(:attr_reader, :path_array)
  end

private

  def file(filepath)
    file_and_content_type(filepath)[0]
  end

  def file_and_content_type(filepath)
    if @app.cache[cache].include?(filepath)
      @app.cache[cache][filepath]
    else
      @app.cache[cache][filepath] = read_file_and_content_type(filepath)
    end
  end

  def read_file_and_content_type(filepath)
    [IO.binread(filepath), mime_type(filepath)]
  end

  def mime_type(filepath)
    MIME::Types.type_for(filepath.split('/').last).first
  end

  def outdated_cache?
    if @app.runtime.config.cache_app
      @last_path_signature.nil?
    else
      @last_path_signature != current_path_signature
    end
  end

  def reload_cache
    @last_path_signature = current_path_signature
    @path_array = build_path_array
    @app.cache[cache] = {}
  end

  def current_path_signature
    Dir.glob("#{base_path}/**/*").map do |name|
      [name, File.mtime(name)].to_s
    end.inject(Digest::SHA512.new) do |digest, x|
      digest.update x
    end.to_s
  end

  def build_path_array
    Dir.glob("#{base_path}/**/*").reject { |file| File.directory?(file) }.collect do |name|
      name.gsub(/^#{base_path}/, '')
    end
  end
end
