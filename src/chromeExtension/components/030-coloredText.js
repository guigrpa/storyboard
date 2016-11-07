import { merge } from 'timm';
import React from 'react';
import { getStyledSegments } from '../../gral/ansiColors';

class ColoredText extends React.PureComponent {
  static propTypes = {
    text: React.PropTypes.string.isRequired,
    onClick: React.PropTypes.func,
    style: React.PropTypes.object,
  };

  // -----------------------------------------------------
  render() {
    const segments = getStyledSegments(this.props.text);
    if (segments.length === 1) {
      const segment = segments[0];
      const extraProps = {
        onClick: this.props.onClick,
        style: merge(segment.style, this.props.style),
      };
      return this.renderMsgSegment(segment, 0, extraProps);
    }
    return (
      <span onClick={this.props.onClick} style={this.props.style}>
        {segments.map((segment, idx) => this.renderMsgSegment(segment, idx))}
      </span>
    );
  }

  renderMsgSegment(segment, idx, extraProps = {}) {
    return (
      <span key={idx} style={segment.style} {...extraProps}>
        {segment.text}
      </span>
    );
  }
}

// -----------------------------------------------------
export default ColoredText;
