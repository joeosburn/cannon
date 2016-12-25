require 'cgi'

module Cannon
  # Holds every incoming http request
  class Request
    include RequestId
    include Benchmarkable

    attr_reader :app, :path

    {
      protocol: 'http_protocol',
      method: 'http_request_method',
      http_cookie: 'http_cookie',
      content_type: 'http_content_type',
      uri: 'http_request_uri',
      query_string: 'http_query_string',
      post_content: 'http_post_content',
      http_headers: 'http_headers'
    }.each do |attr, server_attr|
      define_method(attr) do
        @http_server.instance_variable_get("@#{server_attr}") || ''
      end
    end

    def initialize(http_server, app)
      @path = http_server.instance_variable_get('@http_path_info')
      @http_server = http_server
      @app = app
      @handled = false
      start_benchmarking if @app.runtime.config[:benchmark_requests]
    end

    def finish
      return unless @app.runtime.config[:benchmark_requests]
      stop_benchmarking
      benchmark_request(logger: @app.logger)
    end

    def params
      @params ||= parse_params
    end

    def handled?
      @handled
    end

    def handle
      @handled = true
    end

    def headers
      @headers ||= parse_headers
    end

    def to_s
      "#{method} #{path}"
    end

    def attempt_mount(mount_point)
      matcher = /^#{mount_point}/
      return unless @path =~ matcher

      mount(matcher)
      yield
      unmount
    end

    def mount(matcher)
      mount_paths << @path
      @path = @path.gsub(matcher, '')
    end

    def unmount
      @path = mount_paths.pop
    end

  private

    def mount_paths
      @mount_paths ||= []
    end

    def parse_headers
      Hash[http_headers.split("\x00").map { |header| header.split(': ', 2) }]
    end

    def parse_params
      case method.downcase
      when 'get'
        Hash[mapped_query_params]
      else
        Hash[mapped_post_params]
      end
    end

    def mapped_query_params
      CGI.parse(query_string).map { |(key, value)| [key.to_sym, value.last] }
    end

    def mapped_post_params
      CGI.parse(post_content).map { |(key, value)| [key.to_sym, value.first] }
    end
  end
end
