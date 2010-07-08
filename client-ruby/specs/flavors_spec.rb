
require 'specs/spec_helper'

describe "flavors" do

  it_should_behave_like "all resources"

  it "should allow retrieval of all flavors" do
    DeltaCloud.new( "name", "password", API_URL ) do |client|
      flavors = client.flavors
      flavors.should_not be_empty
      flavors.each do |flavor|
        flavor.uri.should_not be_nil
        flavor.uri.should be_a(String)
        flavor.architecture.should_not be_nil
        flavor.architecture.should be_a(String)
        flavor.storage.should_not be_nil
        flavor.storage.should be_a(Float)
        flavor.memory.should_not be_nil
        flavor.memory.should be_a(Float)
      end
    end
  end 
end