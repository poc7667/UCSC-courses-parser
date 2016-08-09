# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ucsc_ext_courses/version'

Gem::Specification.new do |spec|
  spec.name          = "ucsc_ext_courses"
  spec.version       = UcscExtCourses::VERSION
  spec.authors       = ["poc.hsu"]
  spec.email         = ["poc7667@gmail.com"]

  spec.summary       = %q{Fetch courses from UCSC Ext }
  spec.description   = %q{Fetch courses from UCSC Ext }
  spec.homepage      = "http://course-plan.ucsc-ext.edu"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "Fetch courses from UCSC Ext "
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "nokogiri", "1.6.7.2"
  spec.add_development_dependency "pry", "0.10.3"
  spec.add_development_dependency "rails", "4.2.6"
  spec.add_development_dependency "curb", "0.9.3"
end
