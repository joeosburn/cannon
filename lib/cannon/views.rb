require 'mustache'

module Cannon
  module Views
    include PathCache

    def view(filename)
      reload_cache if outdated_cache?

      file, content_type = *file_and_content_type("#{base_path}/#{filename}")
      header('Content-Type', content_type)
      send(Mustache.render(file, context), status: status)
    end

    def context
      @context ||= {}
    end

  protected

    def initialize_views
      self.cache = :views
      self.base_path = build_view_path
    end

  private

    def build_view_path
      @app.config.view_path =~ /^\// ? @app.config.view_path : "#{@app.runtime.root}/#{@app.config.view_path}"
    end
  end
end
