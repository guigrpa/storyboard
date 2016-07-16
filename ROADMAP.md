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
    + [x] Improve serialize/deserialize. Deserialize before calling treeLines. Improve serialize, support even undefined.
    + [x] Lint
    + [x] Add listener to write to database (choose a simple one)
    + [x] Document listener config options
    + [x] Client-server clock calibration:
        * [x] First version
        * [x] What happens when tab is in the background? sync starts to drift...
        * [x] Allow the user to disable clock sync (disabled by default)
        * [x] When we're sure, only print initial clock delta, not subsequent ones (set them to `TRACE`)
    + [x] Document listener API
    + [x] Console listener: make it configurable not to write anything to `stderr`, using `stdout` instead (to avoid out-of-order logs)
    + [X] Improve cli:
    + [X] Publish 2.0.0-alpha.5 with cli and test it
    + [X] When revealing a hidden story (error/warning): include a separator line in the log to indicate that those records are FROM THE PAST. This separator should ONLY be included in chronological listeners: console and file, and generated at mainStory level.
    + [x] Document cli
    + [x] Reduce lodash dependency
    + [ ] Architecture diagram, graphical vocabulary, different use cases
    + [ ] Publish 2.0.0-rc1
    + [ ] Check compilation of storyboard with browserify (e.g. bump mady): does it keep clocksy and storyboard credits?
    + [ ] Review docs
    + [ ] Release 2.0.0
    + [ ] React App: embeddable SB components (without requiring extension)
