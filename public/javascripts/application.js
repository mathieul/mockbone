(function() {
  var root;
  var __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  }, __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  root = (typeof global !== "undefined" && global !== null) || window;
  root.APP = {};
  APP.Message = (function() {
    __extends(Message, Backbone.Model);
    function Message() {
      Message.__super__.constructor.apply(this, arguments);
    }
    return Message;
  })();
  APP.MessageView = (function() {
    __extends(MessageView, Backbone.View);
    MessageView.prototype.template = Handlebars.compile($('#template-message').html());
    function MessageView(options) {
      MessageView.__super__.constructor.call(this, options);
      _.bindAll(this, 'render');
    }
    MessageView.prototype.render = function() {
      $(this.el).empty().html(this.template(this.model.toJSON()));
      return this;
    };
    return MessageView;
  })();
  APP.Messages = (function() {
    __extends(Messages, Backbone.Collection);
    function Messages() {
      Messages.__super__.constructor.apply(this, arguments);
    }
    Messages.prototype.model = APP.Message;
    return Messages;
  })();
  APP.MessagesView = (function() {
    __extends(MessagesView, Backbone.View);
    MessagesView.prototype.template = Handlebars.compile($('#template-messages').html());
    function MessagesView(options) {
      MessagesView.__super__.constructor.call(this, options);
      _.bindAll(this, 'render', 'renderMessage');
      if (this.collection != null) {
        this.collection.bind('reset', this.render, this);
        this.collection.bind('add', this.render, this);
      }
    }
    MessagesView.prototype.render = function() {
      $(this.el).empty().html(this.template());
      this.list = this.$('ul.list');
      this.collection.each(this.renderMessage);
      return this;
    };
    MessagesView.prototype.renderMessage = function(message) {
      var view;
      view = new APP.MessageView({
        model: message
      });
      return this.list.append(view.render().el);
    };
    return MessagesView;
  })();
  APP.Controller = (function() {
    var _client, _messages, _messagesView, _subscription;
    _client = null;
    _subscription = null;
    _messages = null;
    _messagesView = null;
    function Controller(options) {
      this.options = options != null ? options : {};
      this.sendMessage = __bind(this.sendMessage, this);
      _client = new Faye.Client(this.options.mount);
      _messages = new APP.Messages;
      _messagesView = new APP.MessagesView({
        el: '#messages',
        collection: _messages
      });
      _messagesView.render();
    }
    Controller.prototype.startListening = function() {
      return _subscription = _client.subscribe(this.options.broadcast, function(attributes) {
        return _messages.add(attributes);
      });
    };
    Controller.prototype.stopListening = function() {
      return _subscription != null ? _subscription.cancel() : void 0;
    };
    Controller.prototype.sendMessage = function(from, content) {
      var data;
      data = {
        from: from,
        content: content
      };
      console.log('sending: ', data);
      return _client.publish(this.options.broadcast, data);
    };
    return Controller;
  })();
  jQuery(function() {
    var controller;
    controller = new APP.Controller({
      mount: '/faye',
      broadcast: '/rooms/broadcast'
    });
    controller.startListening();
    return window.zlaj = controller;
  });
}).call(this);
