# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'coffeescript', :input => 'app', :output => 'public/javascripts'

module Server
  extend self

  def start
    puts 'Starting... '
    %x(thin -e production -R ./config.ru -p 9292 -d start)
    puts 'Thin server started'
  end

  def stop
    puts 'Stopping... '
    pid_file = File.expand_path('../tmp/pids/thin.pid', __FILE__)
    started = File.file?(pid_file)
    if started
      %x(thin -f stop)
      puts 'Thin server stopped'
    end
  end
end

guard 'shell' do
  watch(/^app\/.*/) { Server.stop; Server.start }
end

Server.stop
Server.start
