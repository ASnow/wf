# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wf/version'

Gem::Specification.new do |spec|
  spec.name          = 'wf'
  spec.version       = Wf::VERSION
  spec.authors       = ["Андрей Большов"]
  spec.email         = ['asnow.dev@gmail.ru']
  spec.summary       = 'WF'
  spec.description   = 'WF'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'thor'
  spec.add_dependency 'json'
  spec.add_dependency 'sshkit'
  spec.add_dependency 'github_api'
  spec.add_dependency 'cocaine', '~> 0.5.8'
  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'pry-stack_explorer'
end
