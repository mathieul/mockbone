# Use APP as the application namespace if you need to export
# variables below so they can be accessed from another file:
# root = global? or window
# root.APP = {}

###
 Messenger: class used to communicate with the server
###
class Messenger
  constructor: (@options = {mount: '/faye', broadcast: '/rooms/broadcast'}) ->
    @_client = new Faye.Client @options.mount
    @_client.addExtension
      outgoing: (message, callback) =>
        return callback message unless message.channel is '/meta/subscribe'
        message.ext ?= {}
        message.ext.username = @_username
        callback message

  startListening: (username, cb) ->
    @_username = username
    @_client.subscribe @options.broadcast, cb

  stopListening: ->
    @_client.unsubscribe @options.broadcast

  sendMessage: (content) =>
    @_client.publish @options.broadcast, {content}

###
 Base view: base class to extend to inherit common view behaviors
###
class BaseView extends Backbone.View
  constructor: (options) ->
    super options
    _.bindAll @, 'render'

  render: ->
    $(@el)
      .empty()
      .html(@template(@model.toJSON()))
    @

###
 Message model: data of one message
###
class Message extends Backbone.Model

###
 Message view: representation of one message in the DOM
###
class MessageView extends BaseView
  template: Handlebars.compile $('#template-message').html()

###
 Message collection: list of message model instances
###
class Messages extends Backbone.Collection
  model: Message

###
 Messages view: representation of the list of messages in the DOM
###
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
    @messageField = $('#message').focus()
    @

  renderMessage: (message) ->
    view = new MessageView {model: message}
    @list.append view.render().el

  enterMessage: (ev) -> @sendMessage ev if ev.keyCode is 13

  sendMessage: (ev) ->
    ev.preventDefault()
    message = @messageField.val().trim()
    return if message is ''
    @options.messenger.sendMessage message
    @messageField.val ''

  signOut: (ev) -> @options.session.unset 'username'

###
 Session model: user session attributes
###
class Session extends Backbone.Model

###
 Session view: user session information in the DOM
###
class SessionView extends BaseView
  events:
    'keypress .username': 'enterUsername'
    'click    .sign-in':  'signIn'

  template: Handlebars.compile $('#template-session').html()

  constructor: (options) ->
    super options
    @model.bind 'change:username', (model, username) =>
      if username?
        @render()
        @renderMessages()
        @options.messenger.startListening username, (data) =>
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
    @options.messenger.stopListening()
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
      messenger:  @options.messenger
      session:    @model
    $('#messages').empty().append @messagesView.el
    @messagesView.render()

###
 Main: executed when the document is ready
###
jQuery ->
  session     = new Session {username: null}
  messenger   = new Messenger
  sessionView = new SessionView
    el:        '#session'
    model:     session
    messenger: messenger

  sessionView.render()
