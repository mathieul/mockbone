require 'em-hiredis'

class AuthenticationExtension
  DEFAULT_HOST     = 'localhost'
  DEFAULT_PORT     = 6379
  DEFAULT_DATABASE = 0
  KEY_ID_TO_NAME   = 'id-to-name'

  def initialize(config)
    @host = config[:host]      || DEFAULT_HOST
    @port = config[:port]      || DEFAULT_PORT
    @db   = config[:database]  || DEFAULT_DATABASE
    @auth = config[:password]
  end

  def incoming(message, callback)
    if message['channel'] == '/meta/subscribe'
      # map message['clientId'] to message['ext']['username'] in REDIS
      client_id, username = [message['clientId'], message['ext']['username']]
      redis.hset(KEY_ID_TO_NAME, client_id, username) do |set|
        callback.call(message)
      end
    else
      callback.call(message)
    end
  end
  def outgoing(message, callback)
    if message['channel'] == '/rooms/broadcast' && !message['data'].nil?
      redis.hget(KEY_ID_TO_NAME, message['clientId']) do |username|
        message['data']['from'] = username || '???'
        callback.call(message)
      end
    else
      callback.call(message)
    end
  end

  private

  def redis
    return @redis unless @redis.nil?
    @redis = EventMachine::Hiredis::Client.connect(@host, @port).tap do |redis|
      redis.auth(@auth) unless @auth.nil?
      redis.select(@db)
    end
  end
end
