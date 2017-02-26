require 'cgi'

module Cannon
  # Holds every incoming http request
  class Request
    include RequestId

    attr_reader :env
    attr_accessor :app

    def initialize(env)
      @env = env
      @env['start-time'] = Time.now
    end

    def handled?
      @handled || false
    end

    def handle
      @handled = true
    end

    def mount_at(mount_point)
      mount_point_paths << path.gsub(/^#{mount_point}/, '')
    end

    def unmount
      mount_point_paths.pop
    end

    def params
      @params ||= map_params
    end

    def headers
      @headers ||= map_headers
    end

    def path
      mount_point_paths.last || full_path
    end

    def full_path
      env['http_path_info']
    end

    def protocol
      env['http_protocol']
    end

    def method
      env['http_request_method']
    end

    def to_s
      "#{method} #{full_path}"
    end

    private

    def mount_point_paths
      @mount_point_paths ||= [full_path]
    end

    def map_headers
      Hash[env['http_headers'].split("\x00").map { |header| header.split(': ', 2) }]
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
      CGI.parse(env['http_query_string']).map { |(key, value)| [key.to_sym, value.last] }
    end

    def mapped_post_params
      CGI.parse(env['http_post_content']).map { |(key, value)| [key.to_sym, value.first] }
    end
  end
end
