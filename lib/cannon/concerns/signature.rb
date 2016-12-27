require 'openssl'

# Concern for signed cookies
module Signature
  # Error raised if the cookies.secret config value is not set
  class CookieSecretNotSet < StandardError; end

  def signature(value, app)
    if secret = app.runtime.config[:cookies][:secret]
      OpenSSL::HMAC.hexdigest(digest, secret, value)
    else
      raise CookieSecretNotSet, 'Set runtime.config[:cookies][:secret] to use signed cookies'
    end
  end

  def digest
    @digest ||= OpenSSL::Digest.new('sha1')
  end
end
