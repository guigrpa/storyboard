- **Conversion to monorepo**
    + Foreseen dir structure:
        - packages
            - [x] storyboard
            - [x] storyboard-core (<-- src/gral, .flow types, recordToLines, vendor)
            - [x] storyboard-cli
            - [x] storyboard-listener-console
            - [x] storyboard-listener-file
            - [x] storyboard-listener-db-postgres (--> pg)
            - [ ] storyboard-listener-ws-server (--> express, socket.io). Includes serverLogsApp
            - [ ] storyboard-listener-browser-extension
            - [ ] storyboard-listener-ws-client (--> socket.io-client)
            - [ ] storyboard-extension-chrome (private)
            - [ ] storyboard-examples (private)
        - docs
        - scripts
        - test
        - testJest
        - tools
        - ...
    + [x] Remove deprecated SW:
        - noPlugins.js
        - stdinLogger.js
        - withConsoleListener.js
    + [ ] Versioning: synchronised, but packages that have no changes are not released.
      This should be automated to avoid problems. The tool should ask for a new version number,
      and then determine which packages will be released. A commit is then performed and tagged.
    + [ ] Publishing:
        - Tool builds, which includes:
            - Copy README to packages/storyboard
            - Copy README stub to other packages
            - Copy certain fields from <root>/package.json to all packages:
              description, keywords, author, license, homepage/bugs/repository, etc.
        - Tool asks for new version number
        - Tool determines which packages will be released
        - Tool updates selected packages
        - Tool commits and tags
        -
    + [ ] Tests
    + [ ] Preset: check with default and named exports

- Hints: login, settings

- Bugs:
    +
- **Chrome extension**:
    + Add config screenshot
    + Someday...
        * [ ] Better approach for app reducer? Handle actions in a single place. Check this: http://www.code-experience.com/problems-with-flux/
        * [ ] Algorithm for fixing server stories received *before* their parent client stories (e.g. when uploading: server stories that happen before the socket is established): save story IDs for which the client-parent is unavailable for later (a hash, just like `openStories` and `closedStories`: `pendingClientParentStories`? :) ). When the client-parent appears, move the story and delete the story ID from the list.
- **Lib**:
    + [ ] React App: embeddable SB components (without requiring extension)
- **Chrome extension**:
    + [ ] Remove CJSX code
    + [ ] Add Jest snapshots to assist in code conversion
    + [ ] Clean up automatically converted CJSX code
    + [ ] Bump React, use PureComponent where possible
