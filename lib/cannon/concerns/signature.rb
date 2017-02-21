require 'openssl'

# Concern for signed cookies
module Signature
  # Error raised if the cookies.secret config value is not set
  class CookieSecretNotSet < StandardError; end

  def signature(value, secret)
    raise CookieSecretNotSet, 'Set runtime.config[:cookies][:secret] to use signed cookies' unless secret
    OpenSSL::HMAC.hexdigest(digest, secret, value)
  end

  def digest
    @digest ||= OpenSSL::Digest.new('sha1')
  end
end
