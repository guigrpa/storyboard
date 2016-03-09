# storyboard [![Build Status](https://travis-ci.org/guigrpa/storyboard.svg)](https://travis-ci.org/guigrpa/storyboard) [![npm version](https://img.shields.io/npm/v/storyboard.svg)](https://www.npmjs.com/package/storyboard) 

## What?

A library, plus a DevTools extension (currently for Chrome).

![Storyboard DevTools](https://github.com/guigrpa/storyboard/blob/master/docs/xxxx.png?raw=true)


## Why?

* **Hierarchical stories**: a *story* is a group of logs and other stories, extremely useful with concurrent user actions.
* **End-to-end stories**: don't lose track of your stories; all client and server logs related to a user click (a Login button, maybe) in a single place.
* **Chrome extension**: use it to view client and server logs with a clean and detail-rich interface.
* **Real-time**: server logs can be pushed out-of-the-box to the Storyboard DevTools extension via websockets.
* **Authentication**: of course, you don't want to grant access to server logs to everybody; hook your own auth function.
* **Simple-yet-complete API**: severity levels, sources, story status, etc.
* **Attachments**: logs can include all sorts of attachments
* **Flexible architecture** with stories, a hub, and listeners (plugins). Three plugins are available out of the box: console, WebSocket server and WebSocket client. Just use what you want: most features are optional!
* **Log filtering** by source and severity levels, with white and black lists.
* **Colorful logs**: based on the popular [chalk](https://github.com/chalk/chalk) library, extended so that it can also be used on the browser.


## How?

### Installation

To install the Storyboard library in your project:

```
$ npm install --save storyboard
```

To install the Storyboard DevTools extension for Chrome, get it from the Chrome Web Store. Optional, but highly recommended! After installing it, open the Storyboard in the DevTools and point your browser to a Storyboard-equipped page (see the following sections).

Feel free to check out the [example](https://github.com/guigrpa/storyboard/blob/master/src/example) in this repo. To try it out, clone the repo and run `npm install && npm run buildExample && npm run example`.


### Basic usage

```js
var {mainStory: story} = require('storyboard');
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

We recommend using the popular [chalk](https://github.com/chalk/chalk) library by Sindre Sorhus. Chalk is automatically extended by Storyboard for use in the browser. If you use another ANSI-color library, make sure it's universal and doesn't disable itself in the browser.


### Attachments

Attach anything that might provide context to your logs: an object, an array, an exception, a simple value... Don't worry about circular references! Use the `attach` option to show attachments as a tree in the console, or `attachInline` to show a more compact, `JSON.stringify`ed version of the object.

You can also use the `attachLevel` option to control the (severity) level of the detailed object logs (by default: the same level of the main logged line).

```js
story.info("test", "A simple object", {attachInline: obj1})
// 2016-03-09T16:51:16.436Z           test INFO  A simple object -- {"foo":2,"bar":3}
story.info("test", "An object with a circular reference", 
  {attach: obj2, attachLevel: 'debug'})
// 2016-03-09T16:52:48.882Z           test INFO  An object with a circular reference
// 2016-03-09T16:52:48.882Z           test DEBUG   foo: 2
// 2016-03-09T16:52:48.882Z           test DEBUG   bar: 3
// 2016-03-09T16:52:48.882Z           test DEBUG   circularRef: [CIRCULAR]
```

Note that `attach` and `attachInline` have no effect on the way attachments are shown in the Storyboard DevTools.


### Log filtering

Inspired by the popular [debug](https://github.com/visionmedia/debug) library, Storyboard allows you to filter logs according to source, specifying white and black lists and using wildcards. Beyond that, you can specify the minimum severity level you are interested in, depending on the source:

<<<< remove colons after config

* `*:DEBUG` (default) or `*`: will show logs from all sources, as long as they have severity `debug` or higher
* `*:*`: will show absolutely all logs
* `foo` or `foo:DEBUG`: will show logs from `foo` but no logs from any other source
* `-test, *:*`: will show all logs, except those from source `test`
* `foo, bar:INFO, -test, *:WARN`: will show logs from `foo` (`DEBUG` or higher), `bar` (`INFO` or higher), and all other modules (`WARN` or higher), but nothing from source `test`
* `ba*:*, -basket`, will show all logs from `bar`, `baz`, etc. but not from `basket`

In Node, you can configure filter logs via the `STORYBOARD` environment variable:

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

Logs emitted by stories are relayed by the Storyboard `hub` module to all attached *listeners*. Storyboard comes with three listeners built-in:

* **Console listener**: formats logs and sends them to `console.log` or `console.error`. You've already seen this listener in action in the previous sections. It is automatically enabled in the server, and in development mode in the browser.

* **Websocket server listener**: encapsulates logs and pushes them in real-time to Websocket clients. It is disabled by default. Enable it for [remote access to server stories](#remote-access-to-server-stories)

* **Websocket client listener**: takes logs pushed from the server, as well as local client logs and relays them to the Storyboard DevTools (if installed). It is automatically enabled in the browser.

More listeners can be added by the user, e.g. to persist logs in a database, publish them online, etc. Get inspired by [winston](https://github.com/winstonjs/winston)'s or [bunyan](https://www.npmjs.com/package/bunyan)'s plugins.


### Remote access to server stories

Adding remote access to a Node application is easy; just attach the Websocket server listener as follows:

```js
var storyboard = require("storyboard");
var wsServer = require("storyboard/lib/listeners/wsServer");
storyboard.addListener(wsServer);
```

You can call `addListener()` with an additional `options` object overriding the following defaults or including additional parameters:

```js
var options = {
  port: 8090,           // standalone server logs port
  throttle: 200,        // [ms] send logs at most every X ms
  authenticate: null,   // no authentication function
};
```

Most probably, you'll want to configure the `authenticate` function:

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

* If you want to set up a **standalone HTTP server** (independent from your main application HTTP server), leave the default `port` value or specify a different port. You'll be able to see your server-side logs with the Storyboard DevTools. Disable this server by setting `port` to `null`.

* If you want to use your **main application HTTP server**, find your case below. This is most interesting, since it enables [end-to-end stories](#linking-server-and-client-stories).

    + If you don't already use websockets, pass the `http` `Server` instance as `options.httpServer`:

    ```js
    var http = require('http');
    var app = require('express')();
    var httpServer = http.createServer(app);
    httpServer.listen(3000);
    storyboard.addListener(wsServer, {httpServer});
    ```

    + If your main server uses [socket.io](https://github.com/socketio/socket.io) websockets, pass the `socket.io` `Server` instance as `options.socketServer`:

    ```js
    var socketServer = socketio(httpServer);
    storyboard.addListener(wsServer, {socketServer});
    // If you use socket authentication, make sure you namespace the main app's
    // sockets so that it does not interfere with the log server
    var io = socketServer.of("/myApp");
    io.use(socketAuthenticate);
    io.on("connection", socketConnect);
    ```


### Linking server and client stories


### Storyboard DevTools

Using the Storyboard DevTools is (or should be) very straightforward. Just open the Chrome DevTools, select the Storyboard pane and point your browser at either:

- Your standard port (80), to see both server and client logs
- Port 8090 (configurable) of your server, to see server logs only




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
