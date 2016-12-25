# Maps getter/setter methods to element reference methods
module ElementalReference
  # Raised when trying to access an unknown key
  class UnknownKey < StandardError; end

  def [](key)
    send(key)
  rescue NoMethodError
    raise UnknownKey, "Unknown key #{key}"
  end

  def []=(key, value)
    send("#{key}=".to_sym, value)
  rescue NoMethodError
    raise UnknownKey, "Unknown key #{key}"
  end
end
