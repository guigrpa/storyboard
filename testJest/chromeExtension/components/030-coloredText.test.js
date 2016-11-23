/* eslint-env jest */
/* eslint-disable no-extend-native */
import React from 'react';
import renderer from 'react-test-renderer';
import chalk from 'chalk';
import ColoredText from '../../../lib/chromeExtension/components/030-coloredText';

describe('ColoredText', () => {
  it('renders correctly with unstyled text', () => {
    const tree = renderer.create(
      <ColoredText text="Hello" />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it('renders correctly with styled text', () => {
    const text = `That's ${chalk.red('red')} and that's ${chalk.cyan.bold('very important')}`;
    const tree = renderer.create(
      <ColoredText text={text} />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it('renders nested styles correctly', () => {
    const text = `That's ${chalk.red(`${chalk.bold('very')} important`)}`;
    const tree = renderer.create(
      <ColoredText text={text} />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it('respects the style prop', () => {
    const tree = renderer.create(
      <ColoredText text="Hello" style={{ border: '1px solid black' }} />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });

  it('respects the onClick prop', () => {
    const tree = renderer.create(
      <ColoredText text="Hello" onClick={() => {}} />
    ).toJSON();
    expect(tree).toMatchSnapshot();
  });
});
