# README #

## Run ##

    $ rackup config.ru -s thin -E production

## Faye ##

In the browser, subscribe with:

    var client = new Faye.Client('/faye');
    var subscription = client.subscribe('/the-channel', function (msg) { console.log(msg); })

Send a message with:

    client.publish('/the-channel', {msg: 'something for everybody'});

Unsubscribe with:

    subscription.cancel();
