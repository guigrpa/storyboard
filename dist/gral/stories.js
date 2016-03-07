(function() {
  var DEFAULT_CHILD_TITLE, DEFAULT_SRC, Story, _, _emit, _getRecordId, _getStoryId, _recordId, _storyId, filters, hub, k, mainStory, title, uuid;

  uuid = require('node-uuid');

  _ = require('../vendor/lodash');

  hub = require('./hub');

  k = require('./constants');

  filters = require('./filters');

  DEFAULT_SRC = 'main';

  DEFAULT_CHILD_TITLE = '';

  _storyId = 0;

  _getStoryId = function() {
    return (k.IS_BROWSER ? "cs/" : "ss/") + uuid.v4();
  };

  _recordId = 0;

  _getRecordId = function() {
    if (k.IS_BROWSER) {
      return "c" + (_recordId++);
    } else {
      return "s" + (_recordId++);
    }
  };

  Story = function(parents, src, title) {
    this.parents = parents;
    this.fRoot = !parents.length;
    this.storyId = this.fRoot ? '*' : _getStoryId();
    this.src = src;
    this.title = title;
    this.fServer = !k.IS_BROWSER;
    this.t = new Date().getTime();
    this.fOpen = true;
    this.status = void 0;
    return this.logStory('CREATED', this.t);
  };

  Story.prototype.close = function() {
    this.fOpen = false;
    return this.logStory('CLOSED');
  };

  Story.prototype.changeTitle = function(title) {
    this.title = title;
    return this.logStory('TITLE_CHANGED');
  };

  Story.prototype.changeStatus = function(status) {
    this.status = status;
    return this.logStory('STATUS_CHANGED');
  };

  Story.prototype.addParent = function(id) {
    return this.parents.push(id);
  };

  Story.prototype.child = function(options) {
    var extraParents, parents, ref, ref1, src, title;
    if (options == null) {
      options = {};
    }
    src = (ref = options.src) != null ? ref : DEFAULT_SRC, title = (ref1 = options.title) != null ? ref1 : DEFAULT_CHILD_TITLE, extraParents = options.extraParents;
    parents = [this.storyId];
    if (extraParents != null) {
      parents = parents.concat(extraParents);
    }
    return new Story(parents, src, title);
  };

  _.each(k.LEVEL_NUM_TO_STR, function(levelStr, levelNum) {
    if (levelStr === 'STORY') {
      return;
    }
    return Story.prototype[levelStr.toLowerCase()] = function(src, msg, options) {
      var objLevel, record, ref, ref1, ref2, ref3, ref4;
      if (arguments.length <= 1) {
        msg = (ref = arguments[0]) != null ? ref : '';
        src = DEFAULT_SRC;
      } else if (_.isObject(arguments[1])) {
        options = arguments[1];
        msg = (ref1 = arguments[0]) != null ? ref1 : '';
        src = DEFAULT_SRC;
      }
      if (options == null) {
        options = {};
      }
      record = {
        storyId: this.storyId,
        level: levelNum,
        src: src,
        msg: msg
      };
      if (options.hasOwnProperty('attach')) {
        record.obj = options.attach;
        record.objExpanded = !((ref2 = options.attachInline) != null ? ref2 : false);
      } else if (options.hasOwnProperty('attachInline')) {
        record.obj = options.attachInline;
        record.objExpanded = false;
      }
      if (record.hasOwnProperty('obj')) {
        objLevel = (ref3 = k.LEVEL_STR_TO_NUM[(ref4 = options.attachLevel) != null ? ref4.toUpperCase() : void 0]) != null ? ref3 : levelNum;
        record.objLevel = objLevel;
        record.objOptions = _.pick(options, ['ignoreKeys']);
        record.objIsError = _.isError(record.obj);
      }
      return _emit(record);
    };
  });

  Story.prototype.logStory = function(action, t) {
    return _emit({
      parents: this.parents,
      fRoot: this.fRoot,
      storyId: this.storyId,
      src: this.src,
      title: this.title,
      fServer: this.fServer,
      t: t,
      fOpen: this.fOpen,
      status: this.status,
      fStory: true,
      action: action
    });
  };

  _emit = function(record) {
    if (!record.fStory) {
      if (!filters.passesFilter(record.src, record.level)) {
        return;
      }
    }
    record.id = _getRecordId();
    if (record.t == null) {
      record.t = new Date().getTime();
    }
    record.fServer = !k.IS_BROWSER;
    hub.emit(record);
  };

  title = (k.IS_BROWSER ? 'BROWSER' : 'SERVER') + ' ROOT STORY';

  mainStory = new Story([], 'storyboard', title);

  module.exports = mainStory;

}).call(this);
