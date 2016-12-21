module Cannon
  # Base functionality for managing Cannon environment
  module Base
    FUNCTIONS = %w{env environment }

    def self.included(base)
      FUNCTIONS.each { |function| base.send(:module_function, function) }
    end

    def env
      @env ||= Environment.new((ENV['CANNON_ENV'] ||= 'development'))
    end

    def environment(*environments)
      environments.each do |environment|
        env.inform(environment)
        yield if block_given? && env == environment.to_s
      end
    end
  end

  # Holds a Cannon environment and responds to queries on which type of environment it is
  class Environment
    def initialize(environment)
      @environments = [environment]
    end

    def inform(environment)
      @environments << environment
      @environments.compact!
      @environment_methods = nil
    end

    def method_missing(meth, *arguments, &block)
      if env = environment(meth)
        @environments[0] == env
      else
        super
      end
    end

    def respond_to?(meth)
      return true if environment(meth)
      super
    end

    def to_s
      @environments[0]
    end

    def ==(value)
      @environments[0] == value
    end

  private

  def environment_methods
    @environment_methods ||= @environments.map { |env| "#{env}?".to_sym }
  end

    def environment(meth)
      environment_methods.include?(meth) ? meth[0..-2] : nil
    end
  end
end
