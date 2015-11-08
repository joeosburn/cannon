require 'filemagic'

module Cannon
  module Middleware
    class ContentType
      def initialize(app)
        @app = app
      end

      def run(request, response)
        return unless response.headers['Content-Type'] == nil

        content_type = FileMagic.new(FileMagic::MAGIC_MIME).buffer(response.content)
        response.headers['Content-Type'] = content_type
      end
    end
  end
end
