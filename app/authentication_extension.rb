require 'em-hiredis'

class AuthenticationExtension
  DEFAULT_HOST     = 'localhost'
  DEFAULT_PORT     = 6379
  DEFAULT_DATABASE = 0

  def initialize(config)
    @host = config[:host]      || DEFAULT_HOST
    @port = config[:port]      || DEFAULT_PORT
    @db   = config[:database]  || DEFAULT_DATABASE
    @auth = config[:password]
  end

  def incoming(message, callback)
    # puts "incoming(#{message.inspect}, callback)"
    return callback.call(message) unless message['channel'] == '/meta/subscribe'
    # TODO: use message['ext']['username']
    callback.call(message)
  end

  # def outgoing(message, callback)
  #   puts "outgoing(#{message.inspect}, callback)"
  #   callback.call(message)
  # end

  private

  def redis
    return @redis unless @redis.nil?
    @redis = EventMachine::Hiredis::Client.connect(host, port).tap do |redis|
      redis.auth(@auth) unless @auth.nil?
      redis.select(@db)
    end
  end
end
