module Cannon
  class HttpResponse
    attr_reader :delegated_response, :headers
    attr_accessor :content, :status

    HTTP_STATUS_CODES = {
      100 => '100 Continue',
      101 => '101 Switching Protocols',
      200 => '200 OK',
      201 => '201 Created',
      202 => '202 Accepted',
      203 => '203 Non-Authoritative Information',
      204 => '204 No Content',
      205 => '205 Reset Content',
      206 => '206 Partial Content',
      300 => '300 Multiple Choices',
      301 => '301 Moved Permanently',
      302 => '302 Found',
      303 => '303 See Other',
      304 => '304 Not Modified',
      305 => '305 Use Proxy',
      307 => '307 Temporary Redirect',
      400 => '400 Bad Request',
      401 => '401 Unauthorized',
      402 => '402 Payment Required',
      403 => '403 Forbidden',
      404 => '404 Not Found',
      405 => '405 Method Not Allowed',
      406 => '406 Not Acceptable',
      407 => '407 Proxy Authentication Required',
      408 => '408 Request Timeout',
      409 => '409 Conflict',
      410 => '410 Gone',
      411 => '411 Length Required',
      412 => '412 Precondition Failed',
      413 => '413 Request Entity Too Large',
      414 => '414 Request-URI Too Long',
      415 => '415 Unsupported Media Type',
      416 => '416 Requested Range Not Satisfiable',
      417 => '417 Expectation Failed',
      500 => '500 Internal Server Error',
      501 => '501 Not Implemented',
      502 => '502 Bad Gateway',
      503 => '503 Service Unavailable',
      504 => '504 Gateway Timeout',
      505 => '505 HTTP Version Not Supported',
    }

    HTTP_STATUS_SHORTCUTS = {
      continue: 100,
      switching_protocols: 101,
      ok: 200,
      created: 201,
      accepted: 202,
      non_authoritative_information: 203,
      no_content: 204,
      reset_content: 205,
      partial_content: 206,
      multiple_choices: 300,
      moved_permanently: 301,
      found: 302,
      see_other: 303,
      not_modified: 304,
      use_proxy: 305,
      temporary_redirect: 307,
      bad_request: 400,
      unauthorized: 401,
      payment_required: 402,
      forbidden: 403,
      not_found: 404,
      method_not_allowed: 405,
      not_acceptable: 406,
      proxy_authentication_required: 407,
      request_timeout: 408,
      conflict: 409,
      gone: 410,
      length_required: 411,
      precondition_failed: 412,
      request_entity_too_large: 413,
      request_uri_too_long: 414,
      unsupported_media_type: 415,
      requested_range_not_satisfied: 416,
      expectation_failed: 417,
      internal_server_error: 500,
      not_implemented: 501,
      bad_gateway: 502,
      service_unavailable: 503,
      gateway_timeout: 504,
      http_version_not_supported: 505,
    }

    def initialize(http_server)
      @delegated_response = EventMachine::DelegatedHttpResponse.new(http_server)
      @sent = false
      @headers = {}

      self.content = ''
      self.status = :ok
    end

    def sent?
      @sent
    end

    def send(content = self.content, status: self.status)
      unless @sent
        delegated_response.status = converted_status(status)
        delegated_response.content = content
        delegated_response.headers = self.headers
        delegated_response.send_response
        @sent = true
      end
    end

    def header(key, value)
      headers[key] = value
    end

    def location_header(location)
      header('Location', location)
    end

    def permanent_redirect(location)
      location_header(location)
      self.status = :moved_permanently
      send
    end

    def temporary_redirect(location)
      location_header(location)
      self.status = :found
      send
    end

    def not_found
      send('Not Found', status: 404)
    end

  private

    def converted_status(status)
      if status.is_a?(Symbol)
        converted_status(HTTP_STATUS_SHORTCUTS[status] || status.to_s)
      elsif status.is_a?(Fixnum)
        HTTP_STATUS_CODES[status] || status.to_s
      else
        status.to_s
      end
    end
  end
end
