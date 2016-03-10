- [ ] Library:
    + [ ] More tests
    + [ ] Separate wsClient listener in two: one only for WS, the other for just relaying client logs. Refactor the common parts

- [ ] Chrome extension
    + [ ] Add setting: collapseAllNewStories. It will imply cross-state between storyReducer and settingsReducer!
    + [ ] Better way to add listeners than `require 'storyboard/dist/listeners/xxx` ?
    + [ ] Improve perf with very long logs
    - [ ] Forget logs and (closed) stories...
    - [ ] Animation: show lines immediately, then add an animation to show the new elements
