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
      define_method(attr) { http_server.send(server_attr) || '' }
    end

    def initialize(http_server, app)
      @app = app
      @http_server = http_server
      start_benchmarking if app.runtime.config[:benchmark_requests]
    end

    def path
      mount_point_paths.last || full_path
    end

    def full_path
      http_server.http_path_info
    end

    def finish
      return unless @app.runtime.config[:benchmark_requests]
      stop_benchmarking
      benchmark_request(logger: @app.logger)
    end

    def params
      @params ||= map_params
    end

    def headers
      @headers ||= map_headers(http_server.http_headers)
    end

    def handled?
      @handled || false
    end

    def handle
      @handled = true
    end

    def to_s
      "#{method} #{path}"
    end

    def at_mount_point(mount_point)
      mount_point_paths << path.gsub(/^#{mount_point}/, '')
      yield if mount_point_paths.last != full_path
      mount_point_paths.pop
    end

    private

    def mount_point_paths
      @mount_point_paths ||= []
    end

    attr_reader :http_server

    def map_headers(http_headers)
      Hash[http_headers.split("\x00").map { |header| header.split(': ', 2) }]
    end

    def map_params
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
