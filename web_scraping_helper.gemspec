# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'web_scraping_helper/version'

Gem::Specification.new do |spec|
  spec.name          = "web_scraping_helper"
  spec.version       = WebScrapingHelper::VERSION
  spec.authors       = ["momo-lab"]
  spec.email         = ["momotaro.n@gmail.com"]

  spec.summary       = "WebScrapingHelper"
  spec.description   = "WebScrapingHelper"
  spec.homepage      = "https://github.com/momo-lab/web_scraping_helper"

#  # Prevent pushing this gem to RubyGems.org by setting 'allowed_push_host', or
#  # delete this section to allow pushing this gem to any host.
#  if spec.respond_to?(:metadata)
#    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
#  else
#    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
#  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rest-client"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "minitest-power_assert"
  spec.add_development_dependency "webmock", "~> 2.0"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-minitest"
end
