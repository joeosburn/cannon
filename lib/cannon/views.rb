require 'mustache'

module Cannon
  module Views
    def view(filename, options = {})
      filepath = "#{@view_path}/#{filename}"
      view_data = IO.binread(filepath)
      mime_type = Cannon.mime_type(filepath)
      header('Content-Type', mime_type) if mime_type
      send(Mustache.render(view_data, options), status: status)
    end
  end
end
