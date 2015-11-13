module Cannon
  class Response
    extend Forwardable

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

    def initialize(http_server, app)
      @delegated_response = EventMachine::DelegatedHttpResponse.new(http_server)
      @flushed = false
      @headers = {}
      @view_path = "#{Cannon.root}/#{app.config.view_path}"

      self.status = :ok
    end

    def flushed?
      @flushed
    end

    def send(content, status: self.status)
      self.content ||= ''
      self.status = status
      delegated_response.status = converted_status(status)
      delegated_response.content += content
      delegated_response.headers = self.headers
    end

    def flush
      unless flushed?
        send('')
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
      send(html, status: :internal_server_error)
    end

    def view(filename, status: :ok)
      filepath = "#{@view_path}/#{filename}"
      view_data = IO.binread(filepath)
      mime_type = Cannon.mime_type(filepath)
      header('Content-Type', mime_type) if mime_type
      send(view_data, status: status)
    end

  private

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
