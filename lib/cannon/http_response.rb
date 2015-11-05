module Cannon
  class HttpResponse
    attr_accessor :delegated_response
    attr_accessor :content
    attr_accessor :status

    def initialize(http_server)
      self.delegated_response = EventMachine::DelegatedHttpResponse.new(http_server)
      self.content = ''
      self.status = 200
      @sent = false
    end

    def sent?
      @sent
    end

    def send(content = self.content, status: self.status)
      unless @sent
        delegated_response.status = status
        delegated_response.content = content
        delegated_response.send_response
        @sent = true
      end
    end

    def not_found
      send('Not Found', status: 404)
    end
  end
end
