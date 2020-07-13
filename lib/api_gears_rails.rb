require "rails"
require "active_record"
require "byebug"
require "api_gears_rails/railtie"
# require "api_gears_rails/core_ext"
# require "api_gears_rails/api_connection.rb"
module ApiGearsRails
  require_dependency "api_gears_rails/api_connection"
  require_relative "generators/generator_helpers"
  require_relative "generators/api/api_generator"
end
