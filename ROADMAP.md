- [ ] Library:
    + [ ] More tests
    + [ ] Better tests for WS Server listener (currently skipped)
    + [ ] Stories with levels:
        * [x] Add attribute to story
        * [x] Story actions published with same level as story
        * [x] Console listener: always show level
        * [x] Filter story action records -- implies:
            - Chrome extension will ignore the existence of some stories
            - When it receives a log belonging to one of those stories, it will put it on the main story. Id. for child stories
        * [x] Should we also filter out normal logs within a filtered story?
            - It seems reasonable that everything under that story should be hidden, EXCEPT if at level WARN or above (error conditions), in which the normal filter rules would apply (i.e. source and level)
            - If a WARN+ log appears inside a filtered story (or its descendants), the story should become visible again --> even if out of chronological order. Before the embedded log, Stories should output all previous story actions.
        * [ ] Document child levels

- [ ] Chrome extension:
    + [ ] Better approach for app reducer? Handle actions in a single place. Check this: http://www.code-experience.com/problems-with-flux/
    - [ ] Periodically, go through the story tree and "forget" logs and (closed) stories...
