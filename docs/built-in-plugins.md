# Built-in listeners (plugins)

Remember the generic way to enable a listener:

```js
import { mainStory, addListener } from 'storyboard';
import consoleListener from 'storyboard/lib/listeners/console';
addListener(consoleListener, options);
```

The following sections describe the parameters you can pass as `options`.

## Console

Module: `storyboard/lib/listeners/console`

Options:

* **moduleNameLength** *number* (default: `20`): number of characters dedicated to the `src` field (e.g. `main`, `storyboard`, `httpServer`, ...)
* **relativeTime** *boolean* (default: `true` at the browser, `false` otherwise): whether full timestamps are logged, or only relative. If `relativeTime` is enabled, time differences lower than 10 ms are not logged, and those higher than 1 s introduce an extra line to make the log more readable.

## File

Module: `storyboard/lib/listeners/file`

Options:

* **moduleNameLength** *number* (default: `20`): see [Console](#console).
* **colors** *boolean* (default: `false`): whether ANSI-color escapes should be kept before saving to file.
* **filePath** *string* (default: `storyboard.log`): relative path for the log file. If the file exists, new logs will be appended.

## PostgreSQL Database

Module: `storyboard/lib/listeners/dbPostgres`

Options:

* **host** *string* (default: `localhost`)
* **port** *number* (default: `process.env.PGPORT || 5432`)
* **database** *string* (default: `process.env.PGDATABASE`)
* **table** *string* (default: `logEntried`)
* **user** *string* (default: `process.env.PGUSER`)
* **password** *string* (default: `process.env.PGPASSWORD`)
* **throttle** *number* (default: `200`): minimum interval to wait between consecutive save operations. Set to a falsy value for no throttling.
* **colors** *boolean* (default: `true`): whether ANSI-color escapes should be kept before saving to the database.

## Browser Extension

Module: `storyboard/lib/listeners/browserExtension`

*No options available.*

## WebSocket Server

Module: `storyboard/lib/listeners/wsServer`

See [usage hints](https://github.com/guigrpa/storyboard/blob/master/README.md#remote-access-to-server-stories).

Options:

* TBW

## WebSocket Client

Module: `storyboard/lib/listeners/wsClient`

Options:

* **uploadClientStories** *boolean* (default: `false`). Enable this flag for [remote access to client stories](https://github.com/guigrpa/storyboard/blob/master/README.md#remote-access-to-client-stories)
* **throttleUpload** *number* (default: `null`): minimum interval to wait between consecutive uploads. Set to a falsy value for no throttling.
