console.log 'content-script'

button = document.getElementById "mybutton"
button.addEventListener "click", -> alert "Hello 2"
