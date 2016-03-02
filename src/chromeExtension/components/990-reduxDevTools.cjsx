React = require 'react'
{createDevTools} = require 'redux-devtools'
DiffMonitor = require('redux-devtools-diff-monitor').default
LogMonitor = require('redux-devtools-log-monitor').default
SliderMonitor = require 'redux-slider-monitor'
DockMonitor = require('redux-devtools-dock-monitor').default

module.exports = createDevTools(
  <DockMonitor 
    toggleVisibilityKey="ctrl-h"
    changePositionKey="ctrl-shift-h"
    changeMonitorKey="ctrl-m"
    defaultIsVisible={true}
    defaultPosition="right"
  >
    <DiffMonitor theme="tomorrow"/>
    <LogMonitor 
      theme="chalk"
      expandStateRoot={true}
    />
  </DockMonitor>
)
