require 'sinatra'
require 'haml'
require 'sass'

set :public, File.expand_path('../public', __FILE__)
set :haml, :format => :html5
