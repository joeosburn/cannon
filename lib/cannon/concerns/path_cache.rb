module PathCache
  def self.included(base)
    base.send(:attr_accessor, :base_path, :cache)
    base.send(:attr_reader, :path_array)
  end

private

  def file_and_content_type(filepath)
    if @app.cache[cache].include?(filepath)
      @app.cache[cache][filepath]
    else
      @app.cache[cache][filepath] = read_file_and_content_type(filepath)
    end
  end

  def read_file_and_content_type(filepath)
    [IO.binread(filepath), Cannon.mime_type(filepath)]
  end

  def outdated_cache?
    if @app.config.reload_on_request
      @last_path_signature != current_path_signature
    else
      @last_path_signature.nil?
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
