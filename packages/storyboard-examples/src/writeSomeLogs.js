import { mainStory, chalk } from 'storyboard';

const writeSomeLogs = () => {
  // Some example logs (including a circular reference)
  const longArray = [];
  for (let i = 0; i < 750; i++) {
    longArray.push(i);
  }
  const someInfo = {
    appName: 'Storyboard example',
    upSince: new Date(),
    dontShow: 'hidden',
    loginRequiredForLogs: true,
    nested: {
      configOptions: {
        foo: undefined,
        bar: null,
        values: [1, 2],
      },
    },
    shortBuffer: Buffer.from([0, 1, 2, 3]),
    longBuffer: Buffer.from(longArray),
  };
  someInfo.nested.configOptions.mainInfo = someInfo;
  mainStory.debug('server', 'Example info:', {
    attach: someInfo,
    attachLevel: 'TRACE',
    ignoreKeys: ['dontShow'],
  });
  mainStory.debug('server', 'A message with an undefined attachment', { attach: undefined });
  mainStory.warn('server', 'Example warning');
  mainStory.error('server', 'Example error', { attach: new Error('EXAMPLE error message') });
  setInterval(() => {
    mainStory.debug('server', `t: ${chalk.blue(new Date().toISOString())}`);
  }, 60000);

  const story = mainStory.child({ title: 'Example child story' });
  story.info('Info');
  story.warn('Warn');
  story.error('Error!');
  story.close();
};

export default writeSomeLogs;
