require 'cgi'

module Cannon
  # Extends Chase::Request
  module Request
    include RequestId

    def self.included(mod)
      mod.send(:attr_accessor, :app)
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

    def path
      mount_point_paths.last || full_path
    end

    def full_path
      env['PATH_INFO']
    end

    def protocol
      env['PROTOCOL']
    end

    def method
      env['REQUEST_METHOD']
    end

    def to_s
      "#{method} #{full_path}"
    end

    private

    def mount_point_paths
      @mount_point_paths ||= [full_path]
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
      CGI.parse(env['QUERY_STRING']).map { |(key, value)| [key.to_sym, value.last] }
    end

    def mapped_post_params
      CGI.parse(env['POST_CONTENT']).map { |(key, value)| [key.to_sym, value.first] }
    end
  end
end

Chase::Request.include Cannon::Request
