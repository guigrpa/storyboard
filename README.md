# Storyboard [![Build Status](https://travis-ci.org/guigrpa/storyboard.svg?branch=master)](https://travis-ci.org/guigrpa/storyboard) [![Coverage Status](https://coveralls.io/repos/github/guigrpa/storyboard/badge.svg?branch=master)](https://coveralls.io/github/guigrpa/storyboard?branch=master) [![npm version](https://img.shields.io/npm/v/storyboard.svg)](https://www.npmjs.com/package/storyboard)

_**These are the docs for the upcoming Storyboard v2. The latest docs for v1.x can be recovered [here](https://github.com/guigrpa/storyboard/blob/v1.4.0/README.md). See also the [CHANGELOG](https://github.com/guigrpa/storyboard/blob/master/CHANGELOG.md) for details on new features and breaking changes.**_

![Storyboard DevTools](https://raw.githubusercontent.com/guigrpa/storyboard/master/docs/Storyboard.gif)

A library, plus a [Chrome DevTools extension](https://chrome.google.com/webstore/detail/storyboard-devtools/gficinaagglofbelmgdkknaefhpknccc).

Demo: http://storyboard-demo.herokuapp.com/

## Why?

* **Hierarchical stories**: put logs in context (*stories*), and group stories/logs within stories. Stories are extremely useful with concurrent user actions and async events.
* Get the whole picture with *end-to-end stories*: see all **client and server tasks** triggered by a user action (a click on the *Login* button, maybe) **in a single place**.
* Use the **Storyboard DevTools Chrome extension** to view client and server logs with a clean and detail-rich interface. Now with **remote client log monitoring for mobile devices** and non-Chrome browsers.
* Not ready to change your application to use this library? No worries, use the **CLI tool** to call it, giving you remote access to your logs and compatibility with the Storyboard DevTools.
* Watch server logs being pushed in **real time** to the Storyboard DevTools extension via WebSockets, with **opt-in client-server clock synchronization**. Even more: **control the level of detail you get from various parts of your server remotely, without relaunching**.
* Ask for **authentication** to see server logs; hook up your own auth function.
* **Attach anything** to your logs for further investigation.
* Integrate your app with Storyboard's **flexible plugin architecture**. Several plugins are available out of the box: Console, WebSocket Server & Client, File, (PostgreSQL) Database, and Browser Extension, with more coming up. Just use what you need: most features are optional!
* Give logs **source and severity** attributes and apply **coarse- or fine-grained filtering**, with white and black lists.
* Use **color** to highlight what's important. Storyboard extends the popular [chalk](https://github.com/chalk/chalk) library so that it can also be used on the browser.
* Enjoy the **simple-yet-powerful API** (I hope!).


## Installation

To add the **Storyboard library** to your project:

```bash
$ npm install --save storyboard
```

If you only need the CLI tool, see [this section](#cli-tool).

To install the **Storyboard DevTools** Chrome extension, [get it from the Chrome Web Store](https://chrome.google.com/webstore/detail/storyboard-devtools/gficinaagglofbelmgdkknaefhpknccc). Optional, but highly recommended! After installing it, open the Storyboard pane in the Chrome DevTools and point your browser to a Storyboard-equipped page (see below for how to use the library).

Feel free to check out the [example](https://github.com/guigrpa/storyboard/blob/master/src/example): just clone the repo and run `npm install && npm run buildExample && npm run example`. You can also test-drive the PostgreSQL Database listener with `npm run exampleWithDb`, but make sure you run [these SQL scripts](https://github.com/guigrpa/storyboard/blob/master/src/example/db.sql) before on your DB and [customize the connection parameters](https://github.com/guigrpa/storyboard/blob/master/src/example/serverWithDb.js).


## CLI tool

Hopefully the next sections will convince you of the benefits of adding Storyboard to your project. If you don't want to modify your existing application but still want to use the Storyboard DevTools or other Storyboard features, you can use the `sb` CLI tool:

```bash
$ npm install -g storyboard
$ sb --server ls

2016-07-15T17:26:33.974Z           storyboard INFO  ┌── ROOT STORY [CREATED]
2016-07-15T17:26:33.975Z           storyboard INFO  Log filter: *:DEBUG
2016-07-15T17:26:34.151Z           storyboard INFO  Logs available via web on port 8090
2016-07-15T17:26:34.154Z                 main INFO  CHANGELOG.md
2016-07-15T17:26:34.155Z                 main INFO  LICENSE
2016-07-15T17:26:34.155Z                 main INFO  README.md
2016-07-15T17:26:34.155Z                 main INFO  ROADMAP.md
2016-07-15T17:26:34.155Z                 main INFO  chromeExtension
2016-07-15T17:26:34.155Z                 main INFO  coverage
...
```

You can pipe `stdin` and `stdout` in the standard way:

```bash
$ sb ls | head -n 3

2016-07-15T14:41:47.573Z           storyboard INFO  ┌── ROOT STORY [CREATED]
2016-07-15T14:41:47.574Z           storyboard INFO  Log filter: *:DEBUG
2016-07-15T14:41:47.601Z                 main INFO  CHANGELOG.md

$ ls | sb -- head -n 3

2016-07-15T14:41:52.174Z           storyboard INFO  ┌── ROOT STORY [CREATED]
2016-07-15T14:41:52.176Z           storyboard INFO  Log filter: *:DEBUG
2016-07-15T14:41:52.201Z                 main INFO  CHANGELOG.md
2016-07-15T14:41:52.201Z                 main INFO  LICENSE
2016-07-15T14:41:52.201Z                 main INFO  README.md
2016-07-15T14:41:52.202Z                 main INFO  
2016-07-15T14:41:52.203Z           storyboard INFO  └── ROOT STORY [CLOSED]
```

*Note the use of the `--` separator: before the separator, options belong to the `sb` tool; after the separator, they belong to the called application.*

Here are the CLI tool configuration options:

```
$ sb --help

  Usage: sb [options] <command> [args...]

  Options:

    -h, --help         output usage information
    -V, --version      output the version number
    --no-console       Disable console output
    --stderr           Enable stderr for errors
    --no-colors        Disable color output
    -f, --file <path>  Save logs to file
    -s, --server       Launch web server for logs
    -p, --port <port>  Port for web server
```



## Storyboard library usage

### Basic usage

```js
import { mainStory, addListener } from 'storyboard';
import consoleListener from 'storyboard/lib/listeners/console';
addListener(consoleListener);

mainStory.info('Hello world!');
```

**_Note this breaking change in v2.0.0:_ As you can see above, Storyboard [no longer](https://github.com/guigrpa/storyboard/blob/master/CHANGELOG.md) enables listeners (plugins) by default, so you will need to do this manually upon startup.**


### Severity levels

```js
mainStory.trace('Teeny-weeny detail: x = 3, y = 4');
mainStory.debug('Called login()');
mainStory.info('User "admin" authenticated successfully');
mainStory.warn('Sad we can\'t show colors in GFM');
mainStory.error('User "admin" could not be authenticated', { attach: err });
mainStory.fatal('Ooops! Crashed! Mayday!', { attach: fatalError });
// ...
// 2016-03-09T16:18:19.659Z           main WARN  Sad we can't show colors in GFM
// 2016-03-09T16:18:19.672Z           main ERROR User "admin" could not be authenticated
// 2016-03-09T16:18:19.672Z           main ERROR   name: 'Error'
// 2016-03-09T16:18:19.672Z           main ERROR   message: 'AUTHENTICATION_ERROR'
// 2016-03-09T16:18:19.672Z           main ERROR   stack: Error: AUTHENTICATION_ERROR
// 2016-03-09T16:18:19.672Z           main ERROR   stack:     at repl:3:11
// ...
```

Maybe you noticed that the `trace` call produces no output by default. See [Log filtering](#log-filtering) to understand why.


### Sources

Namespace your logs for readability, as well as to allow finer-grained [filtering](#log-filtering) later on.

```js
mainStory.info('http', 'GET /api/item/25');
mainStory.info('db', 'Fetching item 25...');
// 2016-03-09T16:29:51.943Z           http INFO  GET /api/item/25
// 2016-03-09T16:31:52.231Z             db INFO  Fetching item 25...
```


### Colors

Use colors to highlight important parts of your logs:

```js
import { mainStory, chalk } from 'storyboard';
mainStory.info('http', `GET ${chalk.green.bold('/api/item/26')}`);
mainStory.info('db', `Fetching item ${chalk.green.bold('26')}...`);
// 2016-03-09T16:29:51.943Z           http INFO  GET /api/item/26
// 2016-03-09T16:31:52.231Z             db INFO  Fetching item 26...
```

As seen above, we recommend using the popular [chalk](https://github.com/chalk/chalk) library by Sindre Sorhus. Chalk is automatically extended by Storyboard for use in the browser. If you prefer another ANSI-color library, make sure it's universal and doesn't disable itself in the browser.


### Attachments

Attach anything to your logs that might provide additional context: an object, an array, an exception, a simple value... Don't worry about circular references, buffers, or `undefined`! Use the `attach` option to display it as a tree, or `attachInline` for a more compact, `JSON.stringify`-ed version.

You can also use the `attachLevel` option to control the (severity) level of the detailed object logs (by default: the same level of the main logged line). *Pro tip: use the `trace` level for long attachments ([hidden by default](#log-filtering)), so that they don't pollute your console but are still accessible via the [Storyboard DevTools](#storyboard-devtools) extension.*

```js
mainStory.info('test', 'A simple object', { attachInline: obj1 });
// 2016-03-09T16:51:16.436Z           test INFO  A simple object -- {"foo":2,"bar":3}
mainStory.info('test', 'An object with a circular reference', {
  attach: obj2,
  attachLevel: 'debug',
});
// 2016-03-09T16:52:48.882Z           test INFO  An object with a circular reference
// 2016-03-09T16:52:48.882Z           test DEBUG   foo: 2
// 2016-03-09T16:52:48.882Z           test DEBUG   bar: 3
// 2016-03-09T16:52:48.882Z           test DEBUG   circularRef: [CIRCULAR]
```

*Note: `attach` and `attachInline` have no effect on the way attachments are shown in the Storyboard DevTools.*


### Log filtering

Inspired by the popular [debug](https://github.com/visionmedia/debug) library, Storyboard allows you to filter logs according to source, specifying white and black lists and using wildcards. Beyond that, you can specify the minimum severity level you are interested in, depending on the source:

* `*:DEBUG` (default) or `*` will include logs from all sources, as long as they have severity `debug` or higher.
* `*:*` will include absolutely all logs.
* `foo` or `foo:DEBUG` will include logs from `foo` but exclude all other sources.
* `-test, *:*` will include all logs, except those from source `test`.
* `foo, bar:INFO, -test, *:WARN` will include logs from `foo` (`DEBUG` or higher), `bar` (`INFO` or higher), and all other sources (`WARN` or higher), but exclude source `test`.
* `ba*:*, -basket` will include all logs from `bar`, `baz`, etc. but exclude source `basket`.

In Node, you can configure log filtering via the `STORYBOARD` environment variable (have a look at [cross-env](https://github.com/kentcdodds/cross-env) for a cross-platform setup):

```bash
# OS X / Linux
$ STORYBOARD=*:* node myScript

# Windows
$ set "STORYBOARD=*:*" && node myScript
```

In the browser, use `localStorage`:

```js
localStorage.STORYBOARD = '*:*'
```

Alternatively, you can configure the log filters programatically:

```js
import storyboard from 'storyboard';
storyboard.config({ filter: '*:*' });
```

And even more convenient: configure filters remotely and without reloading by using the [Storyboard DevTools](#storyboard-devtools).


### Children stories

Create child stories by calling `child()` on the parent story and passing an options argument. Don't forget to `close()` the child story when you're done with it! More on child stories [here](#remote-access-to-server-stories).

```js
const story = mainStory.child({
  src: 'lib',
  title: 'Little Red Riding Hood',
  level: 'DEBUG',
});
story.info('Once upon a time...');
story.warn('...a wolf appeared!...');
story.info('...and they lived happily ever after.');
story.close();
// 2016-03-19T14:10:14.080Z        lib DEBUG ┌── Little Red Riding Hood [CREATED]
// 2016-03-19T14:10:14.083Z       main INFO  Once upon a time...
// 2016-03-19T14:10:14.085Z       main WARN  ...a wolf appeared!...
// 2016-03-19T14:10:14.087Z       main INFO  ...and they lived happily ever after.
// 2016-03-19T14:10:14.088Z        lib DEBUG └── Little Red Riding Hood [CLOSED]
```

*Pro tip: Child stories have `INFO` level by default, and can be completely hidden by [log filtering](#log-filtering). However, when a log with level `WARN` or higher is added to a hidden story, the story and all of its ancestors will become visible. You will not miss any errors, nor the actions that led to them!*


### Listeners (plugins)

Logs emitted by stories are relayed by the Storyboard *Hub* to all attached *listeners*. A Hub exists at the core of every Storyboard instance. Here is an example of a typical configuration, with a server-side Hub and a client-side Hub (other use cases have proved possible in production):

![Typical configuration](https://raw.githubusercontent.com/guigrpa/storyboard/master/docs/typical-arch.gif)

Several listeners come built-in (check out their [configuration options](https://github.com/guigrpa/storyboard/blob/master/docs/built-in-plugins.md), as well as the following sections):

* **Console**: formats logs and sends them to `console.log` or `console.error`. You've already seen this listener in action above.

* **WebSocket Server**: encapsulates logs and pushes them in real time to WebSocket clients. Used jointly with the WebSocket Client and Browser Extension, it allows [remote access to server stories](#remote-access-to-server-stories).

* **WebSocket Client**: downloads server logs from the WebSocket Server, and optionally [uploads client logs to the server for remote monitoring](#remote-access-to-client-stories).

* **Browser Extension**: relays logs to the [Storyboard DevTools](#storyboard-devtools).

* **File**: saves logs to file.

* **PostgreSQL Database**: saves logs to a PostgreSQL database for later retrieval, including (serialized) attachments, story hierarchy, etc.

More listeners can be added by the user (see [the API](https://github.com/guigrpa/storyboard/blob/master/docs/plugin-api.md)), e.g. to support different databases, integrate with other services, etc. Get inspired by [winston](https://github.com/winstonjs/winston)'s and [bunyan](https://github.com/trentm/node-bunyan)'s plugins. PRs are welcome!

**_Note this breaking change in v2.0.0:_ Storyboard [no longer](https://github.com/guigrpa/storyboard/blob/master/CHANGELOG.md) enables listeners (plugins) by default, so you will need to do this manually upon startup.**


### Remote access to server stories

**Standalone log server**

The simplest way to add remote access to a Node application's logs is to enable the WebSocket Server listener:

```js
// Server
import { addListener } from 'storyboard';
import wsServerListener from 'storyboard/lib/listeners/wsServer';
addListener(wsServerListener);
```

You now have a standalone HTTP server at port 8090 (by default) and can use the [Storyboard DevTools](#storyboard-devtools) to see your logs.

If you wish, you can add authentication:

```js
addListener(wsServerListener, {
  authenticate: ({ login, password }) => isAuthorized(login, password),
});
```


**Integrated log server**

You can also integrate the log server functionality with your own application server. This may be desirable if you want to use a single port, or if you want to see [end-to-end stories](#end-to-end-stories). In this case, your client application should enable the WebSocket Client listener and Browser Extension listener:

```js
// Client
import { addListener } from 'storyboard';
import wsClientListener from 'storyboard/lib/listeners/wsClient';
import browserExtListener from 'storyboard/lib/listeners/browserExtension';
addListener(wsClientListener);
addListener(browserExtListener);
```

At the server side, initialize the WebSocket Server listener with either your `http` `Server` instance, or your [socket.io](http://socket.io/) `Server` instance, depending on your case:

```js
// If your application doesn't use WebSockets:
import express from 'express';
import http from 'http';
const httpServer = http.createServer(express());
httpServer.listen(3000);
addListener(wsServerListener, { httpServer });

// If your application uses socket.io WebSockets without socket auth:
import socketio from 'socket.io';
const socketServer = socketio(httpServer);
addListener(wsServerListener, { socketServer });

// If your application uses sockets with auth, namespace them
// so that they don't clash with the log server's:
// At the server...
const io = socketServer.of('/myApp');
io.use(myAuthMiddleware);
io.on('connection', myConnectFunction);
// ...and at the client:
const socket = socketio.connect('/myApp')
```

Now when you open your client-side application, you can see both server *and* client logs in the Storyboard DevTools.


### Remote access to client stories

In some cases, you may want to remotely monitor client logs, e.g. if you are building a mobile web app, or you want to see the logs generated in non-Chrome browsers for which there is (currently) no [browser extension](#storyboard-devtools).

For these cases, you can configure your WebSocket Client listener so that it uploads its logs to the server, which can then provide remote access to them:

```js
import { addListener } from 'storyboard';
import wsClientListener from 'storyboard/lib/listeners/wsClient';
addListener(wsClientListener, { uploadClientStories: true });
```

Client logs will not pollute the server's own log, and will appear under a dedicated *browser root story* in the Storyboard DevTools, along with a short description of the remote client's platform:

![Remote monitoring](https://raw.githubusercontent.com/guigrpa/storyboard/master/docs/05-Remote%20monitoring.png)


### End-to-end stories

The icing on the cake is linking server- and client-side stories to get a complete picture of what is triggered by a user action (see video [at the top of this page](#what)).

Storyboard provides a simple yet flexible way to achieve this: stories can have multiple parents, which are specified upon creation. This feature is leveraged by the [Storyboard DevTools](#storyboard-devtools): when it receives a new story from the server with multiple parents, it checks whether any of the parents is a client-side story. If so, it prioritizes this parent for display purposes, since it is expected to provide more context.

For this to work, the client's `storyId` must be transmitted to the server *somehow*. This example uses the URL query string for simplicity, but feel free to use whatever technique you want (the body of a `POST` request, your own WebSocket messaging scheme, etc.):

```js
// Client:
const story = mainStory.child({
  src: 'itemList',
  title: 'User click on Refresh',
});
story.info('itemList', 'Fetching items...');
fetch(`/items?storyId=${story.storyId}`)
.then(response => response.json())
.then(items => story.info('itemList', `Fetched ${items.length} items`))
.finally(() => story.close());  // using Bluebird's terse API

// Server (using Express):
import express from 'express';
const app = express();
app.get('/items', (req, res) => {
  const { storyId } = req.query;
  const story = mainStory.child({
    src: 'http',
    title: `HTTP request ${req.url}`,
    extraParents: storyId != null ? [storyId] : undefined,
  });
  story.info('http', 'Processing request...');
  // ...
  res.json(items);
  story.close();
});
```

Want to see the end-to-end story? Use the Storyboard DevTools extension.

*Note: end-to-end stories work better when server and client system clocks are not too different. Servers are typically NTP-synchronized, as are most modern PCs with Internet access. If this is not the case, enable Storyboard 2.x's time synchronisation function:*

```js
import { addListener } from 'storyboard';
import wsClientListener from 'storyboard/lib/listeners/wsClient';
addListener(wsClientListener, { clockSync: true });
```


## Storyboard DevTools

![Storyboard DevTools](https://raw.githubusercontent.com/guigrpa/storyboard/master/docs/Marquee.png)

Enable the link to the browser extension in your application:

```js
import { addListener } from 'storyboard';
import browserExtListener from 'storyboard/lib/listeners/browserExtension';
addListener(browserExtListener);
```

After [installing the Chrome extension](https://chrome.google.com/webstore/detail/storyboard-devtools/gficinaagglofbelmgdkknaefhpknccc), open the Chrome DevTools, select the Storyboard pane and point your browser at either:

* Your standard application URL, to see both server and client logs
* Port 8090 (configurable) of your server, to see server logs only (+ uploaded client logs)

Some highlighted features:

* Modify the server's filter configuration without restarting it.
* Show a story chronologically (*flat*) or hierarchically (*tree*): hover on the story title for the button to appear.
* Collapse/expand stories: click on the caret. Even when stories are collapsed, detect that they contain an error or warning thanks to a special icon.
* Open attachments and exceptions: click on the folder icon.
* Choose among 3 timestamp formats: UTC, local or relative to now: click on any timestamp.
* Use quick find (case-insensitive) to highlight what you're looking for.
* See how identical, consecutive messages get squashed into a convenient summary line.
* Configure when and how Storyboard *forgets* old logs and stories.

You can check out your new extension navigating to: http://storyboard-demo.herokuapp.com/

Storyboard DevTools is built with [React](https://facebook.github.io/react/), [Redux](http://redux.js.org/) and [Redux-Saga](http://yelouafi.github.io/redux-saga/).


## [Changelog](https://github.com/guigrpa/storyboard/blob/master/CHANGELOG.md)

## License (MIT)

Copyright (c) [Guillermo Grau Panea](https://github.com/guigrpa) 2016

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
