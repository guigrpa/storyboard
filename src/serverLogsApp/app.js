import { addListener } from '../storyboard';
import browserExtension from '../listeners/browserExtension';
import wsClient from '../listeners/wsClient';

addListener(browserExtension);

// Use clock synchronization by default,
// since we are seeing only server-side stories and the user has
// no means to opt in
addListener(wsClient, { clockSync: true });
