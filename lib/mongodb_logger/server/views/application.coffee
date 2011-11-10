$ ->
  MongodbLoggerJS.init()

MongodbLoggerJS = 
  tail_logs_url: null
  tail_log_started: false
  
  init: ->
    $(document).ajaxStart =>
      $('#ajax_loader').show()
    $(document).ajaxStop =>
      $('#ajax_loader').hide()
    
    $('#tail_logs_link').live 'click', (event) =>
      MongodbLoggerJS.tail_logs_url = $(event.target).attr('href')
      $('#tail_logs_block').addClass('started')
      MongodbLoggerJS.tail_logs(null)
      return false
    $('#tail_logs_stop_link').live 'click', (event) =>
      MongodbLoggerJS.tail_log_started = false
      $('#tail_logs_block').removeClass('started')
      return false
    $('#add_more_filter_link').live 'click', (event) =>
      li_el = $('<li></li>').append($('#filter_block').html())
      $('#filter_fields_list').append(li_el)
    $('.delete_filter_fields').live 'click', (event) =>
      elem = $(event.target)
      elem.parents('li').remove()
      
  tail_logs: (count) ->
    url = MongodbLoggerJS.tail_logs_url
    if count?
      url = MongodbLoggerJS.tail_logs_url + "/" + count 
    else
      MongodbLoggerJS.tail_log_started = true
      count = 0
    if MongodbLoggerJS.tail_log_started
      $.ajax
        url: url
        dataType: "json"
        success: (data) ->
          if count != data.count
            if data.content? && data.content.length > 0
              $("#logs_list").prepend(data.content)
            count = data.count
          if MongodbLoggerJS.tail_log_started
            fcallback = -> MongodbLoggerJS.tail_logs(count)
            setTimeout fcallback, 2000
