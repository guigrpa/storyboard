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

	module.exports = __webpack_require__(2);


/***/ },
/* 1 */,
/* 2 */
/***/ function(module, exports) {

	var _bgConnection;

	_bgConnection = null;

	window.addEventListener('message', function(event) {
	  var data, ref, src, type;
	  if (event.source !== window) {
	    return;
	  }
	  ref = event.data, src = ref.src, type = ref.type, data = ref.data;
	  if (src !== 'PAGE') {
	    return;
	  }
	  if (type === 'CONNECT_REQUEST') {
	    _bgConnection = chrome.runtime.connect();
	    _bgConnection.onMessage.addListener(function(msg) {
	      return window.postMessage(msg, '*');
	    });
	  }
	  return _bgConnection != null ? _bgConnection.postMessage(event.data) : void 0;
	});


/***/ }
/******/ ]);