import { addListener } from 'storyboard';
import browserExtension from 'storyboard-listener-browser-extension';
import wsClient from 'storyboard-listener-ws-client';

addListener(browserExtension);

// Use clock synchronization by default,
// since we are seeing only server-side stories and the user has
// no means to opt in
addListener(wsClient, { clockSync: true });
