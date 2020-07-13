class ApplicationRecord < ActiveRecord::Base
  include ApiGearsRails::ApiConnection
  self.abstract_class = true
end
