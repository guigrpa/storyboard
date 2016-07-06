import { mainStory, addPlugin } from '../storyboard';
import browserExtension from '../listeners/browserExtension';
import wsClient from '../listeners/wsClient';

addPlugin(browserExtension);
addPlugin(wsClient);
