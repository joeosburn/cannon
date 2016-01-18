module Cannon
  module Base
    FUNCTIONS = %w{env environment config logger}

    def self.included(base)
      FUNCTIONS.each { |function| base.send(:module_function, function) }
    end

    def env
      @env ||= begin
        env_string = ENV['CANNON_ENV'] ? ENV['CANNON_ENV'].dup : 'development'
        env_string.singleton_class.send(:define_method, "#{env_string}?") { true }
        env_string
      end
    end

    def config
      @config ||= Config.new
    end

    def logger
      config.logger
    end

    def environment(*environments)
      environments.each do |environment|
        meth = "#{environment}?"
        env.singleton_class.send(:define_method, meth) { false } unless env.respond_to?(meth)
        yield if block_given? && env == environment.to_s
      end
    end
  end
end
