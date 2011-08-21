require 'faye'
require File.expand_path('../app/server.rb', __FILE__)
require File.expand_path('../app/authentication_extension.rb', __FILE__)


REDIS_CONFIG = {
  :type       => 'redis',
  :host       => 'localhost',
  :port       => '6379',
  #:password   => 'REDIS_AUTH',
  :database   => 1
}

use Faye::RackAdapter,
  :mount   => '/faye',
  :timeout => 25,
  :engine  => REDIS_CONFIG,
  :extensions => AuthenticationExtension.new(REDIS_CONFIG)

run Sinatra::Application
