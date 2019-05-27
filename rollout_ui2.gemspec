# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rollout_ui2/version'

Gem::Specification.new do |spec|
  spec.name          = "rollout_ui2"
  spec.version       = RolloutUi2::VERSION
  spec.authors       = ["Manuel"]
  spec.email         = ["weap88@gmail.com"]

  spec.summary       = %q{WebUI for rollout 2}
  spec.description   = %q{Sinatra WebUI for rollout 2 }
  spec.homepage      = "https://github.com/weapp/rollout_ui2"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rack-test"

  spec.add_runtime_dependency 'sinatra', "~> 2.0.1", '>= 2.0.1'
end
