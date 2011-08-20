require 'faye'
require File.expand_path('../app/server.rb', __FILE__)

use Faye::RackAdapter,
  :mount   => '/faye',
  :timeout => 25,
  :engine  => {
    :type       => 'redis',
    :host       => 'localhost',
    :port       => '6379',
    #:password   => 'REDIS_AUTH',  # if your server requires it
    :database   => 1              # optional, selects database
  }

run Sinatra::Application
