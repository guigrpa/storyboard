chrome.devtools.panels.create 'Storyboard', null, 'devPanel.html', (panel) ->
  console.log "Added panel"
  panel.onShown.addListener ->
    console.log 'Shown devPanel!'
    node = document.getElementById 'app'
    node.innerHTML = 'hello'
  panel.onHidden.addListener ->
    console.log 'Hidden!'
