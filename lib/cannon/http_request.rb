module Cannon
    class HttpRequest
    attr_accessor :protocol, :method, :cookie, :content_type, :path, :uri, :query_string, :post_content, :headers

    def initialize(http_server)
      self.protocol = http_server.instance_variable_get('@http_protocol')
      self.method = http_server.instance_variable_get('@http_request_method')
      self.cookie = http_server.instance_variable_get('@http_cookie')
      self.content_type = http_server.instance_variable_get('@http_content_type')
      self.path= http_server.instance_variable_get('@http_path_info')
      self.uri = http_server.instance_variable_get('@http_request_uri')
      self.query_string = http_server.instance_variable_get('@http_query_string')
      self.post_content = http_server.instance_variable_get('@http_post_content')
      self.headers = http_server.instance_variable_get('@http_headers')
    end
  end
end
