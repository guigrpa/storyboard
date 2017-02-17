# Storyboard Listener API

For an example of how to implement a Storyboard listener (plugin), check out the [ConsoleListener](https://github.com/guigrpa/storyboard/blob/master/src/listeners/console.js), arguably the simplest built-in listener. Listeners should follow the API described in this document.


## Listener methods

### `constructor()` *(optional)*

* **`config`** *object*: user configuration options. Should typically be merged with some defaults and stored in the listener instance.
* **`context`** *object*:
    - **`hub`** *object*: the hub instance this listener is attached to. See [Hub API for listeners](#hub-api-for-listeners) below.
    - **`chalk`** *object*: a pre-configured, always-enabled version of the chalk library.
    - **`mainStory`** *object*: Storyboard's main story, which can be used to generate logs the same way as a library user:

        ```js
        class MyListener {
          constructor(config, { hub, mainStory }) {
            this.hub = hub;
            this.mainStory = mainStory;
          }

          init() {
            this.mainStory.info('myListener', 'Listener is up and running!');
          }
        }
        ```


### `getConfig()` *(mandatory)*

* *No arguments*
* Returns *object*: current listener configuration.


### configure(config) *(optional)*

* Merges the provided object with the current configuration. You may want to support changes to configuration after initialisation, but this is not mandatory.
* **`config`** *object*: new configuration options.
* *No return value*


### `init()` *(optional)*

* Executes initialisation operations, e.g. connects to a database, opens a file, etc.
* *No arguments*
* *No return value*


### `tearDown()` *(optional)*

* Executes tear-down operations, e.g. disconnects from a database, closes a file, etc.
* *No arguments*
* *No return value*


### `process()` *(mandatory)*

* Processes a message from the hub, e.g. saves records to a database, writes them to a file, relays them to a browser extension, uploads them to a server, etc.
* **`msg`** *object*: a message from the hub, containing:
    - **`type`** *string*: the type of message, e.g. `RECORDS`, `LOGIN_REQUEST`, `LOGIN_RESPONSE`, `SET_SERVER_FILTER`... Typical listeners discard messages with `type` other than `RECORDS`.
    - **`hubId`** *string*: the ID of the hub to which the originating listener is attached. Typical listeners discard messages from hubs other than the one they are attached to.
    - **`src`** *string*: an indication of the message originator, e.g. `STORIES` (a story), `WS_CLIENT` (the WebSocket Client listener; used for signalling). When a message is relayed by a listener, it should not change its `src` field.
    - **`data`** *any*: the message payload; its format is defined by the message `type`: e.g. an array of log records for `RECORDS`, a filter string for `SET_SERVER_FILTER`, clock sync data for `CLOCKSY`, etc.
* *No return value*


## Listener module

Wrap your listener in a module and export a creator function:

```js
import { addDefaults } from 'timm';
const DEFAULT_CONFIG = { /* ... */ };
const create = (userConfig, context) =>
  new MyListener(addDefaults(userConfig, DEFAULT_CONFIG), context);

export default create;
```

Users can add your listener in the standard way:

```js
import myListener from './myListener';
import { addListener } from 'storyboard';
addListener(myListener, { /* custom config */ });
```


## Hub API for listeners

The listener constructor is passed a reference to some hub methods:

### `hub.getHubId()`

* Provides the ID of the hub our listener is attached to.
* *No arguments*
* Returns *string*: hub ID

### `hub.emitMsg()`

* Re-broadcasts a message (that has been previously received via a call to `processMsg()`).
* **`msg`** *object*: the message to be relayed (contents are described in `processMsg()` above)
* **`srcListener`** *object*: pass `this` if you don't want to get the message back from the hub when it re-broadcasts it.
* *No return value*

### `hub.emitMsgWithFields()`

* Builds a new message a broadcasts it to all attached listeners.
* **`src`** *string*: an identifier for the originating listener, e.g. `WS_CLIENT`.
* **`type`** *string*: see `msg` contents in `processMsg()` above.
* **`data`** *any*: see `msg` contents in `processMsg()` above.
* **`srcListener`** *object*: pass `this` if you don't want to get the message back from the hub when it broadcasts it.
