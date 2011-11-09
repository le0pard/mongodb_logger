$ ->
  MongodbLoggerJS.init()

MongodbLoggerJS = 
  init: ->
    $('#tail_logs_link').bind 'click', (event) =>
      obj_element = $(event.target)
      MongodbLoggerJS.push_logs(obj_element.attr('rel'))
      return false
  push_logs: (count) ->
    $.ajax
      url: "/mongodb/push_logs/" + count
      dataType: "json"
      success: (data) ->
        if count != data.count && data.content?
          $("#logs_list").prepend(data.content)
          count = data.count
        callback = -> MongodbLoggerJS.push_logs(count)
        setTimeout callback, 2000
