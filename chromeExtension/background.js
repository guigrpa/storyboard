/******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};

/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {

/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId])
/******/ 			return installedModules[moduleId].exports;

/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			exports: {},
/******/ 			id: moduleId,
/******/ 			loaded: false
/******/ 		};

/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);

/******/ 		// Flag the module as loaded
/******/ 		module.loaded = true;

/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}


/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;

/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;

/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "/";

/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(0);
/******/ })
/************************************************************************/
/******/ ([
/* 0 */
/***/ function(module, exports, __webpack_require__) {

	module.exports = __webpack_require__(1);


/***/ },
/* 1 */
/***/ function(module, exports) {

	var _connections, _logConnections;

	_connections = {};

	console.log("[BG] Launching...");

	_logConnections = function() {
	  var connections, results, tabId;
	  console.log("[BG] Current connections:");
	  results = [];
	  for (tabId in _connections) {
	    connections = _connections[tabId];
	    results.push(console.log(("- " + tabId + ": ") + ("DT: " + (connections.DT != null ? 'YES' : 'NO') + ", ") + ("CS: " + (connections.CS != null ? 'YES' : 'NO'))));
	  }
	  return results;
	};

	chrome.runtime.onConnect.addListener(function(port) {
	  var listener, ref;
	  console.log("[BG] Connected: " + port.sender.url + " [tabId: " + ((ref = port.sender.tab) != null ? ref.id : void 0) + "]");
	  listener = function(msg) {
	    var cxType, data, dst, ref1, ref2, ref3, ref4, src, tabId, type;
	    src = msg.src, dst = msg.dst, type = msg.type, data = msg.data;
	    console.log("[BG] RX " + src + "/" + type, data);
	    if (type === 'CONNECT_REQUEST') {
	      tabId = (function() {
	        switch (src) {
	          case 'DT':
	            return dst;
	          case 'PAGE':
	            return port.sender.tab.id;
	        }
	      })();
	      if (tabId == null) {
	        console.error("[BG] Could not determine the tab ID associated to the connection");
	        return;
	      }
	      if (_connections[tabId] == null) {
	        _connections[tabId] = {};
	      }
	      cxType = src === 'PAGE' ? 'CS' : 'DT';
	      _connections[tabId][cxType] = port;
	      _logConnections();
	    }
	    switch (src) {
	      case 'PAGE':
	        return (ref1 = _connections[port.sender.tab.id]) != null ? (ref2 = ref1.DT) != null ? ref2.postMessage(msg) : void 0 : void 0;
	      case 'DT':
	        return (ref3 = _connections[dst]) != null ? (ref4 = ref3.CS) != null ? ref4.postMessage(msg) : void 0 : void 0;
	    }
	  };
	  port.onMessage.addListener(listener);
	  return port.onDisconnect.addListener(function() {
	    var connection, connections, cxType, tabId;
	    port.onMessage.removeListener(listener);
	    for (tabId in _connections) {
	      connections = _connections[tabId];
	      for (cxType in connections) {
	        connection = connections[cxType];
	        if (connection === port) {
	          delete _connections[tabId][cxType];
	          if ((_connections[tabId].DT == null) && (_connections[tabId].CS == null)) {
	            delete _connections[tabId];
	          }
	          break;
	        }
	      }
	    }
	    _logConnections();
	  });
	});


/***/ }
/******/ ]);