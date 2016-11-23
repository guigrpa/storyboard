import { addDefaults } from 'timm';

export const BASE_COLORS = {
  colorClientBg: 'aliceblue',
  colorClientBgIsDark: false,
  colorClientFg: 'black',
  colorServerBg: 'rgb(214, 236, 255)',
  colorServerBgIsDark: false,
  colorServerFg: 'black',
  colorUiBg: 'white',
  colorUiBgIsDark: false,
  colorUiFg: 'rgb(64, 64, 64)',
};

export const DARK_COLORS = {
  colorClientBg: 'rgb(17, 22, 54)',
  colorClientBgIsDark: true,
  colorClientFg: 'white',
  colorServerBg: 'rgb(14, 11, 33)',
  colorServerBgIsDark: true,
  colorServerFg: 'white',
  colorUiBg: 'black',
  colorUiBgIsDark: true,
  colorUiFg: 'white',
};

export const EMPTY_MAIN_STORY = {
  fExpanded: true,
  fHierarchical: true,
  fOpen: true,
  fWrapper: true,
  records: [
    {
      fExpanded: true,
      fHierarchical: true,
      fMain: true,
      fOpen: true,
      fServer: false,
      fStoryObject: true,
      id: 'main_0',
      lastAction: 'CREATED',
      numRecords: 0,
      pathStr: 'records/0',
      records: [],
      src: 'main',
      status: undefined,
      storyId: 'main_0',
      t: 0,
      title: 'Client',
    },
    {
      fExpanded: true,
      fHierarchical: true,
      fMain: true,
      fOpen: true,
      fServer: true,
      fStoryObject: true,
      id: 'main_1',
      lastAction: 'CREATED',
      numRecords: 0,
      pathStr: 'records/1',
      records: [],
      src: 'main',
      status: undefined,
      storyId: 'main_1',
      t: 0,
      title: 'Server',
    },
  ],
};

export const buildLogRecord = (options = {}) => addDefaults(options, {
  id: 'id1',
  hubId: 'hubId1',
  version: 3,
  fStory: false,
  fServer: false,
  storyId: 'story1',
  t: 0,
  src: 'main',
  level: 30,
  msg: 'Example message',
});

export const buildStory = (options = {}) => {
  const story = addDefaults(options, {
    id: 'id1',
    hubId: 'hubId1',
    version: 3,
    fStory: true,
    fServer: false,
    storyId: 'story1',
    t: 0,
    src: 'main',
    level: 30,
    fRoot: false,
    title: 'Story title',
    parents: [],
    // client-side
    fStoryObject: true,
    fOpen: false,
    fMain: false,
    status: undefined,
    fExpanded: true,
    fHierarchical: true,
    records: [],
  });
  story.records.unshift({
    id: `${story.id}.creation`,
    hubId: story.hubId,
    version: story.version,
    fStory: true,
    fServer: story.fServer,
    storyId: story.storyId,
    t: story.t,
    src: story.src,
    level: story.level,
    fRoot: story.fRoot,
    title: story.title,
    action: 'CREATED',
  });
  if (!story.fOpen) {
    story.records.push({
      id: `${story.id}.closure`,
      hubId: story.hubId,
      version: story.version,
      fStory: true,
      fServer: story.fServer,
      storyId: story.storyId,
      t: story.records[story.records.length - 1].t,
      src: story.src,
      level: story.level,
      fRoot: story.fRoot,
      title: story.title,
      action: 'CLOSED',
    });
  }
  story.numRecords = story.records.length;
  return story;
};
