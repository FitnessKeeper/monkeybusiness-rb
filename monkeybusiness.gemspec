# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'monkeybusiness/version'

Gem::Specification.new do |spec|
  spec.name          = "monkeybusiness"
  spec.version       = Monkeybusiness::VERSION
  spec.authors       = ["Steve Huff"]
  spec.email         = ["steve.huff@runkeeper.com"]

  spec.summary       = %q{SurveyMonkey ETL worker}
  spec.description   = %q{Ruby component of SurveyMonkey ETL worker.}

  # This gem is not for public consumption
  spec.metadata      = { 'allowed_push_host' => 'localhost' }

  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
  # delete this section to allow pushing this gem to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "aws-sdk", "~> 2"
  spec.add_runtime_dependency "hashie", "~> 3.4"
  spec.add_runtime_dependency "jdbc-postgres", "~> 9.4"
  spec.add_runtime_dependency "logging", "~> 2"
  spec.add_runtime_dependency "sequel", "~> 4"
  spec.add_runtime_dependency "surveymonkey", "~> 0.4"
  spec.add_runtime_dependency "timeliness", "~> 0.3"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "dotenv", "~> 2"
  spec.add_development_dependency "pry", "~> 0.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
