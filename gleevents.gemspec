$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "gleevents/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "gleevents"
  s.version     = Gleevents::VERSION
  s.authors     = ["Jonathan Geggatt"]
  s.email       = ["jgeggatt@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Gleevents."
  s.description = "TODO: Description of Gleevents."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.1.0.rc2"

  s.add_dependency "mongoid"
  s.add_dependency "analytics-ruby"
end
