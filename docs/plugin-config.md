# Built-in listeners (plugins)

Remember the generic way to enable a listener:

```js
import { addListener } from 'storyboard';
import consoleListener from 'storyboard-listener-console';
addListener(consoleListener, options);
```

The following sections describe the parameters you can pass as `options`.

## Console

**Purpose**: formats logs and sends them to `console.log` or `console.error`.

**Package**: `storyboard-listener-console`

**Options:**

* **`moduleNameLength`** *number* (default: `20`): number of characters dedicated to the `src` field (e.g. `main`, `storyboard`, `httpServer`, ...)
* **`colors`** *boolean* (default: `true`): enable/disable colors in output.
* **`relativeTime`** *boolean* (default: `true` browser-side, `false` otherwise): whether full timestamps are logged, or only relative. If `relativeTime` is enabled, time differences lower than 10 ms are not displayed, and those higher than 1 s introduce an extra line to make the log more readable.


## WebSocket Server

**Purpose**: encapsulates logs and pushes them in real time to WebSocket clients. Used jointly with the WebSocket Client and Browser Extension, it allows remote access to server stories.

**Package**: `storyboard-listener-ws-server`

See [usage hints](https://github.com/guigrpa/storyboard/blob/master/README.md#remote-access-to-server-stories).

**Options:**

* **`port`** *number* (default: `8090`): port for the standalone log server. Set to `null` to disable this server (does not affect integration with the existing application HTTP/socket.io server).
* **`throttle`** *number* (default: `200`): minimum interval to wait between consecutive broadcasts. Set to a falsy value for no throttling.
* **`authenticate`** *function* (default: `null`): authentication function:
    - **`credentials`** *object*: `login` and `password`
    - Returns *boolean|Promise of boolean*: whether the user is authenticated or not
* **`httpServer`** *object*: an `http` `Server` instance, which will be used to provide WebSocket services. *Provide either `httpServer`, `socketServer` or none.*
* **`socketServer`** *object*: a [socket.io](http://socket.io/) `Server` instance, which will be used to provide WebSocket services. *Provide either `httpServer`, `socketServer` or none.*


## WebSocket Client

**Purpose**: downloads server logs from the WebSocket Server, and optionally uploads client logs to the server for remote monitoring.

**Package**: `storyboard-listener-ws-client`

**Options:**

* **`uploadClientStories`** *boolean* (default: `false`): enable this flag for [remote access to client stories](https://github.com/guigrpa/storyboard/blob/master/README.md#remote-access-to-client-stories)
* **`throttleUpload`** *number* (default: `null`): minimum interval to wait between consecutive uploads. Set to a falsy value for no throttling.


## Browser Extension

**Purpose**: relays logs to the Storyboard DevTools.

**Package**: `storyboard-listener-browser-extension`

*No options available.*


## File

**Purpose**: saves logs to file.

**Package**: `storyboard-listener-file`

**Options:**

* **`moduleNameLength`** *number* (default: `20`): see [Console](#console).
* **`colors`** *boolean* (default: `false`): whether ANSI-color escapes should be kept before saving to file.
* **`filePath`** *string* (default: `storyboard.log`): relative path for the log file. If the file exists, new logs will be appended.


## PostgreSQL Database

**Purpose**: saves logs to a PostgreSQL database for later retrieval, including (serialized) attachments, story hierarchy, etc.

**Package**: `storyboard-listener-db-postgres`

**Options:**

* **`host`** *string* (default: `localhost`)
* **`port`** *number* (default: `process.env.PGPORT || 5432`)
* **`database`** *string* (default: `process.env.PGDATABASE`)
* **`table`** *string* (default: `logEntries`)
* **`user`** *string* (default: `process.env.PGUSER`)
* **`password`** *string* (default: `process.env.PGPASSWORD`)
* **`throttle`** *number* (default: `200`): minimum interval to wait between consecutive save operations. Set to a falsy value for no throttling.
* **`colors`** *boolean* (default: `true`): whether ANSI-color escapes should be kept before saving to the database.
