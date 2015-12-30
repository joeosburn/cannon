RSpec::Matchers.define(:redirect_to) do |expected|
  match do |actual|
    actual['location'] == expected
  end

  failure_message do |actual|
    "expected that headers #{actual} would include Location: header for #{expected}"
  end

  failure_message_when_negated do |actual|
    "expected that headers #{actual} would not include Location: header for #{expected}"
  end

  description do
    "include a Location: header for #{expected}"
  end
end
