ffmpeg -i "Storyboard overview.mov" -s 600x400 -pix_fmt rgb24 -r 10 -f gif - | gifsicle --optimize=3 --delay=10 > out.gif

var express = require('express');
Promise = require('bluebird');
var app = express();
var {mainStory} = require('.');
var h = function(req, res) {    var { storyId } = req.query;    var extraParents = (storyId !== undefined) ? [storyId] : undefined;    var st = mainStory.child({ src: "http", title: `HTTP request ${req.url}`, extraParents });    st.info("http", "Processing request...");    res.json([1,2,3]);    st.close(); };
app.get("/items", h);
app.listen(3005);


require('isomorphic-fetch');
var story = mainStory.child({src: "itemList", title: "User click on Refresh"});
story.info("itemList", "Fetching items...");
fetch(`http://localhost:3005/items?storyId=${story.storyId}`).then(response => response.json()).then(items => story.info("itemList", `Fetched ${items.length} items`)).finally(() => story.close());


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
