class Dashing.SensuTable extends Dashing.Widget

  ready: ->
    # This is fired when the widget is done being rendered
    console.log 'hello'
   onData: (data) ->
    # Handle incoming data
    # You can access the html node of this widget with `@node`
    # Example: $(@node).fadeOut().fadeIn() will make the node flash each time data comes in.
    console.log 'reading data'
   # $(@node).fadeOut().fadeIn() 
   # window.open('www.google.com', '_blank')
   #$(@node).sorttablexx.reinit()
   # console.log $(@node)
   # console.log 'done...................................................................'
