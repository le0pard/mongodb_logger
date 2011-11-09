$ ->
  MongodbLoggerJS.init()

MongodbLoggerJS = 
  push_logs_url: null
  
  init: ->
    if $('#tail_logs_link').length > 0
      $('#tail_logs_link').click (event) =>
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
          if data.content? && data.content.length > 0
            $("#logs_list").prepend(data.content)
          count = data.count
        fcallback = -> MongodbLoggerJS.push_logs(count)
        setTimeout fcallback, 2000
