        * Config is debug-library-like:
            - Env variables (server-side) and localstorage (client-side)
            - Comma-separated list
            - Include/exclude components (excluded have preference)
        * Add Storyboard global in the browser, to simplify configuration (`Storyboard.filter("*:WARN")`)
        * Examples:
            - *empty* (default: `*:INFO`)
            - `*` (equals `*:INFO`)
            - `*:WARN` (every src, WARN or higher, i.e. not INFO or lower)
            - `a:TRACE, b:DEBUG, -c, *:WARN`
                + First we process the exclusions: `c` will never get shown
                + Then we process the inclusions from left to right:
                    * `a` will get TRACE level
                    * `b` will get DEBUG level
                    * All other modules will get WARN level
        * Implemented at the source (`stories` module)
