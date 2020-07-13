require 'rails_helper'
RSpec.describe ApiGearsRails do
  it "has a version number" do
    expect(ApiGearsRails::VERSION).not_to be nil
  end

  it "does something useful" do
    expect(false).to eq(!true)
  end
end
