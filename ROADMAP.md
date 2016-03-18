- [ ] Library:
    + [ ] More tests
    + [ ] Better tests for WS Server listener (currently skipped)
    + [ ] Stories with levels:
        * Add attribute to story
        * Story actions published with same level as story
        * Include story records in the filter -- implies:
            - Chrome extension will ignore the existence of some stories
            - When it receives a log belonging to one of those stories, it will put it on the main story
        * Console listener: always show level (simplification)

- [ ] Chrome extension:
    + [ ] Better approach for app reducer? Handle actions in a single place. Check this: http://www.code-experience.com/problems-with-flux/
    - [ ] Periodically, go through the story tree and "forget" logs and (closed) stories...
