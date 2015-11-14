module Cannon
  class Config
    attr_accessor :middleware, :public_path, :view_path, :reload_on_request, :benchmark_requests

    DEFAULT_MIDDLEWARE = %w{RequestLogger Files Router ContentType}

    def initialize
      self.middleware = DEFAULT_MIDDLEWARE
      self.public_path = 'public'
      self.view_path = 'views'
      self.reload_on_request = false
      self.benchmark_requests = true
    end

  end
end
