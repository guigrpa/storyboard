- **Conversion to monorepo**
    * Prerelease: check versions: none should be higher than the master one
    * Manual version updates, tagging
    * Automated publishing:
        * Ask the user whether he has run yarn build
        * Determine which packages need publishing and do it (npm publish)
    * Automated publishing (warn if not master, compare published version with current package, publish if needed)
    + [ ] Preset: check with default and named exports
    + [ ] Normal: check flow interface

- [ ] **Bump versions**

- Add hints: login, settings

- Bugs:
    +
- **Chrome extension**:
    + Add config screenshot
    + Someday...
        * [ ] Better approach for app reducer? Handle actions in a single place. Check this: http://www.code-experience.com/problems-with-flux/
        * [ ] Algorithm for fixing server stories received *before* their parent client stories (e.g. when uploading: server stories that happen before the socket is established): save story IDs for which the client-parent is unavailable for later (a hash, just like `openStories` and `closedStories`: `pendingClientParentStories`? :) ). When the client-parent appears, move the story and delete the story ID from the list.
- **Lib**:
    + [ ] React App: embeddable SB components (without requiring extension)
