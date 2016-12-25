# Contains logic for retrieve or generating a request id
module RequestId
  def request_id
    @request_id ||= retrieve_request_id
  end

private

  def retrieve_request_id
    limited_header_request_id || generate_request_id
  end

  def limited_header_request_id
    header_request_id[0..254] unless header_request_id.empty?
  end

  def header_request_id
    headers['X-Request-Id'] || ''
  end

  def generate_request_id
    return nil unless app.runtime.config[:generate_request_ids]

    id = SecureRandom.hex(18)
    [8, 13, 18, 23].each { |pos| id[pos] = '-' }
    id
  end
end
