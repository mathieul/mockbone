# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'coffeescript', :input => 'app', :output => 'public/javascripts'

module Server
  extend self

  def start
    %x(thin -e production -R ./config.ru -p 9292 -d start)
    puts 'Thin server started'
  end

  def stop
    pid_file = File.expand_path('../tmp/pids/thin.pid', __FILE__)
    started = File.file?(pid_file)
    if started
      %x(thin -f stop)
      puts 'Thin server stopped'
    end
  end
end

guard 'shell' do
  watch /^app\/.*/ do
    Server.stop
    Server.start
    puts "READY."
  end
end

Server.stop
Server.start
