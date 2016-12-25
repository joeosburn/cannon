require 'mustache'

module Cannon
  # Basic view support for Response
  module Views
    include FileCache

    def view(filename)
      if filename.split('.').last == 'mustache'
        render(filename)
      else
        raw_view(filename)
      end
    end

    def context
      @context ||= {}
    end

  private

    def cache_key
      :views
    end

    def base_path
      @base_path ||= build_view_path
    end

    def render(filename)
      file = file(full_path(filename))
      content_type = mime_type(filename.split('.')[0..-2].join('.'))
      header('Content-Type', content_type) if content_type
      send(Mustache.render(file, context), status: status)
    end

    def raw_view(filename)
      file, content_type = *file_and_content_type(full_path(filename))
      header('Content-Type', content_type) if content_type
      send(file, status: status)
    end

    def full_path(filename)
      "#{base_path}/#{filename}"
    end

    def build_view_path
      app_view_path_relative? ? @app.config[:view_path] : full_view_path
    end

    def app_view_path_relative?
      @app.config[:view_path] =~ /^\//
    end

    def full_view_path
      "#{@app.runtime.root}/#{@app.config[:view_path]}"
    end
  end
end
