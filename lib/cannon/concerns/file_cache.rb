require 'mime/types'

# Concern which provides cached file loading with content types
module FileCache
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
    mime_types(filepath.split('/').last).first
  end

  def mime_types(filename)
    MIME::Types.type_for(filename)
  end

  def cache
    @app.cache[cache_key] ||= {}
  end
end
