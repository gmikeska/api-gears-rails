$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "api_gears_rails/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "api_gears_rails"
  spec.version     = ApiGearsRails::VERSION
  spec.authors     = ["Greg Mikeska"]
  spec.email       = ["digitalintaglio@lavabit.com"]
  spec.homepage    = "https://github.com/gmikeska/api_gears_rails"
  spec.summary     = "A rails plugin for the api_gears gem"
  spec.description = "api_gears_rails allows installation of an API client into rails models, to keep data synchronized between a rails model and an API."
  spec.license     = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  spec.add_dependency "rails", "~> 6.0.3", ">= 6.0.3.2"
  spec.add_dependency "api_gears", "~> 1.0.5"

  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "byebug"
end
