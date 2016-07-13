# Storyboard Listener API

For an example of a simple Storyboard listener (plugin), see the ConsoleListener. Listeners should follow the API described in this document.

## Listener methods

**constructor()** (optional)

* **config** *object*: user configuration options. Should typically be merged with some defaults and stored in the listener instance.
* **context** *object*:
    - **hub** *object*: the hub instance this listener is attached to. Refer to [Hub API for listeners](#hub-api-for-listeners) for guidance on how to use it.
    - **mainStory** *object*: Storyboard's main story, which can be used to generate logs the same way as a library user:

        ```js
        mainStory.info('myListener', 'Listener is up and running!');
        ```


**getConfig()** (mandatory)

* *No arguments*
* Returns *object*: current listener configuration.


**configure(config)** (optional)

* Merges the provided object with the current configuration.
* *No arguments*
* *No return value*


**init()** (optional)

* Executes initialization operations, e.g. connects to a database, opens a file, etc.
* *No arguments*
* *No return value*


**tearDown()** (optional)

* Executes tear-down operations, e.g. disconnects from a database, closes a file, etc.
* *No arguments*
* *No return value*


**process()** (mandatory)

* Processes a message from the hub, e.g. saves records to a database, writes them to a file, relay them to a browser extension, uploads them to a server, etc.
* **TBW**
* *No return value*


## Listener module

Wrap your listener in a module and export a creator function:

TBW


## Hub API for listeners

* Get the `hubId`: `hub.getHubId()`
* Broadcast a message: `hub.emitMsg(msg, this)` (to all listeners except the sender)
* Build and broadcast a message: `hub.emitMsgWithFields('WS_CLIENT', type, data, this)` (to all listeners except the sender)
