React = require 'react'
{createDevTools} = require 'redux-devtools'
LogMonitor = require('redux-devtools-log-monitor').default
DockMonitor = require('redux-devtools-dock-monitor').default

module.exports = createDevTools(
  <DockMonitor 
    toggleVisibilityKey="ctrl-h"
    changePositionKey="ctrl-shift-h"
    changeMonitorKey="ctrl-m"
    defaultIsVisible={true}
    defaultPosition="right"
  >
    <LogMonitor 
      theme="chalk"
      expandStateRoot={true}
    />
  </DockMonitor>
)
