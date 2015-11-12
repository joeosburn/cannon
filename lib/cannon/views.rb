module Cannon
  module Views
    def view(filename, status: :ok)
      filepath = "#{@view_path}/#{filename}"
      view_data = IO.binread(filepath)
      mime_type = Cannon.mime_type(filepath)
      header('Content-Type', mime_type) if mime_type
      send(view_data, status: status)
    end
  end
end
