# Changelog

*[M]: major change; [m]: minor change*

* Lib:
    - Add unit tests for most tests
* Browser extension:
    - [M] Add the capability to forget logs and closed stories
    - Add very limited unit tests (concerning the storyReducer)
* Tooling:
    - Use `nyc` instead of `istanbul` for coverage testing (simplifies merging coverage reports)
    
## 0.1.1 (Mar. 19, 2016)

**Not a breaking change, but still noteworthy:** Stories now have a level attribute and are subject to filtering, the same way as logs. The default story level is `INFO`. Depending on your filter configuration, you may start filtering out some stories.

* Lib: 
    - Stories:
        + [M] Add story level
        + [M] Filter out stories completely according to source and level, even if they contain logs that would have been visible (up to INFO level). Logs at WARN or above turn their ancestor stories visible again.
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

* First public release.
