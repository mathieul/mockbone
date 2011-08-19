require 'sinatra'
require 'haml'
require 'sass'

set :public, File.expand_path('../public', __FILE__)
set :haml, :format => :html5

get '/stylesheets/application.css' do
  sass :application
end

get '/' do
  haml :application
end
