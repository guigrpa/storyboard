# Changelog

*[M]: major change; [m]: minor change*

* Browser extension:
    - [M] **Allow the user to configure the filters used by the server and local client**
    - [m] Allow the user to filter out client root stories from other clients

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
    - [m] Swap severity and source columns for coherence wiht console output
    - [m] Show story levels
    - [m] Tweak style of some components

## 0.1.0 (Mar. 15, 2016)

* First public release
