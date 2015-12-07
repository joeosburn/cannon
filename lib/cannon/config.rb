module Cannon
  class UnknownLogLevel < StandardError; end

  class Config
    attr_accessor :middleware, :public_path, :view_path, :reload_on_request, :benchmark_requests, :port, :ip_address
    attr_reader :logger, :log_level

    DEFAULT_MIDDLEWARE = %w{RequestLogger Files Cookies Router ContentType}

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
      self.middleware = DEFAULT_MIDDLEWARE
      self.public_path = 'public'
      self.view_path = 'views'
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
  end
end
