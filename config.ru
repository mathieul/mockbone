require 'faye'
require File.expand_path('../app/server.rb', __FILE__)

use Faye::RackAdapter, :mount   => '/faye',
                       :timeout => 25

run Sinatra::Application
