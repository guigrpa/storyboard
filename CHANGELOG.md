# Changelog

*[M]: major change; [m]: minor change*

* Library:
    - [m] Add `withConsoleListener.js` convenience initialiser, for the most common case in which we just want to attach a console listener:

    ```js
    import { mainStory } from 'storyboard/lib/withConsoleListener';

    mainStory.info('That was fast!');
    ```

## 2.0.1 (July 18, 2016)

* Minor documentation changes.

## 2.0.0 (July 18, 2016)

**Breaking changes**

* **No listeners are installed by default**. The default behaviour in v1 was to automatically install some listeners, depending on whether Storyboard ran on the server or the client and the development/production mode. This was very convenient out of the box, but made it harder to customize the configuration in certain setups. If you need the old default behaviour, use this (note that for conditionally bundling listeners we recommend sticking to `require` for the time being):

    ```js
    import { addListener } from 'storyboard';

    // Server
    import consoleListener from 'storyboard/lib/listeners/console';
    addListener(consoleListener);

    // Client
    if (process.env.NODE_ENV !== 'production') {
        addListener(require('storyboard/lib/listeners/console').default);
        addListener(require('storyboard/lib/listeners/browserExtension').default);
        addListener(require('storyboard/lib/listeners/wsClient').default);
    }
    ```

* **Listeners have been migrated to ES6**. Notice above the different way to use them, depending on whether you `import` them (ES6 module) or `require` them (CommonJS):

    ```js
    // ES6 module
    import fileListener from 'storyboard/lib/listeners/file';
    addListener(fileListener);

    // CommonJS module
    const fileListener = require('storyboard/lib/listeners/file').default;
    addListener(fileListener);
    ```

* **The Console listener no longer uses `stderr` on Node, to avoid out-of-order logs** (see [this link](https://nodejs.org/api/console.html#console_asynchronous_vs_synchronous_consoles) for some background); it now uses `stdout` for all log levels. If you want the old behaviour, configure it with `useStderr: true`. On the browser, `console.error()` is used as before.

**Other changes**

* **Add a command-line interface (CLI) tool to use Storyboard on unmodified applications/modules** (i.e. without requiring the use of the library). This tool wraps the application and allows redirecting the logs to a file, the console and/or the web (using the WebSocket Server listener). In principle, this makes *any* application compatible with the Storyboard DevTools. [More details here](https://github.com/guigrpa/storyboard/blob/master/README.md#cli-tool).
* Library:
    - [M] Implement a **refined listener architecture**, affecting in particular the client side. These changes should be transparent to the user. The WsClient listener no longer interfaces directly with the browser extension, but rather relays its messages via the hub. The BrowserExtension listener has been merged with the interfaceExtension helper, since no other module can have access to this interface any more. This architecture **is more flexible and will allow other uses of the library**, e.g. using the WsClient listener in a non-browser application to obtain logs from another process and offload database access or file storage.
    - [M] **WebSocket Server and Client can now estimate their clock differences**, so that timestamps correspond to (approximately) the client's system clock. This functionality is disabled by default, but can be opted in by setting `clockSync: true` in the WebSocket Client configuration.
    - [M] **Add Postgres database listener**: stores logs to a PostgreSQL database, including attachments.
    - [M] **Add file listener**: stores all logs to a file, with or without ANSI color escapes (disabled by default).
    - [M] **Better attachment serialization**. `undefined` values will no longer disappear from your attachments when they traverse the WebSocket interface between the WsServer and WsClient plugins.
    - [m] Improve graceful exits, tearing down all listeners if possible. Previously, we only closed the main story.
* Browser extension:
    - [m] Settings: show version.
    - Bugfix: Settings: Fix hysteresis tooltip.
* Internal:
    - Ongoing migration from CoffeeScript to JS.

## 1.4.0 (June 29, 2016)

* Browser extension:
    - [M] **Improve behaviour when server restarts** (always download the server's new records)
    - [m] Click on the warning icon in a story title to expand the story.

## 1.3.1 (June 29, 2016)

* [m] Show **buffers** nicely within attachments.
* Bugfix: Correct serialization of exceptions.
* Bugfix: Fix an issue in the browser extension where an incorrect attachment would be open when clicked upon after a server reset.

## 1.3.0 (June 9, 2016)

* Browser extension:
    - [m] Use [Giu](http://guigrpa.github.io/giu/) components for the UI
    - [m] Add some validation on the settings
    - [m] Simplify cxReducer state
    - [m] Fix panel charset (required for Redux devtools)
* Lib:
    - [M] **Attach objects in their original shape (not simplified), after removal of possible circular refs**
    - [m] Add `stdinLogger` tool (result from issue #11): use it to log via Storyboard the output of any command, e.g. `ls | node stdinLogger.js`
    - [m] Fix incorrect filter config when user enters a blank string

## 1.2.0 (Apr. 19, 2016)

* Browser extension:
    - [M] **Allow the user to configure the filters used by the server and local client**
    - [M] **Add warning icon to collapsed stories containing warnings/errors**
    - [m] Allow the user to filter out client root stories from other clients
* Lib:
    - [m] Internal: the Storyboard entry point now just re-exports the `noPlugins` API, enabling listeners as in the previous version (hence, non-breaking change)

## 1.1.1 (Apr. 12, 2016)

* Lib:
    - [M] Fix a regression concerning the client side of the server logs (standalone) app: plugins were not included in the minified/production version

## 1.1.0 (Apr. 12, 2016)

* Lib:
    - [M] Add **remote log monitoring**: logs can be uploaded by the WS Client listener, e.g. from mobile devices or non-Chrome browsers, and monitored from a remote Storyboard DevTools somewhere else.
    - [M] Split WS Client listener in two:
        + WS Client listener (dedicated just to WebSockets)
        + Browser Extension listener (relays client-side logs to the browser extension)
    - [M] Include a *no-plugins* version of Storyboard (at `storyboard/lib/noPlugins`), which might become default in future major releases. Using this version prevents socket.io from getting into your bundle, if you don't need it.
* Browser extension:
    - [M] For servers requiring no auth for logs: Automatically retrieve server backlog upon startup
    - [m] Bumped React to v15.0.1

## 1.0.0 (Apr. 5, 2016)

* Enforce semver
* Lib:
    - [m] Publish chalk as part of the top-level API: `storyboard.chalk`. This is for convenience, as well as to prevent duplicate instances of chalk in certain setups (should not happen anyway if you use `npm@3` and include `chalk@^1.0.0`).

## 0.1.3 (Mar. 30, 2016)

* Browser extension:
    - [M] **Add shorthand representation for "identical, consecutive logs"**
    - [m] Allow user configuration of the maximum number of logs/stories to be remembered
    - Thorough testing of storyReducer
    - Add tests for all other reducers

## 0.1.2 (Mar. 28, 2016)

* Lib:
    - Add unit tests for most modules
* Browser extension:
    - [M] **Add the capability to forget logs and closed stories**
    - Add very limited unit tests (concerning the storyReducer)
* Tooling:
    - Use `nyc` instead of `istanbul` for coverage testing (simplifies merging coverage reports)

## 0.1.1 (Mar. 19, 2016)

**Not a breaking change, but still noteworthy:** Stories now have a level attribute and are subject to filtering, the same way as logs. The default story level is `INFO`. Depending on your filter configuration, you may start filtering out some stories.

* Lib:
    - Stories:
        + [M] **Add level attribute to stories (same as for logs)**
        + [M] **Filter out stories completely according to source and level**, even if they contain logs that would have been visible (up to INFO level). Logs at WARN or above turn their ancestor stories visible again.
    - Console Listener:
        + [m] Show story levels
        + [m] Hide story ID
        + [m] Hide time in attachment lines (just as in the browser extension)
        + [m] Highlight action lines
    - WS Client Listener:
        + [m] Stop dumping internal Storyboard messages to the console
* Browser extension:
    - [m] Swap severity and source columns for coherence with console output
    - [m] Show story levels
    - [m] Tweak style of some components

## 0.1.0 (Mar. 15, 2016)

* First public release
