module Cannon
  class Runtime
    # Config that is specific to the Cannon runtime
    class Config
      include ElementalReference

      # Error that is raised if the log level set is unknown
      class UnknownLogLevel < StandardError; end

      LOG_LEVELS = {
        unknown: Logger::UNKNOWN,
        fatal: Logger::FATAL,
        error: Logger::ERROR,
        warn: Logger::WARN,
        info: Logger::INFO,
        debug: Logger::DEBUG
      }.freeze

      def initialize
        self.ip_address = '127.0.0.1'
        self.port = 5030
        self.cache_app = true
        self.benchmark_requests = true
        @log_level = :info
        $stdout.sync = true
        self.logger = Logger.new($stdout)
        self.generate_request_ids = false
      end

      protected

      attr_accessor :cache_app, :benchmark_requests, :port, :ip_address, :generate_request_ids
      attr_reader :logger, :log_level

      def logger=(value)
        @logger = value
        logger.datetime_format = '%Y-%m-%d %H:%M:%S'
        logger.formatter = logger_formatter_proc
        self.log_level = log_level
      end

      def log_level=(value)
        logger_level = LOG_LEVELS[value.to_sym]
        raise UnknownLogLevel unless logger_level
        @log_level = value
        logger.level = logger_level
      end

      def cookies
        @cookies ||= Cookies.new
      end

      def session
        @session ||= Session.new
      end

      private

      def logger_formatter_proc
        proc do |_severity, _datetime, _progname, msg|
          if currrent_request_has_request_id?
            "request_id=#{current_request_id} #{msg}\n"
          else
            "#{msg}\n"
          end
        end
      end

      def current_request_has_request_id?
        current_request && current_request_id
      end

      def current_request_id
        current_request.request_id
      end

      def current_request
        LSpace[:request]
      end

      # Runtime config for cookies
      class Cookies
        include ElementalReference

        def initialize
          self.secret = nil
        end

        protected

        attr_accessor :secret
      end

      # Runtime config for sessions
      class Session
        include ElementalReference

        def initialize
          self.cookie_name = '__session'
        end

        protected

        attr_accessor :cookie_name
      end
    end
  end
end
