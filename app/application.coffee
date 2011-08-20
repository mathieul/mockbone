root = global? or window
root.APP = {}

class BaseView extends Backbone.View
  constructor: (options) ->
    super options
    _.bindAll @, 'render'

  render: ->
    $(@el)
      .empty()
      .html(@template(@model.toJSON()))
    @

class APP.Message extends Backbone.Model

class APP.MessageView extends BaseView
  template: Handlebars.compile $('#template-message').html()

class APP.Messages extends Backbone.Collection
  model: APP.Message

class APP.MessagesView extends Backbone.View
  events:
    'click #send':        'sendMessage'
    'keypress #message':  'enterMessage'
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
    @collection.chain()
      .reverse()
      .each(@renderMessage)
      .value()
    $('#message').focus()
    @

  renderMessage: (message) ->
    view = new APP.MessageView
      model: message
    @list.append view.render().el

  enterMessage: (ev) -> @sendMessage ev if ev.keyCode is 13

  sendMessage: (ev) ->
    message = $ '#message'
    who = APP.session.get 'username'
    APP.messenger.sendMessage who, message.val()
    message.val ''

class APP.Messenger
  _client       = null
  _subscription = null

  constructor: (@options = {}) ->
    _client = new Faye.Client @options.mount

  startListening: (cb) ->
    _subscription = _client.subscribe @options.broadcast, cb

  stopListening: ->
    _subscription?.cancel()

  sendMessage: (from, content) =>
    data = {from, content}
    console.log 'sending: ', data
    _client.publish @options.broadcast, data

class APP.Session extends Backbone.Model

class APP.SessionView extends BaseView
  events:
    'keypress .username': 'enterUsername'
    'click    .sign-in':  'signIn'
    'click    .sign-out': 'signOut'
  template: Handlebars.compile $('#template-session').html()

  enterUsername: (ev) -> @signIn ev if ev.keyCode is 13

  signIn: (ev) ->
    username = @$('.username').val().trim()
    return if username is ''
    @model.set username: username
    @render()
    @renderMessages()
    APP.messenger = new APP.Messenger
      mount:      '/faye'
      broadcast:  '/rooms/broadcast'

    APP.messenger.startListening (data) =>
      me = APP.session.get 'username'
      data.type = if data.from is me then 'error' else 'notice'
      @_messages.add data

  signOut: (ev) ->
    ev.preventDefault()
    @model.unset 'username'
    @_messages = null
    $(@_messagesView.el).empty()
    @_messagesView = null
    @render()

  render: ->
    super()
    @$('.username').focus()

  renderMessages: ->
    @_messages = new APP.Messages
    @_messagesView = new APP.MessagesView
      el:         '#messages'
      collection: @_messages
    @_messagesView.render()

jQuery ->
  APP.session = new APP.Session
    username: null
  sessionView = new APP.SessionView
    el: '#session'
    model: APP.session
  sessionView.render()
