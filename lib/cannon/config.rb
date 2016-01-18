module Cannon
  class UnknownLogLevel < StandardError; end

  class Config
    attr_accessor :reload_on_request, :benchmark_requests, :port, :ip_address
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
      self.reload_on_request = false
      self.benchmark_requests = true
      @log_level = :info
      self.logger = Logger.new(STDOUT)
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
