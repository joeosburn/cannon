module Cannon
  # Route which can be matched based on a path and method
  class Route
    attr_reader :params

    def initialize(path, method)
      @path = path
      @method = method.to_s.upcase
      @params = extract_params_from_path
    end

    def matchable_path
      @matcheable_path ||= prepare_matchable_path
    end

    def matches?(request)
      matched_method?(request.method) && matched_path?(request.path)
    end

    def to_s
      "Route: #{path}"
    end

    def path_matches(path)
      matchable_path.match(path)
    end

  private

    def matched_method?(request_method)
      @method == 'ALL' || request_method == @method
    end

    def matched_path?(path)
      path_matches(path) != nil
    end

    def prepare_matchable_path
      /^#{path_with_params.gsub('/', '\/')}$/
    end

    def path_with_params
      @params.reduce(@path) { |path, param| path.gsub(":#{param}", '([^\/]+)') }
    end

    def extract_params_from_path
      @path.scan(/:[a-zA-Z0-9_]+/).map { |param| param[1..-1] }
    end
  end
end
