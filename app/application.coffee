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
    @collection.each @renderMessage
    @

  renderMessage: (message) ->
    view = new APP.MessageView
      model: message
    @list.append view.render().el

class APP.Controller
  _client       = null
  _subscription = null
  _messages     = null
  _messagesView = null

  constructor: (@options = {}) ->
    _client = new Faye.Client @options.mount
    _messages = new APP.Messages
    _messagesView = new APP.MessagesView
      el:         '#messages'
      collection: _messages
    _messagesView.render()

  startListening: ->
    _subscription = _client.subscribe @options.broadcast, (attributes) ->
      _messages.add(attributes)

  stopListening: ->
    _subscription?.cancel()

  sendMessage: (from, content) =>
    data = {from, content}
    console.log 'sending: ', data
    _client.publish @options.broadcast, data

jQuery ->
  controller = new APP.Controller
    mount:      '/faye'
    broadcast:  '/rooms/broadcast'
  controller.startListening()

  window.zlaj = controller
