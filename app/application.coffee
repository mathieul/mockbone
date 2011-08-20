root = global? or window
root.APP = {}

class APP.Message extends Backbone.Model

class APP.MessageView extends Backbone.View
  template: Handlebars.compile $('#template-message').html()

  constructor: (options) ->
    super options
    _.bindAll @, 'render'

  render: ->
    $(@el)
      .empty()
      .html(@template(@model.toJSON()))
    @

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

  enterMessage: (ev) ->
    @sendMessage ev if ev.keyCode is 13

  sendMessage: (ev) ->
    message = $ '#message'
    @options.messenger.sendMessage 'static', message.val()
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

jQuery ->
  messenger = new APP.Messenger
    mount:      '/faye'
    broadcast:  '/rooms/broadcast'

  messages = new APP.Messages
  messagesView = new APP.MessagesView
    el:         '#messages'
    collection: messages
    messenger:  messenger
  messagesView.render()
  messenger.startListening (attributes) ->
    messages.add(attributes)
