$ ->
  MongodbLoggerJS.init()

MongodbLoggerJS = 
  tail_logs_url: null
  tail_log_started: false
  log_info_offset: null
  log_info_padding: 15
  
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
    # filter tougle
    $('div.filter-toggle').live 'click', (event) =>
      $('div.filter').slideToggle()
    
    # message tabs
    $('li.message_tab').live 'click', (event) =>
      elm_obj = $(event.target)
      tab = elm_obj.attr('data-tab')
      if tab?
        $('li.message_tab').removeClass('active')
        $('pre.tab_content').addClass('hidden')
        elm_obj.addClass('active')
        $('.' + tab).removeClass('hidden')
           
    # init pjax
    this.init_pjax()
    this.init_on_pages()
    
  init_pjax: ->
    $('a[data-pjax]').pjax()
    $('body').bind 'pjax:start', () => 
      $('#ajax_loader').show()
    $('body').bind 'pjax:end', () => 
      $('#ajax_loader').hide()
      # stop tailing
      MongodbLoggerJS.tail_log_started = false
      # scroll on top
      if ($(window).scrollTop() > 100)
        $('html, body').stop().animate({ scrollTop: 0 }, 'slow')
      # init pages
      MongodbLoggerJS.init_on_pages()
  
  init_on_pages: ->
    # code highlight
    $('pre code').each (i, e) ->
      hljs.highlightBlock(e, '  ')
    
    # log info window
    if $("#log_info").length > 0
      MongodbLoggerJS.log_info_offset = $("#log_info").offset()
      $(window).scroll =>
        if $(window).scrollTop() > MongodbLoggerJS.log_info_offset.top
          $("#log_info").stop().animate
            marginTop: $(window).scrollTop() - MongodbLoggerJS.log_info_offset.top + MongodbLoggerJS.log_info_padding
        else
          $("#log_info").stop().animate
            marginTop: 0
  
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
          if data.time
            $('#tail_logs_time').text(data.time)
            if count != data.count
              count = data.count
              if $("#db_collection_count").length > 0
                $("#db_collection_count").text(count)
              if data.content? && data.content.length > 0
                elements = $(data.content)
                elements.addClass('newlog')
                $('#logs_list tr:first').after(elements).effect("highlight", {}, 1000)
          if MongodbLoggerJS.tail_log_started
            fcallback = -> MongodbLoggerJS.tail_logs(count)
            setTimeout fcallback, 2000
