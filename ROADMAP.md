- Bugs:
    + 
- **Chrome extension**:
    + Add config screenshot
    + Someday...
        * [ ] Client-server clock calibration
        * [ ] Better approach for app reducer? Handle actions in a single place. Check this: http://www.code-experience.com/problems-with-flux/
        * [ ] Algorithm for fixing server stories received *before* their parent client stories (e.g. when uploading: server stories that happen before the socket is established): save story IDs for which the client-parent is unavailable for later (a hash, just like `openStories` and `closedStories`: `pendingClientParentStories`? :) ). When the client-parent appears, move the story and delete the story ID from the list.
- **Lib**:
    + [x] Add listener to write to file
    + [x] Migrate to JS: WS listeners, so that their APIs are all the same
    + [x] Change hub.emit() to emit different types of messages, not records
    + [x] Update all listeners to use the new hub API (both for tx and rx)
    + [x] Change WsClient listener so that it doesn't use interfaceExtension (sends messages through the hub)
    + [ ] Merge browserExtension and interfaceExtension. In the CONNECTION_REQUEST and CONNECTION_RESPONSE sent by the hub, include the hubId.
    + [ ] Use the browserExtension's hubId to better determine which root stories are to be removed by the storyReducer
    + [ ] Remove process.nextTick() from WsServerListener

    + [ ] Add listener to write to database (choose a simple one)
    + [ ] Update docs
    + [ ] Publish 2.0.0-rc1
    + [ ] Migrate client and clientWithUpload.coffee
    + [ ] React App: embeddable SB components (without requiring extension)
    + [ ] Try to get all WS Server unit tests back to work
    + Working with out-of-order logs:
        * [ ] When revealing a hidden story (error/warning): include a separator line in the log to indicate that those records are FROM THE PAST
        * [ ] Console listener: make it configurable not to write anything to `stderr`, using `stdout` instead (to avoid out-of-order logs)
