require 'msgpack'

module Cannon
  class Response
    extend Forwardable
    include Views

    attr_reader :delegated_response
    attr_accessor :status

    delegate :content => :delegated_response
    delegate :content= => :delegated_response
    delegate :headers => :delegated_response
    delegate :cookies => :delegated_response

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
      @app = app
      @delegated_response = RecordedDelegatedResponse.new(http_server)
      @flushed = false

      initialize_views

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
    end

    def flush
      unless flushed?
        delegated_response.send_headers
        delegated_response.send_response
        @flushed = true
      end
    end

    def header(key, value)
      delegated_response.header(key, value)
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

  class RecordedDelegatedResponse
    attr_reader :headers

    def initialize(http_server)
      @delegated_response = EventMachine::DelegatedHttpResponse.new(http_server)
      @recording = false
      @headers = {}
      @cookies = {}
    end

    def start_recording
      method_stack.clear
      @recording = true
    end

    def stop_recording
      @recording = false
    end

    def recording?
      @recording
    end

    def recording
      method_stack
    end

    def header(key, value)
      method_stack << [:header, [key, value], nil]
      @headers[key] = value
    end

    def cookies(key, value)
      method_stack << [:cookies, [key, value], nil]
      @cookies[key] = value
      header('Set-Cookie', @cookies.collect { |k, v| v })
    end

    def send_headers
      @delegated_response.headers = headers
    end

    def method_missing(sym, *args, &block)
      method_stack << [sym, args, block] if recording?
      @delegated_response.send(sym, *args, &block)
    end

  private

    def method_stack
      @method_stack ||= []
    end
  end
end
