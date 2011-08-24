# README #

Mockbone is a basic test application intended to test Backbone model,
collection and view classes.

It allows to sign in to a global broadcast channel and send and receive
text messages.

## Dependencies ##

You need Redis for this application. It is used by the Faye redis engine
to store client state (allow more than one web server). It is also used
to save the username for each client.

Redis configuration can be changed in config.ru (REDIS\_CONFIG) .

## Installation ##

Assuming you use RVM and homebrew (on MacOSX):

    $ rvm use 1.9.2-p290@mockbone --create   # not necessary if no RVM or RVM is configured to use .rvmrc
    $ gem install bundler
    $ bundle
    $ brew install redis                     # if redis is not installed already

## Running the Application ##

Run the application in development or production mode, and open browser
windows at URL: *http://localhost:9292*.

### Development Mode ###

To run the application in development mode (it is reloaded when changes
are made and coffeescript file(s) are compiled when changed:

    $ guard

**Note**: thin must run in production mode as its development mode is not
compatible with websockets.

To stop it just press Ctrl-C.

### Production Mode ###

Or to run the application in production mode:

    $ thin -e production -R ./config.ru -p 9292 -d start

and stop it with:

    $ thin stop
