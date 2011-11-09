$ ->
  MongodbLoggerJS.init()

MongodbLoggerJS = 
  push_logs_url: null
  
  init: ->
    $('#tail_logs_link').bind 'click', (event) =>
      MongodbLoggerJS.push_logs_url = $(event.target).attr('href')
      MongodbLoggerJS.push_logs(null)
      return false
  push_logs: (count) ->
    url = MongodbLoggerJS.push_logs_url
    if count?
      url = MongodbLoggerJS.push_logs_url + "/" + count 
    else
      count = 0
    $.ajax
      url: url
      dataType: "json"
      success: (data) ->
        if count != data.count
          if data.content?
            $("#logs_list").prepend(data.content)
          count = data.count
        callback = -> MongodbLoggerJS.push_logs(count)
        setTimeout callback, 2000
