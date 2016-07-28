- Heroku: remove login -- many people don't try it and miss out on server-side logs!

- UI colors:
  - Smart color substitution (replace unreadable colors)
  - Fix background color when scrolling down
- Fix anchor to bottom
- Hints: login, settings

- Bugs:
    +
- **Chrome extension**:
    + Allow color customisation
    + Add config screenshot
    + Someday...
        * [ ] Better approach for app reducer? Handle actions in a single place. Check this: http://www.code-experience.com/problems-with-flux/
        * [ ] Algorithm for fixing server stories received *before* their parent client stories (e.g. when uploading: server stories that happen before the socket is established): save story IDs for which the client-parent is unavailable for later (a hash, just like `openStories` and `closedStories`: `pendingClientParentStories`? :) ). When the client-parent appears, move the story and delete the story ID from the list.
- **Lib**:
    + [ ] React App: embeddable SB components (without requiring extension)
    + [ ] Continue migration to JS
