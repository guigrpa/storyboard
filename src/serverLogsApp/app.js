import { addListener } from '../storyboard';
import browserExtension from '../listeners/browserExtension';
import wsClient from '../listeners/wsClient';

addListener(browserExtension);
addListener(wsClient);
