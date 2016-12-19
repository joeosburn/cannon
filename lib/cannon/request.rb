require 'cgi'

module Cannon
  class Request
    attr_accessor :protocol, :method, :http_cookie, :content_type, :path, :uri, :query_string, :post_content,
                  :http_headers, :start_time

    attr_reader :app, :response

    def initialize(http_server, app, response:)
      self.protocol = http_server.instance_variable_get('@http_protocol')
      self.method = http_server.instance_variable_get('@http_request_method')
      self.http_cookie = http_server.instance_variable_get('@http_cookie')
      self.content_type = http_server.instance_variable_get('@http_content_type')
      self.path = http_server.instance_variable_get('@http_path_info')
      self.uri = http_server.instance_variable_get('@http_request_uri')
      self.query_string = http_server.instance_variable_get('@http_query_string')
      self.post_content = http_server.instance_variable_get('@http_post_content')
      self.http_headers = http_server.instance_variable_get('@http_headers')
      self.start_time = Time.now
      @app = app
      @response = response

      @handled = false
    end

    def finish
      @response.flush unless @response.flushed?
      benchmark_request if @app.runtime.config.benchmark_requests
    end

    def params
      @params ||= parse_params
    end

    def handled?
      @handled
    end

    def handle!
      @handled = true
    end

    def headers
      @headers ||= parse_headers
    end

    def not_found
      @response.send('Not Found', status: :not_found)
    end

    def internal_server_error(title:, content:)
      html = "<html><head><title>Internal Server Error: #{title}</title></head><body><h1>#{title}</h1><p>#{content}</p></body></html>"
      @response.header('Content-Type', 'text/html')
      @response.send(html, status: :internal_server_error)
    end

    def request_id
      @request_id ||= retrieve_request_id
    end

    def to_s
      "#{method} #{path}"
    end

  private

    def retrieve_request_id
      header_request_id || generate_request_id
    end

    def header_request_id
      headers['X-Request-Id'][0..254] if headers.include?('X-Request-Id') && headers['X-Request-Id'].length > 0
    end

    def generate_request_id
      return nil unless app.runtime.config.generate_request_ids

      id = SecureRandom.hex(18)
      id[8] = '-'
      id[13] = '-'
      id[18] = '-'
      id[23] = '-'
      id
    end

    def benchmark_request
      @app.logger.debug "Response took #{time_ago_in_ms(start_time)}ms"
    end

    def time_ago_in_ms(time_ago)
      Time.at((Time.now - time_ago)).strftime('%6N').to_i/1000.0
    end

    def parse_headers
      Hash[http_headers.split("\x00").map { |header| header.split(': ', 2) }]
    end

    def parse_params
      case method.downcase
      when 'get'
        Hash[CGI::parse(query_string || '').map { |(k, v)| [k.to_sym, v.last] }]
      else
        Hash[CGI::parse(post_content || '').map { |(k, v)| [k.to_sym, v.count > 1 ? v : v.first] }]
      end
    end
  end
end
