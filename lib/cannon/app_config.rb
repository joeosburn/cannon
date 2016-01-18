module Cannon
  class AppConfig
    attr_accessor :middleware, :public_path, :view_path

    DEFAULT_MIDDLEWARE = %w{RequestLogger Files Cookies Session Flash Router ContentType}

    def initialize
      self.middleware = DEFAULT_MIDDLEWARE
      self.public_path = 'public'
      self.view_path = 'views'
    end
  end
end
