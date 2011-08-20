(function() {
  var BaseView, root;
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
  BaseView = (function() {
    __extends(BaseView, Backbone.View);
    function BaseView(options) {
      BaseView.__super__.constructor.call(this, options);
      _.bindAll(this, 'render');
    }
    BaseView.prototype.render = function() {
      $(this.el).empty().html(this.template(this.model.toJSON()));
      return this;
    };
    return BaseView;
  })();
  APP.Message = (function() {
    __extends(Message, Backbone.Model);
    function Message() {
      Message.__super__.constructor.apply(this, arguments);
    }
    return Message;
  })();
  APP.MessageView = (function() {
    __extends(MessageView, BaseView);
    function MessageView() {
      MessageView.__super__.constructor.apply(this, arguments);
    }
    MessageView.prototype.template = Handlebars.compile($('#template-message').html());
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
    MessagesView.prototype.events = {
      'click #send': 'sendMessage',
      'keypress #message': 'enterMessage'
    };
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
      this.collection.chain().reverse().each(this.renderMessage).value();
      $('#message').focus();
      return this;
    };
    MessagesView.prototype.renderMessage = function(message) {
      var view;
      view = new APP.MessageView({
        model: message
      });
      return this.list.append(view.render().el);
    };
    MessagesView.prototype.enterMessage = function(ev) {
      if (ev.keyCode === 13) {
        return this.sendMessage(ev);
      }
    };
    MessagesView.prototype.sendMessage = function(ev) {
      var message, who;
      message = $('#message');
      who = APP.session.get('username');
      APP.messenger.sendMessage(who, message.val());
      return message.val('');
    };
    return MessagesView;
  })();
  APP.Messenger = (function() {
    var _client, _subscription;
    _client = null;
    _subscription = null;
    function Messenger(options) {
      this.options = options != null ? options : {};
      this.sendMessage = __bind(this.sendMessage, this);
      _client = new Faye.Client(this.options.mount);
    }
    Messenger.prototype.startListening = function(cb) {
      return _subscription = _client.subscribe(this.options.broadcast, cb);
    };
    Messenger.prototype.stopListening = function() {
      return _subscription != null ? _subscription.cancel() : void 0;
    };
    Messenger.prototype.sendMessage = function(from, content) {
      var data;
      data = {
        from: from,
        content: content
      };
      console.log('sending: ', data);
      return _client.publish(this.options.broadcast, data);
    };
    return Messenger;
  })();
  APP.Session = (function() {
    __extends(Session, Backbone.Model);
    function Session() {
      Session.__super__.constructor.apply(this, arguments);
    }
    return Session;
  })();
  APP.SessionView = (function() {
    __extends(SessionView, BaseView);
    function SessionView() {
      SessionView.__super__.constructor.apply(this, arguments);
    }
    SessionView.prototype.events = {
      'keypress .username': 'enterUsername',
      'click    .sign-in': 'signIn'
    };
    SessionView.prototype.template = Handlebars.compile($('#template-session').html());
    SessionView.prototype.enterUsername = function(ev) {
      if (ev.keyCode === 13) {
        return this.signIn(ev);
      }
    };
    SessionView.prototype.signIn = function(ev) {
      var username;
      username = this.$('.username').val().trim();
      if (username === '') {
        return;
      }
      this.model.set({
        username: username
      });
      this.render();
      this.renderMessages();
      APP.messenger = new APP.Messenger({
        mount: '/faye',
        broadcast: '/rooms/broadcast'
      });
      return APP.messenger.startListening(__bind(function(data) {
        var me;
        me = APP.session.get('username');
        data.type = data.from === me ? 'error' : 'notice';
        return this._messages.add(data);
      }, this));
    };
    SessionView.prototype.render = function() {
      SessionView.__super__.render.call(this);
      return this.$('.username').focus();
    };
    SessionView.prototype.renderMessages = function() {
      this._messages = new APP.Messages;
      this._messagesView = new APP.MessagesView({
        el: '#messages',
        collection: this._messages
      });
      return this._messagesView.render();
    };
    return SessionView;
  })();
  jQuery(function() {
    var sessionView;
    APP.session = new APP.Session({
      username: null
    });
    sessionView = new APP.SessionView({
      el: '#session',
      model: APP.session
    });
    return sessionView.render();
  });
}).call(this);
