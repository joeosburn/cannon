require 'mime/types'

module PathCache
  def self.included(base)
    base.send(:attr_accessor, :base_path, :cache_key)
  end

private

  def file(filepath)
    file_and_content_type(filepath)[0]
  end

  def file_and_content_type(filepath)
    if cache.include?(filepath)
      cache[filepath]
    else
      cache[filepath] = read_file_and_content_type(filepath)
    end
  end

  def read_file_and_content_type(filepath)
    [IO.binread(filepath), mime_type(filepath)]
  end

  def mime_type(filepath)
    MIME::Types.type_for(filepath.split('/').last).first
  end

  def cache
    @app.cache[cache_key] ||= {}
  end
end
