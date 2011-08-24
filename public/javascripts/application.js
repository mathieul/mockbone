(function() {
  /*
   Messenger: class used to communicate with the server
  */
  var BaseView, Message, MessageView, Messages, MessagesView, Messenger, Session, SessionView;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; }, __hasProp = Object.prototype.hasOwnProperty, __extends = function(child, parent) {
    for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; }
    function ctor() { this.constructor = child; }
    ctor.prototype = parent.prototype;
    child.prototype = new ctor;
    child.__super__ = parent.prototype;
    return child;
  };
  Messenger = (function() {
    function Messenger(options) {
      this.options = options != null ? options : {
        mount: '/faye',
        broadcast: '/rooms/broadcast'
      };
      this.sendMessage = __bind(this.sendMessage, this);
      this._client = new Faye.Client(this.options.mount);
      this._client.addExtension({
        outgoing: __bind(function(message, callback) {
          var _ref;
          if (message.channel !== '/meta/subscribe') {
            return callback(message);
          }
          if ((_ref = message.ext) == null) {
            message.ext = {};
          }
          message.ext.username = this._username;
          return callback(message);
        }, this)
      });
    }
    Messenger.prototype.startListening = function(username, cb) {
      this._username = username;
      return this._client.subscribe(this.options.broadcast, cb);
    };
    Messenger.prototype.stopListening = function() {
      return this._client.unsubscribe(this.options.broadcast);
    };
    Messenger.prototype.sendMessage = function(content) {
      return this._client.publish(this.options.broadcast, {
        content: content
      });
    };
    return Messenger;
  })();
  /*
   Base view: base class to extend to inherit common view behaviors
  */
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
  /*
   Message model: data of one message
  */
  Message = (function() {
    __extends(Message, Backbone.Model);
    function Message() {
      Message.__super__.constructor.apply(this, arguments);
    }
    return Message;
  })();
  /*
   Message view: representation of one message in the DOM
  */
  MessageView = (function() {
    __extends(MessageView, BaseView);
    function MessageView() {
      MessageView.__super__.constructor.apply(this, arguments);
    }
    MessageView.prototype.template = Handlebars.compile($('#template-message').html());
    return MessageView;
  })();
  /*
   Message collection: list of message model instances
  */
  Messages = (function() {
    __extends(Messages, Backbone.Collection);
    function Messages() {
      Messages.__super__.constructor.apply(this, arguments);
    }
    Messages.prototype.model = Message;
    return Messages;
  })();
  /*
   Messages view: representation of the list of messages in the DOM
  */
  MessagesView = (function() {
    __extends(MessagesView, Backbone.View);
    MessagesView.prototype.events = {
      'click #send': 'sendMessage',
      'keypress #message': 'enterMessage',
      'click .sign-out': 'signOut'
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
      this.collection.each(this.renderMessage);
      this.list[0].scrollTop = this.list[0].scrollHeight;
      this.messageField = $('#message').focus();
      return this;
    };
    MessagesView.prototype.renderMessage = function(message) {
      var view;
      view = new MessageView({
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
      var message;
      ev.preventDefault();
      message = this.messageField.val().trim();
      if (message === '') {
        return;
      }
      this.options.messenger.sendMessage(message);
      return this.messageField.val('');
    };
    MessagesView.prototype.signOut = function(ev) {
      return this.options.session.unset('username');
    };
    return MessagesView;
  })();
  /*
   Session model: user session attributes
  */
  Session = (function() {
    __extends(Session, Backbone.Model);
    function Session() {
      Session.__super__.constructor.apply(this, arguments);
    }
    return Session;
  })();
  /*
   Session view: user session information in the DOM
  */
  SessionView = (function() {
    __extends(SessionView, BaseView);
    SessionView.prototype.events = {
      'keypress .username': 'enterUsername',
      'click    .sign-in': 'signIn'
    };
    SessionView.prototype.template = Handlebars.compile($('#template-session').html());
    function SessionView(options) {
      SessionView.__super__.constructor.call(this, options);
      this.model.bind('change:username', __bind(function(model, username) {
        if (username != null) {
          this.render();
          this.renderMessages();
          return this.options.messenger.startListening(username, __bind(function(data) {
            var me;
            me = this.model.get('username');
            data.type = data.from === me ? 'error' : 'notice';
            return this.messages.add(data);
          }, this));
        } else {
          return this.signOut();
        }
      }, this));
    }
    SessionView.prototype.enterUsername = function(ev) {
      if (ev.keyCode === 13) {
        return this.signIn(ev);
      }
    };
    SessionView.prototype.signIn = function(ev) {
      var username;
      username = this.$('.username').val().trim();
      if (username !== '') {
        return this.model.set({
          username: username
        });
      }
    };
    SessionView.prototype.signOut = function() {
      var _ref;
      this.options.messenger.stopListening();
      this.messagesView.remove();
      _ref = [null, null], this.messages = _ref[0], this.messagesView = _ref[1];
      return this.render();
    };
    SessionView.prototype.render = function() {
      SessionView.__super__.render.call(this);
      return this.$('.username').focus();
    };
    SessionView.prototype.renderMessages = function() {
      this.messages = new Messages;
      this.messagesView = new MessagesView({
        collection: this.messages,
        messenger: this.options.messenger,
        session: this.model
      });
      $('#messages').empty().append(this.messagesView.el);
      return this.messagesView.render();
    };
    return SessionView;
  })();
  /*
   Main: executed when the document is ready
  */
  jQuery(function() {
    var messenger, session, sessionView;
    session = new Session({
      username: null
    });
    messenger = new Messenger;
    sessionView = new SessionView({
      el: '#session',
      model: session,
      messenger: messenger
    });
    return sessionView.render();
  });
}).call(this);
