# Use APP as the application namespace if you need to export
# variables below so they can be accessed from another file:
# root = global? or window
# root.APP = {}

class BaseView extends Backbone.View
  constructor: (options) ->
    super options
    _.bindAll @, 'render'

  render: ->
    $(@el)
      .empty()
      .html(@template(@model.toJSON()))
    @

class Message extends Backbone.Model

class MessageView extends BaseView
  template: Handlebars.compile $('#template-message').html()

class Messages extends Backbone.Collection
  model: Message

class MessagesView extends Backbone.View
  events:
    'click #send':        'sendMessage'
    'keypress #message':  'enterMessage'
    'click .sign-out':    'signOut'
  template: Handlebars.compile $('#template-messages').html()

  constructor: (options) ->
    super options
    _.bindAll @, 'render', 'renderMessage'
    if @collection?
      @collection.bind 'reset', @render, @
      @collection.bind 'add', @render, @

  render: ->
    $(@el).empty().html @template()
    @list = @$ 'ul.list'
    @collection.each(@renderMessage)
    @list[0].scrollTop = @list[0].scrollHeight
    $('#message').focus()
    @

  renderMessage: (message) ->
    view = new MessageView
      model: message
    @list.append view.render().el

  enterMessage: (ev) -> @sendMessage ev if ev.keyCode is 13

  sendMessage: (ev) ->
    message = $ '#message'
    who = @options.session.get 'username'
    @options.messenger.sendMessage who, message.val()
    message.val ''

  signOut: (ev) -> @options.session.unset 'username'

class Messenger
  _client       = null
  _subscription = null
  _username     = null

  constructor: (@options = {mount: '/faye', broadcast: '/rooms/broadcast'}) ->
    _client = new Faye.Client @options.mount
    # _client.addExtension
    #   outgoing: (message, callback) ->
    #     return callback message unless message.channel is '/meta/subscribe'
    #     message.ext ?= {}
    #     message.ext.username = _username
    #     callback message

  startListening: (username, cb) ->
    _username = username
    _subscription = _client.subscribe @options.broadcast, cb

  stopListening: ->
    _client.unsubscribe @options.broadcast
    _client.disconnect()

  sendMessage: (from, content) =>
    data = {from, content}
    console.log 'sending: ', data
    _client.publish @options.broadcast, data

class Session extends Backbone.Model

class SessionView extends BaseView
  events:
    'keypress .username': 'enterUsername'
    'click    .sign-in':  'signIn'

  template: Handlebars.compile $('#template-session').html()

  constructor: (options) ->
    super options
    @messenger = new Messenger
    @model.bind 'change:username', (model, username) =>
      if username?
        @render()
        @renderMessages()
        @messenger.startListening {username: username}, (data) =>
          me = @model.get 'username'
          data.type = if data.from is me then 'error' else 'notice'
          @messages.add data
      else
        @signOut()

  enterUsername: (ev) -> @signIn ev if ev.keyCode is 13

  signIn: (ev) ->
    username = @$('.username').val().trim()
    @model.set(username: username) unless username is ''

  signOut: ->
    @messenger.stopListening()
    @messagesView.remove()
    [@messages, @messagesView ] = [null, null]
    @render()

  render: ->
    super()
    @$('.username').focus()

  renderMessages: ->
    @messages = new Messages
    @messagesView = new MessagesView
      collection: @messages
      messenger:  @messenger
      session:    @model
    $('#messages').empty().append @messagesView.el
    @messagesView.render()

jQuery ->
  session = new Session
    username: null
  sessionView = new SessionView
    el: '#session'
    model: session
  sessionView.render()
