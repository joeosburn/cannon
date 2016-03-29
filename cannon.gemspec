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
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = ['cannon', 'cannon-dev']
  spec.require_paths = ['lib']
  spec.test_files = Dir['spec/**/*']

  spec.add_dependency 'eventmachine', '~> 1.0.8'
  spec.add_dependency 'eventmachine_httpserver'
  spec.add_dependency 'mime-types', '~> 2.6.2'
  spec.add_dependency 'mustache', '~> 1.0.2'
  spec.add_dependency 'pry', '~> 0.10.3'
  spec.add_dependency 'msgpack', '~> 0.7.1'
  spec.add_dependency 'lspace', '~> 0.13'
  spec.add_dependency 'listen', '~> 3.0.6'

  spec.add_development_dependency 'rspec', '~> 3.3.0'
  spec.add_development_dependency 'http-cookie', '~> 1.0.2'
end
