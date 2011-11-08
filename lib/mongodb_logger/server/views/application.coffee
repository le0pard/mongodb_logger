jQuery ->
  MongodbLoggerJS.init()

MongodbLoggerJS = 
  init: ->
    $(document).ajaxStart: ->
      $('#ajax_loader').show()
    $(document).ajaxStop: ->
      $('#ajax_loader').hide()
      
  