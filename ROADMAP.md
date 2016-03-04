- [ ] Library:
    + [ ] Add tests
    + [ ] Tree lines: support non-objects (arrays, booleans, etc)
    + [ ] Level thresholding:
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
        * Useful code from `debug`:

```js
function enable(namespaces) {
  exports.save(namespaces);

  var split = (namespaces || '').split(/[\s,]+/);
  var len = split.length;

  for (var i = 0; i < len; i++) {
    if (!split[i]) continue; // ignore empty strings
    namespaces = split[i].replace(/\*/g, '.*?');
    if (namespaces[0] === '-') {
      exports.skips.push(new RegExp('^' + namespaces.substr(1) + '$'));
    } else {
      exports.names.push(new RegExp('^' + namespaces + '$'));
    }
  }
}

// ...

function enabled(name) {
  var i, len;
  for (i = 0, len = exports.skips.length; i < len; i++) {
    if (exports.skips[i].test(name)) {
      return false;
    }
  }
  for (i = 0, len = exports.names.length; i < len; i++) {
    if (exports.names[i].test(name)) {
      return true;
    }
  }
  return false;
}
```



- [ ] Chrome extension
    - [ ] Don't use TOGGLE actions, at least for settings - better "SET" them (to be able to set them based on stored settings)
    - [ ] Reduce the number of spans in a line
    - [ ] Log out
    - [ ] Handle scrolling: when user is within X pixels of the bottom, keep him anchored there
    - [ ] Forget logs and (closed) stories...
    - [ ] Save prefs to localStorage (works for Chrome exts?)
    - [ ] Quick find (with highlighting)
    - [ ] Filtering
