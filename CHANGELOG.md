# Changelog

* Browser extension: 
    - [m] Swap severity and source columns for coherence wiht console output
    - [m] Show story levels
    - [m] Tweak style of some components
* Lib: 
    - Stories:
        + [M] Add story level
        + [M] Filter out stories completely according to source and level, even if they contain logs that would have been visible (up to INFO level). Logs at WARN or above make their ancestor stories visible, if needed.
    - Console Listener: 
        + [m] Show story levels
        + [m] Hide story ID
        + [m] Hide time in attachment lines (just as in the browser extension)
        + [m] Highlight action lines
    - WS Client Listener: 
        + [m] Stop dumping internal Storyboard messages to the console

## 0.1.0 (Mar. 15, 2016)

* First public release.
