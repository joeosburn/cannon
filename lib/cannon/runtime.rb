require 'yaml'

module Cannon
  # Runtime for Cannon. Holds config and other objects which are used for the runtime of Cannon.
  # There will only be one runtime instance per running app of cannon, while there may be several Cannon
  # apps in a single running Cannon instance, each with their own config.
  class Runtime
    attr_reader :cache

    def initialize(app_binding)
      @app_binding = app_binding
      @cache = {}
    end

    def config
      @config ||= Config.new
    end

    def logger
      config[:logger]
    end

    def root
      @root ||= Pathname.new(@app_binding.eval('File.expand_path(File.dirname(__FILE__))'))
    end

    def load_env(yaml_filename:)
      values = YAML.load_file(root.join(yaml_filename).to_s)
      values.each { |key, value| ENV[key.to_s] = value }
    end
  end
end
