module Events
  def on(event, &block)
    __events[event] << block
  end

  def emit(event, *args)
    __events[event].each { |cb| cb.call(*args) }
  end

  private

  def __events
    @__events ||= Hash.new([])
  end
end

Object.include Events
