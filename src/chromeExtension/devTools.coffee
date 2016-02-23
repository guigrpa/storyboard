# Create panel, attach event handlers
chrome.devtools.panels.create 'Storyboard', null, 'devPanel.html', (panel) ->
  panel.onShown.addListener  -> console.log "Storyboard panel shown"
  panel.onHidden.addListener -> console.log "Storyboard panel hidden"
