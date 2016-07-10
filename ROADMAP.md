- Bugs:
    + 
- **Chrome extension**:
    + Add config screenshot
    + Someday...
        * [ ] Better approach for app reducer? Handle actions in a single place. Check this: http://www.code-experience.com/problems-with-flux/
        * [ ] Algorithm for fixing server stories received *before* their parent client stories (e.g. when uploading: server stories that happen before the socket is established): save story IDs for which the client-parent is unavailable for later (a hash, just like `openStories` and `closedStories`: `pendingClientParentStories`? :) ). When the client-parent appears, move the story and delete the story ID from the list.
- **Lib**:
    + [x] Remove process.nextTick() from WsServerListener
    + [x] Migrate client and clientWithUpload.coffee
    + [ ] Throttle log generation at the very source??
    + [ ] Improve serialize/deserialize. Desearialize before calling treeLines. Improve serialize, support even undefined.
    + [ ] Lint

    + [ ] Add listener to write to database (choose a simple one)
    + [ ] Document listener API
    + [ ] Update docs
    + [ ] Client-server clock calibration
    + [ ] Publish 2.0.0-rc1
    + [ ] React App: embeddable SB components (without requiring extension)
    + Working with out-of-order logs:
        * [ ] When revealing a hidden story (error/warning): include a separator line in the log to indicate that those records are FROM THE PAST
        * [ ] Console listener: make it configurable not to write anything to `stderr`, using `stdout` instead (to avoid out-of-order logs)
