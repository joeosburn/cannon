require 'mustache'

module Cannon
  module Views
    include PathCache

    def view(filename)
      if renderable?(filename)
        render(filename)
      else
        raw_view(filename)
      end
    end

    def context
      @context ||= {}
    end

  protected

    def initialize_views
      self.cache_key = :views
      self.base_path = build_view_path
    end

  private

    def renderable?(filename)
      filename.split('.').last == 'mustache'
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
      @app.config.view_path =~ /^\// ? @app.config.view_path : "#{@app.runtime.root}/#{@app.config.view_path}"
    end
  end
end
