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
      MongodbLoggerJS.tail_logs_url = $(event.target).attr('data-url')
      $('#tail_logs_block').addClass('started')
      MongodbLoggerJS.tail_logs(null)
      return false
    $('#tail_logs_stop_link').live 'click', (event) =>
      MongodbLoggerJS.tail_log_started = false
      $('#tail_logs_block').removeClass('started')
      return false
    
    $('.log_info').live 'click', (event) =>
      elm_obj = $(event.target)
      url = elm_obj.attr('data-url')
      url = elm_obj.parents('tr').attr('data-url') if !url?
      if url?
        elm_obj.parents('table').find('tr').removeClass('current')
        elm_obj.parents('tr').addClass('current')
        $('#log_info').load(url)
      return false
      
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
              $('#logs_list tr:first').after(data.content)
            count = data.count
          if data.time
            $('#tail_logs_time').text(data.time)
          if MongodbLoggerJS.tail_log_started
            fcallback = -> MongodbLoggerJS.tail_logs(count)
            setTimeout fcallback, 2000
