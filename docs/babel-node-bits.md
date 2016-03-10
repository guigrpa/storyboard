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
