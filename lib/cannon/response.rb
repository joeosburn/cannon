require 'msgpack'

module Cannon
  class Response
    extend Forwardable
    include Views

    attr_reader :delegated_response, :headers
    attr_accessor :status

    delegate :content => :delegated_response
    delegate :content= => :delegated_response

    HTTP_STATUS = {
      continue:                      100,
      switching_protocols:           101,
      ok:                            200,
      created:                       201,
      accepted:                      202,
      non_authoritative_information: 203,
      no_content:                    204,
      reset_content:                 205,
      partial_content:               206,
      multiple_choices:              300,
      moved_permanently:             301,
      found:                         302,
      see_other:                     303,
      not_modified:                  304,
      use_proxy:                     305,
      temporary_redirect:            307,
      bad_request:                   400,
      unauthorized:                  401,
      payment_required:              402,
      forbidden:                     403,
      not_found:                     404,
      method_not_allowed:            405,
      not_acceptable:                406,
      proxy_authentication_required: 407,
      request_timeout:               408,
      conflict:                      409,
      gone:                          410,
      length_required:               411,
      precondition_failed:           412,
      request_entity_too_large:      413,
      request_uri_too_long:          414,
      unsupported_media_type:        415,
      requested_range_not_satisfied: 416,
      expectation_failed:            417,
      internal_server_error:         500,
      not_implemented:               501,
      bad_gateway:                   502,
      service_unavailable:           503,
      gateway_timeout:               504,
      http_version_not_supported:    505,
    }

    def initialize(http_server, app, request: nil)
      @app = app
      @delegated_response = EventMachine::DelegatedHttpResponse.new(http_server)
      @flushed = false
      @headers = {}
      @request = request

      initialize_views

      self.status = :ok
    end

    def finish
      flush unless flushed?
      benchmark_request(@request) if @app.runtime.config.benchmark_requests
    end

    def flushed?
      @flushed
    end

    def send(content, status: self.status)
      self.content ||= ''
      self.status = status
      delegated_response.status = converted_status(status)
      delegated_response.content += content
    end

    def flush
      unless flushed?
        set_cookie_headers
        delegated_response.headers = self.headers
        delegated_response.send_response
        @flushed = true
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
      flush
    end

    def temporary_redirect(location)
      location_header(location)
      self.status = :found
      flush
    end

    def not_found
      send('Not Found', status: :not_found)
    end

    def internal_server_error(title:, content:)
      html = "<html><head><title>Internal Server Error: #{title}</title></head><body><h1>#{title}</h1><p>#{content}</p></body></html>"
      header('Content-Type', 'text/html')
      send(html, status: :internal_server_error)
    end

  private

    def benchmark_request(request)
      @app.logger.debug "Response took #{time_ago_in_ms(request.start_time)}ms"
    end

    def time_ago_in_ms(time_ago)
      Time.at((Time.now - time_ago)).strftime('%6N').to_i/1000.0
    end

    def set_cookie_headers
      cookie_values = []
      cookie_values += @request.cookies.assigned_cookie_values if @request.respond_to?(:cookies)
      cookie_values += @request.signed_cookies.assigned_cookie_values if @request.respond_to?(:signed_cookies)

      return unless cookie_values.size > 0

      cookie_headers = (headers['Set-Cookie'] = [])
      cookie_values.each { |cookie_value| cookie_headers << cookie_value }
    end

    def converted_status(status)
      if status.is_a?(Symbol)
        HTTP_STATUS[status] || status.to_s
      elsif status.is_a?(Fixnum)
        status
      else
        status.to_s
      end
    end
  end
end
