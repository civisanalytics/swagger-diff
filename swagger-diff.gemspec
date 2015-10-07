# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'swagger/diff/version'

Gem::Specification.new do |spec|
  spec.name          = 'swagger-diff'
  spec.version       = Swagger::Diff::VERSION
  spec.authors       = ['Jeff Cousens']
  spec.email         = ['opensource@civisanalytics.com']

  spec.summary       = 'Utility for comparing two Swagger specifications.'
  spec.description   = 'Swagger::Diff is a utility for comparing two different Swagger specifications.
It is intended to determine whether a newer API specification is backwards-
compatible with an older API specification. It provides both an RSpec matcher
and helper functions that can be used directly.'
  spec.homepage      = 'https://github.com/civisanalytics/swagger-diff'
  spec.license       = 'BSD 3-Clause'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'swagger-core', '~> 0.2.3'
  spec.add_dependency 'rspec-expectations', '~> 3.3'
  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.4'
  spec.add_development_dependency 'rspec', '~> 3.3'
  spec.add_development_dependency 'pry', '~> 0.10.1'
  spec.add_development_dependency 'rubocop', '~> 0.34.0'
  spec.add_development_dependency 'vcr', '~> 2.9'
  spec.add_development_dependency 'webmock', '~> 1.21'
end
