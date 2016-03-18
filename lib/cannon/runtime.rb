require 'yaml'

module Cannon
  class Runtime
    def initialize(app_binding)
      @app_binding = app_binding
      @cache = {}
    end

    def config
      @config ||= Config.new
    end

    def cache
      @cache
    end

    def action_cache
      @action_cache ||= ActionCache.new(cache: cache)
    end

    def logger
      config.logger
    end

    def root
      @root ||= Pathname.new(@app_binding.eval('File.expand_path(File.dirname(__FILE__))'))
    end

    def load_env(filename:)
      values = YAML.load_file(root.join(filename).to_s)
      values.each { |k, v| ENV[k.to_s] = v }
    end

    class UnknownLogLevel < StandardError; end

    class Config
      attr_accessor :cache_app, :benchmark_requests, :port, :ip_address
      attr_reader :logger, :log_level

      LOG_LEVELS = {
        unknown: Logger::UNKNOWN,
        fatal: Logger::FATAL,
        error: Logger::ERROR,
        warn: Logger::WARN,
        info: Logger::INFO,
        debug: Logger::DEBUG,
      }

      def initialize
        self.ip_address = '127.0.0.1'
        self.port = 5030
        self.cache_app = true
        self.benchmark_requests = true
        @log_level = :info
        $stdout.sync = true
        self.logger = Logger.new($stdout)
      end

      def logger=(value)
        @logger = value
        logger.datetime_format = '%Y-%m-%d %H:%M:%S'
        logger.formatter = proc do |severity, datetime, progname, msg|
          "#{msg}\n"
        end
        self.log_level = log_level
      end

      def log_level=(value)
        raise UnknownLogLevel unless LOG_LEVELS.keys.include? value.to_sym
        @log_level = value
        logger.level = LOG_LEVELS[value.to_sym]
      end

      def cookies
        @cookies ||= Cookies.new
      end

      def session
        @session ||= Session.new
      end

      class Cookies
        attr_accessor :secret

        def initialize
          self.secret = nil
        end
      end

      class Session
        attr_accessor :cookie_name

        def initialize
          self.cookie_name = '__session'
        end
      end
    end
  end
end
