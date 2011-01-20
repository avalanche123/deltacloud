SERVER_DIR = File::expand_path(File::join(File::dirname(__FILE__), "../../../server"))
Dir.chdir(SERVER_DIR)

require 'rubygems'
require 'nokogiri'
require '../server/server'
require 'rack/test'

Sinatra::Application.set :environment, :test
Sinatra::Application.set :root, SERVER_DIR

CONFIG = {
  :username => 'admin@rhevm.brq.redhat.com',
  :password => 'Redhat01'
}

ENV['RACK_ENV'] = 'test'


World do

  include Rack::Test::Methods

  module Rack
    module Test
      class Session
        def headers
          @headers
        end
      end
    end
    class MockSession
      def set_last_response(response)
        @last_response = response
      end
    end
  end

  def app
    @app = Rack::Builder.new do
      set :environment => :development
      set :loggining => true
      set :raise_errors => true
      set :show_exceptions => true
      run Sinatra::Application
    end
  end

  def xml
    Nokogiri::XML(last_response.body)
  end



  Before do
    unless @no_header
      header 'Accept', 'application/xml;q=9'
    end
  end

end

