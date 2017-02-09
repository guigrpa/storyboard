/* eslint-disable react/no-multi-comp, react/prefer-stateless-function */
import React from 'react';
import * as ReactRedux from 'react-redux';
import { set as timmSet } from 'timm';
import dateFormat from 'date-fns/format';
import dateDistanceInWords from 'date-fns/distance_in_words_strict';
import { Icon, Spinner, cancelEvent } from 'giu';
import { _, chalk, ansiColors, treeLines, serialize, constants } from 'storyboard-core';
import * as actions from '../actions/actions';
import ColoredText from './030-coloredText';

const doQuickFind = (msg0, quickFind) => {
  if (!quickFind.length) return msg0;
  const re = new RegExp(quickFind, 'gi');
  return msg0.replace(re, chalk.bgYellow('$1'));
};

// ======================================================
// Story
// ======================================================
const mapStateToProps = (state) => ({
  timeType: state.settings.timeType,
  fShowClosedActions: state.settings.fShowClosedActions,
  quickFind: state.stories.quickFind,
});

const mapDispatchToProps = {
  setTimeType: actions.setTimeType,
  onToggleExpanded: actions.toggleExpanded,
  onToggleHierarchical: actions.toggleHierarchical,
  onToggleAttachment: actions.toggleAttachment,
};

class Story extends React.Component {
  static propTypes = {
    story: React.PropTypes.object.isRequired,
    level: React.PropTypes.number.isRequired,
    seqFullRefresh: React.PropTypes.number.isRequired,
    timeRef: React.PropTypes.number,
    setTimeRef: React.PropTypes.func.isRequired,
    colors: React.PropTypes.object.isRequired,
    // From Redux.connect (for the top-most story; other
    // child stories inherit them)
    timeType: React.PropTypes.string.isRequired,
    fShowClosedActions: React.PropTypes.bool.isRequired,
    quickFind: React.PropTypes.string.isRequired,
    setTimeType: React.PropTypes.func.isRequired,
    onToggleExpanded: React.PropTypes.func.isRequired,
    onToggleHierarchical: React.PropTypes.func.isRequired,
    onToggleAttachment: React.PropTypes.func.isRequired,
  };

  // -----------------------------------------------------
  render() {
    if (this.props.story.fWrapper) return <div>{this.renderRecords()}</div>;
    if (this.props.level === 1) return this.renderRootStory();
    return this.renderNormalStory();
  }

  renderRootStory() {
    const { level, story, colors } = this.props;
    return (
      <div className="rootStory" style={styleStory.outer(level, story, colors)}>
        <MainStoryTitle
          title={story.title}
          numRecords={story.numRecords}
          fHierarchical={story.fHierarchical}
          fExpanded={story.fExpanded}
          onToggleExpanded={this.toggleExpanded}
          onToggleHierarchical={this.toggleHierarchical}
        />
        {this.renderRecords()}
      </div>
    );
  }

  renderNormalStory() {
    const { level, story, colors } = this.props;
    return (
      <div className="story" style={styleStory.outer(level, story, colors)}>
        <Line
          record={story}
          level={this.props.level}
          fDirectChild={false}
          timeType={this.props.timeType}
          timeRef={this.props.timeRef}
          setTimeType={this.props.setTimeType}
          setTimeRef={this.props.setTimeRef}
          quickFind={this.props.quickFind}
          onToggleExpanded={this.toggleExpanded}
          onToggleHierarchical={this.toggleHierarchical}
          seqFullRefresh={this.props.seqFullRefresh}
          colors={colors}
        />
        {this.renderRecords()}
      </div>
    );
  }

  renderRecords() {
    if (!this.props.story.fExpanded) return null;
    const records = this.prepareRecords(this.props.story.records);
    let out = [];
    for (let i = 0; i < records.length; i++) {
      const record = records[i];
      const el = this.renderRecord(record);
      if (el == null) continue;
      out.push(el);
      if (record.objExpanded && record.obj != null) {
        out = out.concat(this.renderAttachment(record));
      }
      if (record.repetitions) out.push(this.renderRepetitions(record));
    }
    return out;
  }

  renderRecord(record) {
    const { id, fStoryObject, storyId, action } = record;
    const fDirectChild = storyId === this.props.story.storyId;
    if (fStoryObject) {
      return (
        <Story
          key={storyId}
          story={record}
          level={this.props.level + 1}
          seqFullRefresh={this.props.seqFullRefresh}
          colors={this.props.colors}
          timeType={this.props.timeType}
          timeRef={this.props.timeRef}
          fShowClosedActions={this.props.fShowClosedActions}
          quickFind={this.props.quickFind}
          setTimeType={this.props.setTimeType}
          setTimeRef={this.props.setTimeRef}
          onToggleExpanded={this.props.onToggleExpanded}
          onToggleHierarchical={this.props.onToggleHierarchical}
          onToggleAttachment={this.props.onToggleAttachment}
        />
      );
    }
    if (fDirectChild) {
      if (action === 'CREATED') return null;
      if (!this.props.fShowClosedActions && action === 'CLOSED') return null;
    }
    return (
      <Line
        key={`${storyId}_${id}`}
        record={record}
        level={this.props.level}
        fDirectChild={fDirectChild}
        timeType={this.props.timeType}
        timeRef={this.props.timeRef}
        setTimeType={this.props.setTimeType}
        setTimeRef={this.props.setTimeRef}
        quickFind={this.props.quickFind}
        onToggleAttachment={this.toggleAttachment}
        seqFullRefresh={this.props.seqFullRefresh}
        colors={this.props.colors}
      />
    );
  }

  renderAttachment(record) {
    const { storyId, id, obj, objOptions, version } = record;
    const props = _.pick(this.props, [
      'level', 'timeType', 'timeRef', 'setTimeType', 'setTimeRef',
      'quickFind', 'seqFullRefresh', 'colors',
    ]);
    const lines = version >= 2 ? treeLines(serialize.deserialize(obj), objOptions) : obj;
    return lines.map((line, idx) =>
      /* eslint-disable react/no-array-index-key */
      <AttachmentLine
        key={`${storyId}_${id}_${idx}`}
        record={record}
        {...props}
        msg={line}
      />
      /* eslint-enable react/no-array-index-key */
    );
  }

  renderRepetitions(record) {
    const { storyId, id } = record;
    const props = _.pick(this.props, [
      'level', 'timeType', 'timeRef', 'setTimeType', 'setTimeRef',
      'quickFind', 'seqFullRefresh', 'colors',
    ]);
    return (
      <RepetitionLine
        key={`${storyId}_${id}_repetitions`}
        record={record}
        {...props}
      />
    );
  }

  // -----------------------------------------------------
  toggleExpanded = () => {
    this.props.onToggleExpanded(this.props.story.pathStr);
  }

  toggleHierarchical = () => {
    this.props.onToggleHierarchical(this.props.story.pathStr);
  }

  toggleAttachment = (recordId) => {
    this.props.onToggleAttachment(this.props.story.pathStr, recordId);
  }

  // -----------------------------------------------------
  prepareRecords(records) {
    return this.props.story.fHierarchical
      ? _.sortBy(records, 't')
      : this.flatten(records);
  }

  flatten(records, level = 0) {
    let out = [];
    for (let i = 0; i < records.length; i++) {
      const record = records[i];
      if (record.fStoryObject) {
        out = out.concat(this.flatten(record.records, level + 1));
      } else {
        out.push(record);
      }
    }
    if (level === 0) out = _.sortBy(out, 't');
    return out;
  }
}

// -----------------------------------------------------
const styleStory = {
  outer: (level, story, colors) => ({
    backgroundColor: story.fServer ? colors.colorServerBg : colors.colorClientBg,
    color: story.fServer ? colors.colorServerFg : colors.colorClientFg,
    marginBottom: level <= 1 ? 10 : undefined,
    padding: level <= 1 ? 2 : undefined,
  }),
};

// -----------------------------------------------------
const connect = ReactRedux.connect(mapStateToProps, mapDispatchToProps);
const ConnectedStory = connect(Story);

// ======================================================
// MainStoryTitle
// ======================================================
class MainStoryTitle extends React.PureComponent {
  static propTypes = {
    title: React.PropTypes.string.isRequired,
    numRecords: React.PropTypes.number.isRequired,
    fHierarchical: React.PropTypes.bool.isRequired,
    fExpanded: React.PropTypes.bool.isRequired,
    onToggleExpanded: React.PropTypes.func.isRequired,
    onToggleHierarchical: React.PropTypes.func.isRequired,
  };

  constructor(props) {
    super(props);
    this.state = {
      fHovered: false,
    };
  }

  // -----------------------------------------------------
  render() {
    return (
      <div
        className="rootStoryTitle"
        style={styleMainTitle.outer}
        onMouseEnter={this.onMouseEnter}
        onMouseLeave={this.onMouseLeave}
      >
        {this.renderCaret()}
        <span
          style={styleMainTitle.title}
          onClick={this.props.onToggleExpanded}
        >
          {this.props.title.toUpperCase()}{' '}
          <span style={styleMainTitle.numRecords}>[{this.props.numRecords}]</span>
        </span>
        {this.renderToggleHierarchical()}
      </div>
    );
  }

  renderCaret() {
    if (!this.state.fHovered) return null;
    const icon = this.props.fExpanded ? 'caret-down' : 'caret-right';
    return (
      <span onClick={this.props.onToggleExpanded} style={styleMainTitle.caret.outer}>
        <Icon icon={icon} style={styleMainTitle.caret.icon} />
      </span>
    );
  }

  renderToggleHierarchical() {
    if (!this.state.fHovered) return null;
    return (
      <HierarchicalToggle
        fHierarchical={this.props.fHierarchical}
        onToggleHierarchical={this.props.onToggleHierarchical}
        fFloat
      />
    );
  }

  // -----------------------------------------------------
  onMouseEnter = () => { this.setState({ fHovered: true }); }
  onMouseLeave = () => { this.setState({ fHovered: false }); }
}

// -----------------------------------------------------
const styleMainTitle = {
  outer: {
    textAlign: 'center',
    marginBottom: 5,
    cursor: 'pointer',
  },
  title: {
    fontWeight: 900,
    letterSpacing: 3,
  },
  numRecords: { color: 'darkgrey' },
  caret: {
    outer: {
      display: 'inline-block',
      position: 'absolute',
    },
    icon: {
      display: 'inline-block',
      position: 'absolute',
      right: 6,
      top: 2,
    },
  },
};

// ======================================================
// AttachmentLine
// ======================================================
class AttachmentLine extends React.PureComponent {
  static propTypes = {
    record: React.PropTypes.object.isRequired,
    level: React.PropTypes.number.isRequired,
    timeType: React.PropTypes.string.isRequired,
    timeRef: React.PropTypes.number,
    setTimeType: React.PropTypes.func.isRequired,
    setTimeRef: React.PropTypes.func.isRequired,
    seqFullRefresh: React.PropTypes.number.isRequired,
    msg: React.PropTypes.string.isRequired,
    quickFind: React.PropTypes.string.isRequired,
    colors: React.PropTypes.object.isRequired,
  };

  // -----------------------------------------------------
  render() {
    const { record, colors } = this.props;
    const style = styleLine.log(record, colors);
    const msg = doQuickFind(this.props.msg, this.props.quickFind);
    return (
      <div className="attachmentLine allowUserSelect" style={style}>
        <Time
          fShowFull={false}
          timeType={this.props.timeType}
          timeRef={this.props.timeRef}
          setTimeType={this.props.setTimeType}
          setTimeRef={this.props.setTimeRef}
          seqFullRefresh={this.props.seqFullRefresh}
        />
        <Src src={record.src} />
        <Severity level={record.objLevel} />
        <Indent level={this.props.level} />
        <CaretOrSpace />
        <ColoredText text={`  ${msg}`} />
      </div>
    );
  }
}

// ======================================================
// RepetitionLine
// ======================================================
class RepetitionLine extends React.PureComponent {
  static propTypes = {
    record: React.PropTypes.object.isRequired,
    level: React.PropTypes.number.isRequired,
    timeType: React.PropTypes.string.isRequired,
    timeRef: React.PropTypes.number,
    setTimeType: React.PropTypes.func.isRequired,
    setTimeRef: React.PropTypes.func.isRequired,
    seqFullRefresh: React.PropTypes.number.isRequired,
    quickFind: React.PropTypes.string.isRequired,
    colors: React.PropTypes.object.isRequired,
  };

  // -----------------------------------------------------
  render() {
    const {
      record, level,
      timeType, timeRef,
      setTimeType, setTimeRef,
      seqFullRefresh,
      colors,
    } = this.props;
    const style = styleLine.log(record, colors);
    let msg = ` x${record.repetitions + 1}, latest: `;
    msg = doQuickFind(msg, this.props.quickFind);
    return (
      <div className="attachmentLine allowUserSelect" style={style}>
        <Time
          fShowFull={false}
          timeType={timeType}
          timeRef={timeRef}
          setTimeType={setTimeType}
          setTimeRef={setTimeRef}
          seqFullRefresh={seqFullRefresh}
        />
        <Src />
        <Severity />
        <Indent level={level} />
        <CaretOrSpace />
        <Icon icon="copy" disabled style={{ color: 'currentColor' }} />
        <ColoredText text={msg} />
        <Time
          t={record.tLastRepetition}
          fTrim
          timeType={timeType}
          timeRef={timeRef}
          setTimeType={setTimeType}
          setTimeRef={setTimeRef}
          seqFullRefresh={seqFullRefresh}
        />
      </div>
    );
  }
}

// ======================================================
// Line
// ======================================================
class Line extends React.PureComponent {
  static propTypes = {
    record: React.PropTypes.object.isRequired,
    level: React.PropTypes.number.isRequired,
    fDirectChild: React.PropTypes.bool.isRequired,
    timeType: React.PropTypes.string.isRequired,
    timeRef: React.PropTypes.number,
    setTimeType: React.PropTypes.func.isRequired,
    setTimeRef: React.PropTypes.func.isRequired,
    quickFind: React.PropTypes.string.isRequired,
    onToggleExpanded: React.PropTypes.func,
    onToggleHierarchical: React.PropTypes.func,
    onToggleAttachment: React.PropTypes.func,
    seqFullRefresh: React.PropTypes.number.isRequired,
    colors: React.PropTypes.object.isRequired,
  };

  constructor(props) {
    super(props);
    this.state = {
      fHovered: false,
    };
  }

  // -----------------------------------------------------
  render() {
    const { record, fDirectChild, level, colors } = this.props;
    const { fStory, fStoryObject, fServer, fOpen, title, action } = record;
    let { msg } = record;
    if (fStoryObject) msg = title;
    if (fStory) {
      msg = !fDirectChild ? `${title} ` : '';
      if (action) msg += chalk.gray(`[${action}]`);
    }
    const style = fStoryObject
      ? styleLine.titleRow
      : styleLine.log(record, colors);
    const indentLevel = fStoryObject ? level - 1 : level;
    // No animation on dark backgrounds to prevent antialiasing defects
    let className = fStoryObject ? 'storyTitle' : 'log';
    className += ' allowUserSelect';
    const fDarkBg = fServer ? colors.colorServerBgIsDark : colors.colorClientBgIsDark;
    if (!fDarkBg) className += ' fadeIn';
    return (
      <div
        className={className}
        onMouseEnter={this.onMouseEnter}
        onMouseLeave={this.onMouseLeave}
        style={style}
      >
        {this.renderTime(record)}
        <Src src={record.src} colors={colors} />
        <Severity level={record.level} colors={colors} />
        <Indent level={indentLevel} />
        {this.renderCaretOrSpace(record)}
        {this.renderMsg(fStoryObject, msg, record.level)}
        {this.renderWarningIcon(record)}
        {fStoryObject && this.renderToggleHierarchical(record)}
        {fStoryObject && fOpen && <Spinner style={styleLine.spinner} />}
        {this.renderAttachmentIcon(record)}
      </div>
    );
  }

  renderMsg(fStoryObject, msg0, level) {
    let msg = doQuickFind(msg0, this.props.quickFind);
    if (level >= constants.LEVEL_STR_TO_NUM.ERROR) {
      msg = chalk.red.bold(msg);
    } else if (level >= constants.LEVEL_STR_TO_NUM.WARN) {
      msg = chalk.red.yellow(msg);
    }
    if (!fStoryObject) return <ColoredText text={msg} />;
    return (
      <ColoredText
        text={msg}
        onClick={this.props.onToggleExpanded}
        style={styleLine.title}
      />
    );
  }

  renderTime(record) {
    const { fStoryObject, t } = record;
    const { level, timeType, timeRef, setTimeType, setTimeRef, seqFullRefresh } = this.props;
    const fShowFull = (fStoryObject && level <= 2) || (level <= 1);
    return (
      <Time
        t={t}
        fShowFull={fShowFull}
        timeType={timeType}
        timeRef={timeRef}
        setTimeType={setTimeType}
        setTimeRef={setTimeRef}
        seqFullRefresh={seqFullRefresh}
      />
    );
  }

  renderCaretOrSpace(record) {
    let fExpanded;
    if (this.props.onToggleExpanded && record.fStoryObject) {
      fExpanded = record.fExpanded;
    }
    return (
      <CaretOrSpace
        fExpanded={fExpanded}
        onToggleExpanded={this.props.onToggleExpanded}
      />
    );
  }

  renderToggleHierarchical(story) {
    if (!this.props.onToggleHierarchical) return null;
    if (!this.state.fHovered) return null;
    return (
      <HierarchicalToggle
        fHierarchical={story.fHierarchical}
        onToggleHierarchical={this.props.onToggleHierarchical}
      />
    );
  }

  renderWarningIcon(record) {
    if (record.fExpanded) return null;
    const { fHasWarning, fHasError } = record;
    if (!(fHasWarning || fHasError)) return null;
    const title = `Story contains ${fHasError ? 'an error' : 'a warning'}`;
    return (
      <Icon
        icon="warning"
        title={title}
        onClick={this.props.onToggleExpanded}
        style={styleLine.warningIcon(fHasError ? 'error' : 'warning')}
      />
    );
  }

  renderAttachmentIcon(record) {
    if (record.obj == null) return null;
    let icon;
    let style;
    if (record.objIsError) {
      icon = record.objExpanded ? 'folder-open' : 'folder';
      style = timmSet(styleLine.attachmentIcon, 'color', '#cc0000');
    } else {
      icon = record.objExpanded ? 'folder-open-o' : 'folder-o';
      style = styleLine.attachmentIcon;
    }
    return (
      <Icon
        icon={icon}
        onClick={this.onClickAttachment}
        style={style}
      />
    );
  }

  // -----------------------------------------------------
  onMouseEnter = () => { this.setState({ fHovered: true }); }
  onMouseLeave = () => { this.setState({ fHovered: false }); }
  onClickAttachment = () => { this.props.onToggleAttachment(this.props.record.id); }
}

// -----------------------------------------------------
const styleLine = {
  titleRow: {
    fontWeight: 900,
    fontFamily: 'Menlo, Consolas, monospace',
    whiteSpace: 'pre',
    overflowX: 'hidden',
    textOverflow: 'ellipsis',
  },
  title: { cursor: 'pointer' },
  log: (record, colors) => {
    const fServer = record.fServer;
    return {
      backgroundColor: fServer ? colors.colorServerBg : colors.colorClientBg,
      color: fServer ? colors.colorServerFg : colors.colorClientFg,
      fontFamily: 'Menlo, Consolas, monospace',
      whiteSpace: 'pre',
      fontWeight: record.fStory && record.action === 'CREATED' ? 900 : undefined,
      overflowX: 'hidden',
      textOverflow: 'ellipsis',
    };
  },
  spinner: {
    marginLeft: 8,
    overflow: 'hidden',
  },
  attachmentIcon: {
    marginLeft: 8,
    cursor: 'pointer',
    display: 'inline',
  },
  warningIcon: (type) => ({
    marginLeft: 8,
    color: type === 'warning' ? '#ff6600' : '#cc0000',
    display: 'inline',
  }),
};

// ======================================================
// Time
// ======================================================
const TIME_LENGTH = 25;

class Time extends React.PureComponent {
  static propTypes = {
    t: React.PropTypes.number,
    fShowFull: React.PropTypes.bool,
    timeType: React.PropTypes.string.isRequired,
    timeRef: React.PropTypes.number,
    setTimeType: React.PropTypes.func.isRequired,
    setTimeRef: React.PropTypes.func.isRequired,
    seqFullRefresh: React.PropTypes.number.isRequired, // eslint-disable-line react/no-unused-prop-types, max-len
    fTrim: React.PropTypes.bool,
  };

  render() {
    const { t, fShowFull, timeType, timeRef, fTrim } = this.props;
    if (t == null) return <span>{_.padEnd('', TIME_LENGTH)}</span>;
    let fTimeInWords = false;
    let fRefTimestamp = false;
    const localTime = dateFormat(t, 'YYYY-MM-DD HH:mm:ss.SSS');
    let shownTime;

    // No time reference
    if (timeRef == null) {
      if (timeType === 'RELATIVE') {
        shownTime = dateDistanceInWords(new Date(), t, { addSuffix: true });
        fTimeInWords = true;
      } else {
        shownTime = timeType === 'UTC'
          ? new Date(t).toISOString().replace(/T/g, ' ')
          : localTime;
        shownTime = fShowFull ? shownTime : `           ${shownTime.slice(11)}`;
      }

    // There's a time ref, and it matches this timestamp
    } else if (t === timeRef) {
      shownTime = timeType === 'UTC'
        ? new Date(t).toISOString().replace(/T/g, ' ')
        : localTime;
      fRefTimestamp = true;

    // There's a time ref, but it's not this timestamp
    } else if (timeType === 'RELATIVE') {
      shownTime = dateDistanceInWords(timeRef, t, { partialMethod: 'round' });
      shownTime += timeRef > t ? ' before' : ' later';
      fTimeInWords = true;
    } else {
      const delta = Math.abs(t - timeRef);
      shownTime = new Date(delta).toISOString().replace(/T/g, ' ').slice(0, 23);
      if (shownTime.slice(0, 4) === '1970') shownTime = shownTime.slice(5);
      if (shownTime.slice(0, 2) === '01') shownTime = shownTime.slice(3);
      if (shownTime.slice(0, 2) === '01') shownTime = shownTime.slice(3);
      if (shownTime.slice(0, 2) === '00') shownTime = shownTime.slice(3);
      shownTime = `${timeRef > t ? '-' : '+'}${shownTime}`;
      shownTime = _.padStart(shownTime, 23);
    }

    // Finishing touches
    shownTime = _.padEnd(shownTime, TIME_LENGTH);
    if (shownTime.length > TIME_LENGTH) {
      shownTime = `${shownTime.slice(0, TIME_LENGTH - 1)}…`;
    }
    if (fTrim) shownTime = shownTime.trim();
    return (
      <span
        onClick={this.onClick}
        onContextMenu={this.onClick}
        style={styleTime(fTimeInWords, fRefTimestamp)}
        title={shownTime.trim() !== localTime ? localTime : undefined}
      >
        {shownTime}
      </span>
    );
  }

  // -----------------------------------------------------
  onClick = (ev) => {
    const fSetTimeRef = ev.type === 'contextmenu' || ev.ctrlKey;
    if (fSetTimeRef) cancelEvent(ev);
    const { t, timeType: prevTimeType, timeRef: prevTimeRef } = this.props;
    if (fSetTimeRef) {
      const nextTimeRef = t !== prevTimeRef ? t : null;
      this.props.setTimeRef(nextTimeRef);
    } else {
      let nextTimeType;
      if (prevTimeType === 'LOCAL') nextTimeType = 'RELATIVE';
      else if (prevTimeType === 'RELATIVE') nextTimeType = 'UTC';
      else nextTimeType = 'LOCAL';
      this.props.setTimeType(nextTimeType);
    }
  }
}

const styleTime = (fTimeInWords, fRefTimestamp) => ({
  display: 'inline',
  cursor: 'pointer',
  fontStyle: fTimeInWords ? 'italic' : undefined,
  fontWeight: fRefTimestamp ? 'bold' : undefined,
  backgroundColor: fRefTimestamp ? '#d1bd0c' : undefined,
});

// ======================================================
// Severity
// ======================================================
class Severity extends React.PureComponent {
  static propTypes = {
    level: React.PropTypes.number,
  };

  render() {
    const { level } = this.props;
    return level != null
      ? <ColoredText text={ansiColors.LEVEL_NUM_TO_COLORED_STR[level]} />
      : <span>      </span>;  // eslint-disable-line react/self-closing-comp
  }
}

// ======================================================
// Src
// ======================================================
class Src extends React.PureComponent {
  static propTypes = {
    src: React.PropTypes.string,
  };

  render() {
    const { src } = this.props;
    if (src != null) {
      const srcStr = ansiColors.getSrcChalkColor(src)(_.padStart(`${src} `, 20));
      return <ColoredText text={srcStr} />;
    }
    return <span>{_.repeat(' ', 20)}</span>;
  }
}

// ======================================================
// Indent
// ======================================================
const Indent = ({ level }) => {
  const style = {
    display: 'inline-block',
    width: 20 * (level - 1),
  };
  return <div style={style} />;
};

// ======================================================
// CaretOrSpace
// ======================================================
class CaretOrSpace extends React.PureComponent {
  static propTypes = {
    fExpanded: React.PropTypes.bool,
    onToggleExpanded: React.PropTypes.func,
  };

  render() {
    let icon;
    if (this.props.fExpanded != null) {
      const iconType = this.props.fExpanded ? 'caret-down' : 'caret-right';
      icon = <Icon icon={iconType} onClick={this.props.onToggleExpanded} />;
    }
    return <span style={styleCaretOrSpace}>{icon}</span>;
  }
}

const styleCaretOrSpace = {
  display: 'inline-block',
  width: 30,
  paddingLeft: 10,
  cursor: 'pointer',
};

// ======================================================
// HierarchicalToggle
// ======================================================
class HierarchicalToggle extends React.PureComponent {
  static propTypes = {
    fHierarchical: React.PropTypes.bool.isRequired,
    onToggleHierarchical: React.PropTypes.func.isRequired,
    fFloat: React.PropTypes.bool,
  };

  render() {
    const icon = this.props.fHierarchical ? 'bars' : 'sitemap';
    const text = this.props.fHierarchical ? 'Show flat' : 'Show tree';
    return (
      <span
        onClick={this.props.onToggleHierarchical}
        style={styleHierarchical.outer(this.props.fFloat)}
      >
        <Icon icon={icon} style={styleHierarchical.icon} />
        {text}
      </span>
    );
  }
}

const styleHierarchical = {
  outer: (fFloat) => ({
    position: fFloat ? 'absolute' : undefined,
    marginLeft: 10,
    color: 'darkgrey',
    textDecoration: 'underline',
    cursor: 'pointer',
    fontWeight: 'normal',
    fontFamily: 'Menlo, Consolas, monospace',
  }),
  icon: { marginRight: 4 },
};

// ======================================================
export default ConnectedStory;
export { Story as _Story };
