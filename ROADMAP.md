- [ ] Chrome extension:
    + Bubble up errors/ warnings, showing a flag in parent stories (up to, but not including, the client/server root stories)
    + Allow the user to filter out client root stories from other clients
    + Someday...
        * [ ] Better approach for app reducer? Handle actions in a single place. Check this: http://www.code-experience.com/problems-with-flux/
        * [ ] Client-server clock calibration
        * [ ] Algorithm for fixing server stories received *before* their parent client stories (e.g. when uploading: server stories that happen before the socket is established): save story IDs for which the client-parent is unavailable for later (a hash, just like `openStories` and `closedStories`: `pendingClientParentStories`? :) ). When the client-parent appears, move the story and delete the story ID from the list.
- [ ] Lib:
    + [ ] Remove storyboard-core dependencies, contents -- and add warning to readme.md
    + [ ] Better console behaviour in FF
    + [ ] Try to get all WS Server unit tests back to work
