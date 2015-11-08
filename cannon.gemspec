# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cannon/version'

Gem::Specification.new do |spec|
  spec.name          = 'cannon'
  spec.version       = Cannon::VERSION
  spec.authors       = ['Joe Osburn']
  spec.email         = ['joe@jnodev.com']

  spec.summary       = %q{Cannon is a fast web framework}
  spec.homepage      = 'https://github.com/joeosburn/cannon'

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']
  spec.test_files = Dir['spec/**/*']

  spec.add_dependency 'eventmachine', '~> 1.0.8'
  spec.add_dependency 'eventmachine_httpserver'
  spec.add_dependency 'mime-types', '~> 2.6.2'

  spec.add_development_dependency 'rspec', '~> 3.3.0'
end
