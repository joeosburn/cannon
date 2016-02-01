require 'openssl'

module Signature
  class CookieSecretNotSet < StandardError; end

  def signature(value)
    raise CookieSecretNotSet, 'Set config.cookies.secret to use signed cookies' if @app.runtime.config.cookies.secret.nil?
    OpenSSL::HMAC.hexdigest(digest, @app.runtime.config.cookies.secret, value)
  end

  def digest
    @digest ||= OpenSSL::Digest.new('sha1')
  end
end
