# storyboard [![Build Status](https://travis-ci.org/guigrpa/storyboard.svg)](https://travis-ci.org/guigrpa/storyboard) [![npm version](https://img.shields.io/npm/v/storyboard.svg)](https://www.npmjs.com/package/storyboard) 

## What?

A library, plus a Chrome DevTools extension.

![Storyboard DevTools](https://github.com/guigrpa/storyboard/blob/master/docs/Storyboard.gif?raw=true)

## Why?

* **Hierarchical stories**: put logs in context (*stories*), and stories/logs within stories. Such groupings are extremely useful with concurrent user actions.
* Watch the whole picture with **end-to-end stories**: see all client and server tasks triggered by a user action (a click on the *Login* button, maybe) in a single place.
* Use the **Chrome extension** to view client and server logs with a clean and detail-rich interface.
* Watch server logs being pushed in **real time** (and out-of-the-box) to the Storyboard DevTools extension via WebSockets.
* Ask for **authentication** to see server logs; hook your own auth function.
* **Attach things** to your logs for further investigation.
* Integrate your app with Storyboard's **flexible plugin architecture**. Three plugins are available out of the box: Console, WebSocket Server and WebSocket Client. Just use what you want: most features are optional!
* Give logs **source and severity levels** and apply **coarse- or fine-grained filtering**, with white and black lists.
* Use **color** to highlight what's important. Storyboard extends the popular [chalk](https://github.com/chalk/chalk) library so that it can also be used on the browser.
* Enjoy the **simple-yet-powerful API** (I hope!).


## How?

### Installation

To install the **Storyboard library** in your project:

```
$ npm install --save storyboard
```

To install the **Storyboard DevTools** Chrome extension, get it from the Chrome Web Store. Optional, but highly recommended! After installing it, open the Storyboard pane in the Chrome DevTools and point your browser to a Storyboard-equipped page (see the following sections).

Feel free to check out the [example](https://github.com/guigrpa/storyboard/blob/master/src/example): just clone the repo and run `npm install && npm run buildExample && npm run example`.


### Basic usage

```js
var {mainStory: story} = require("storyboard");
story.info("Hello world!");
```


### Severity levels

```js
story.trace("Teeny-weeny detail: x = 3, y = 4");
story.debug("Called login()");
story.info("User 'admin' authenticated successfully");
story.warn("Sad we can't show colors in GFM");
story.error("User 'admin' could not be authenticated", {attach: err});
story.fatal("Ooops! Crashed! Mayday!", {attach: fatalError});
// ...
// 2016-03-09T16:18:19.659Z           main WARN  Sad we can't show colors in GFM
// 2016-03-09T16:18:19.672Z           main ERROR User 'admin' could not be authenticated
// 2016-03-09T16:18:19.672Z           main ERROR   name: 'Error'
// 2016-03-09T16:18:19.672Z           main ERROR   message: 'AUTHENTICATION_ERROR'
// 2016-03-09T16:18:19.672Z           main ERROR   stack: Error: AUTHENTICATION_ERROR
// 2016-03-09T16:18:19.672Z           main ERROR   stack:     at repl:3:11
// ...
```

Maybe you noticed that the `trace` call does not produce any output. See [Log filtering](#log-filtering) to understand why.


### Sources

Namespace your logs for readability, as well as to allow finer-grained filtering later on.

```js
story.info("http", "GET /api/item/25");
story.info("db", "Fetching item 25...");
// 2016-03-09T16:29:51.943Z           http INFO  GET /api/item/25
// 2016-03-09T16:31:52.231Z             db INFO  Fetching item 25...
```


### Colors

Use colors to highlight important parts of your logs:

```js
story.info("http", `GET ${chalk.green.bold("/api/item/26")}`);
story.info("db", `Fetching item ${chalk.green.bold("26")}...`);
// 2016-03-09T16:29:51.943Z           http INFO  GET /api/item/26
// 2016-03-09T16:31:52.231Z             db INFO  Fetching item 26...
```

We recommend using the popular [chalk](https://github.com/chalk/chalk) library by Sindre Sorhus. Chalk is automatically extended by Storyboard for use in the browser. If you prefer another ANSI-color library, make sure it's universal and doesn't disable itself in the browser.


### Attachments

Attach anything to your logs that might provide additional context: an object, an array, an exception, a simple value... Don't worry about circular references! Use the `attach` option to display attachments as a tree, or `attachInline` for a more compact, `JSON.stringify`ed version.

You can also use the `attachLevel` option to control the (severity) level of the detailed object logs (by default: the same level of the main logged line).

```js
story.info("test", "A simple object", {attachInline: obj1})
// 2016-03-09T16:51:16.436Z           test INFO  A simple object -- {"foo":2,"bar":3}
story.info("test", "An object with a circular reference", 
  {attach: obj2, attachLevel: "debug"})
// 2016-03-09T16:52:48.882Z           test INFO  An object with a circular reference
// 2016-03-09T16:52:48.882Z           test DEBUG   foo: 2
// 2016-03-09T16:52:48.882Z           test DEBUG   bar: 3
// 2016-03-09T16:52:48.882Z           test DEBUG   circularRef: [CIRCULAR]
```

Note that `attach` and `attachInline` have no effect on the way attachments are shown in the Storyboard DevTools.


### Log filtering

Inspired by the popular [debug](https://github.com/visionmedia/debug) library, Storyboard allows you to filter logs according to source, specifying white and black lists and using wildcards. Beyond that, you can specify the minimum severity level you are interested in, depending on the source:

* `*:DEBUG` (default) or `*` will include logs from all sources, as long as they have severity `debug` or higher.
* `*:*` will include absolutely all logs.
* `foo` or `foo:DEBUG` will include logs from `foo` but exclude all other sources.
* `-test, *:*` will include all logs, except those from source `test`.
* `foo, bar:INFO, -test, *:WARN` will include logs from `foo` (`DEBUG` or higher), `bar` (`INFO` or higher), and all other sources (`WARN` or higher), but exclude source `test`.
* `ba*:*, -basket` will include all logs from `bar`, `baz`, etc. but exclude source `basket`.

In Node, you can configure log filtering via the `STORYBOARD` environment variable:

```bash
# OS X / Linux
STORYBOARD=*:* node myScript
# Windows
set "STORYBOARD=*:*" && node myScript
```

In the browser, use `localStorage`:

```js
localStorage.STORYBOARD = "*:*"
```

Alternatively, you can configure the log filters programatically:

```js
var storyboard = require("storyboard");
storyboard.config({filter: "*:*"});
```


### Children stories

Create child stories by calling `child()` on the parent story and passing an options argument. Don't forget to `close()` the child story when you're done with it!

```js
var childStory = story.child({src: "lib", title: "Little Red Riding Hood"});
childStory.info("Once upon a time...");
childStory.warn("...a wolf appeared!...");
childStory.info("...and they lived happily ever after.");
childStory.close();
// 2016-03-09T17:28:35.574Z     lib ----- ss/ce8b2 - Little Red Riding Hood [CREATED]
// 2016-03-09T17:28:35.578Z    main INFO  Once upon a time...
// 2016-03-09T17:28:35.580Z    main WARN  ...a wolf appeared!...
// 2016-03-09T17:28:35.582Z    main INFO  ...and they lived happily ever after.
// 2016-03-09T17:28:35.586Z     lib ----- ss/ce8b2 - Little Red Riding Hood [CLOSED]
```


### Listeners

Logs emitted by stories are relayed by the Storyboard `hub` module to all attached *listeners*. Three listeners come built-in:

* **Console**: formats logs and sends them to `console.log` or `console.error`. You've already seen this listener in action in the previous sections. It is automatically enabled in the server, and in development mode (`NODE_ENV` environment variable set to `development` while bundling) in the browser.

* **WebSocket Server**: encapsulates logs and pushes them in real time to WebSocket clients. It is disabled by default. Enable it for [remote access to server stories](#remote-access-to-server-stories).

* **WebSocket Client**: takes logs pushed from the server, as well as local client logs and relays them to the Storyboard DevTools. It is automatically enabled in the browser.

More listeners can be added by the user, e.g. to persist logs in a database, publish them online, etc. Get inspired by [winston](https://github.com/winstonjs/winston)'s or [bunyan](https://www.npmjs.com/package/bunyan)'s plugins.


### Remote access to server stories

Adding remote access to a Node application is easy; just attach the WebSocket Server listener as follows:

```js
var storyboard = require("storyboard");
var wsServer = require("storyboard/lib/listeners/wsServer");
storyboard.addListener(wsServer);
```

You can call `addListener()` with an additional `options` object overriding the following defaults or including additional parameters:

```js
var options = {
  port: 8090,           // port for standalone log server
  throttle: 200,        // [ms] send logs at most every X ms
  authenticate: null,   // no authentication function
  httpServer: null,     // no integration with existing HTTP server
  socketServer: null,   // no integration with existing socket.io server
};
```

You'll probably want to configure the `authenticate` function (without it, your server logs become public by enabling the listener):

```js
// Example #1: synchronous
storyboard.addListener(wsServer, {
  authenticate: ({login, password}) => true
});

// Example #2: asynchronous (returning a promise)
storyboard.addListener(wsServer, {
  authenticate: ({login, password}) => Promise.resolve(true)
});
```

Configuring `options.port`, `options.httpServer` and/or `options.socketServer` lets you configure 0, 1 or 2 log servers:

* If you want to set up a **standalone HTTP server** (independent from your main application HTTP server), leave the default `port` value or specify a different port. You'll be able to see your server-side logs with the Storyboard DevTools. Disable the standalone server by setting `port` to `null`.

* If you want to supercharge your **main application HTTP server for [end-to-end stories](#end-to-end-stories)**, find your case below:

    1. If you don't already use WebSockets, pass the `http` `Server` instance as `options.httpServer`:

        ```js
        var http = require("http");
        var app = require("express")();
        var httpServer = http.createServer(app);
        httpServer.listen(3000);
        storyboard.addListener(wsServer, {httpServer});
        ```

    2. If your main server uses [socket.io](https://github.com/socketio/socket.io) WebSockets, pass the `socket.io` `Server` instance as `options.socketServer`:

        ```js
        var socketServer = socketio(httpServer);
        storyboard.addListener(wsServer, {socketServer});
    
        // If you use socket authentication, make sure you namespace the main app's
        // sockets so that it does not interfere with the log server.
        // At the server...
        var io = socketServer.of("/myApp");
        io.use(socketAuthenticate);
        io.on("connection", socketConnect);
        // ...and at the client:
        var socket = socketio.connect("/myApp")
        ```


### End-to-end stories

The icing on the cake is linking server- and client-side stories to have a complete picture of what is triggered by a user action (see video [at the top of this page](#what)). 

Storyboard provides a simple yet flexible way to accomplish this: stories can have multiple parents, which are specified upon creation. This is leveraged for example by the Storyboard DevTools: when it receives a new story from the server with multiple parents, it checks whether any of the parents is a client-side story. If so, it prioritises this parent for display purposes, since it is expected to provide more context.

In order for this to work, the client's `storyId` must be transmitted to the server somehow. This example uses the URL query string for simplicity, but feel free to use whatever you want (the body of a `POST` request, your own WebSocket messaging scheme, etc.):

```js
// Client:
var story = mainStory.child({src: "itemList", title: "User click on Refresh"});
story.info("itemList", "Fetching items...");
fetch(`/items?storyId=${story.storyId}`)
.then(response => response.json())
.then(items => story.info("itemList", `Fetched ${items.length} items`))
.finally(() => story.close());  // using Bluebird's terse API

// Server (using Express):
var app = require("express")();
app.get("/items", function(req, res){
  var {storyId} = req.query;
  var extraParents = (storyId !== undefined) ? [storyId] : undefined;
  var story = mainStory.child({
    src: "http", 
    title: `HTTP request ${req.url}`,
    extraParents
  });
  story.info("http", "Processing request...")
  // ...
  res.json(items);
  story.close();
});
```

Want to see the end-to-end story? Use the [Storyboard DevTools](#storyboard-devtools) extension.

*Note: end-to-end stories work better when server and client system clocks are not too different. Servers are typically NTP-synchronised, as are most modern PCs with Internet access. If this is not the case, your story hierarchy will be OK but mixed client-server stories might be out of order.*


### Storyboard DevTools

Using the Storyboard DevTools should be pretty straightforward. Just open the Chrome DevTools, select the Storyboard pane and point your browser at either:

* Your standard application URL, to see both server and client logs
* Port 8090 (configurable) of your server, to see server logs only

Some highlighted features:

* Show a story chronologically (*flat*) or hierarchically (*tree*): hover on the story title for the button to appear.
* Collapse/expand stories: click on the caret.
* Open attachments, including exceptions: click on the folder icon.
* 3 timestamp formats: UTC, local or relative to now: click on any timestamp.
* Use quick find (case-insensitive) to highlight what you're looking for.

Storyboard DevTools is built with [React](https://facebook.github.io/react/), [Redux](http://redux.js.org/) and [Redux-Saga](http://yelouafi.github.io/redux-saga/).


## Shall I? — The MIT license

Copyright (c) [Guillermo Grau Panea](https://github.com/guigrpa) 2016

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
