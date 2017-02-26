module Cannon
  # Configuration per app
  class Config
    include ElementalReference

    DEFAULT_MIDDLEWARE = %w(Benchmark RequestLogger Files Cookies Session Flash Router).freeze

    def initialize
      self.middleware = DEFAULT_MIDDLEWARE
      self.public_path = 'public'
      self.view_path = 'views'
    end

    protected

    attr_accessor :middleware, :public_path, :view_path
  end
end
