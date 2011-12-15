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
    
    $(document).on 'click', '#tail_logs_link', (event) =>
      MongodbLoggerJS.tail_logs_url = $(event.target).attr('data-url')
      $('#tail_logs_block').addClass('started')
      MongodbLoggerJS.tail_logs(null)
      return false
    $(document).on 'click', '#tail_logs_stop_link', (event) =>
      MongodbLoggerJS.tail_log_started = false
      $('#tail_logs_block').removeClass('started')
      return false
    
    $(document).on 'click', '.log_info', (event) =>
      elm_obj = $(event.target)
      url = elm_obj.attr('data-url')
      url = elm_obj.parents('tr').attr('data-url') if !url?
      if url?
        elm_obj.parents('table').find('tr').removeClass('current')
        elm_obj.parents('tr').addClass('current')
        $('#log_info').load(url)
      return false
    # filter tougle
    $(document).on 'click', 'div.filter-toggle', (event) =>
      $('div.filter').slideToggle()
      $('div.filter-toggle span.arrow-down').toggleClass('rotate')
      
    # additional filters
    $(document).on 'click', '#add_more_filter', (event) =>
      url = $(event.target).attr('href')
      $.ajax
        url: url
        success: (data) ->
          content = $('<li></li>').html(data)
          $('#more_filter_list').append(content)
      return false
    
    $(document).on 'change', 'select.filter_type', (event) =>
      elm_object = $(event.target)
      url = elm_object.attr('rel') + "/" + elm_object.val()
      $.ajax
        url: url
        dataType: "json"
        success: (data) ->
          cond_options = ""
          value_input = ""
          $.each data.conditions, (key, val) =>
            cond_options += '<option value="' + val + '">' + val + '</option>'
          elm_object.parents('div.filter_block').find('select.filter_conditions').empty().append(cond_options) 
          if data.values.length > 0
            value_input = '<select id="filter[more][]_value" name="filter[more][][value]">'
            $.each data.values, (key, val) =>
              value_input += '<option value="' + val + '">' + val + '</option>'
            value_input += '</select>'
          else
            value_input = '<input type="text" name="filter[more][][value]" value="" placeholder="value">'
          elm_object.parents('div.filter_block').find('div.filter_values').html(value_input)
          if "date" == elm_object.val()
            elm_object.parents('div.filter_block').find('div.filter_values input').datepicker
              dateFormat: "yy-mm-dd"
              changeMonth: true
              changeYear: true
              yearRange: 'c-50:c+10'
      return false
    
    $(document).on 'click', '.close_more_filter', (event) =>
      $(event.target).parents('li').remove()
      return false
      
    # message tabs
    $(document).on 'click', 'li.message_tab', (event) =>
      elm_obj = $(event.target)
      tab = elm_obj.attr('data-tab')
      if tab?
        $('li.message_tab').removeClass('active')
        $('pre.tab_content').addClass('hidden')
        elm_obj.addClass('active')
        $('.' + tab).removeClass('hidden')
    
    # analytic form
    $(document).on 'submit', '#analyticForm', (event) =>
      element = $('#analyticForm')
      url = element.attr('action')
      data = element.serializeArray()
      $('#analyticData').load url, data
      return false
      
    # keydown log  
    $(document).on 'keydown', '*', (event) =>
      switch event.keyCode
        when 40
          if $('#logs_list').find('tr.current').length > 0
            $('#logs_list').find('tr.current').next("tr").find('td:first').trigger('click')
          return false
        when 38
          if $('#logs_list').find('tr.current').length > 0
            $('#logs_list').find('tr.current').prev("tr").find('td:first').trigger('click')
          return false
          
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
      
    $( ".datepicker, .filter_values input.date" ).datepicker
      dateFormat: "yy-mm-dd"
      changeMonth: true
      changeYear: true
      yearRange: 'c-50:c+10'
    
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
  
  tail_logs: (log_last_id) ->
    url = MongodbLoggerJS.tail_logs_url
    if log_last_id? && log_last_id.length > 0
      url = MongodbLoggerJS.tail_logs_url + "/" + log_last_id 
    else
      MongodbLoggerJS.tail_log_started = true
      log_last_id = ""
    if MongodbLoggerJS.tail_log_started
      $.ajax
        url: url
        dataType: "json"
        success: (data) ->
          if data.time
            $('#tail_logs_time').text(data.time)
            if data.log_last_id?
              log_last_id = data.log_last_id
            if data.content? && data.content.length > 0
              elements = $(data.content)
              elements.addClass('newlog')
              $('#logs_list tr:first').after(elements).effect("highlight", {}, 1000)
            if data.collection_stats && $("#collection_stats").length > 0
              $("#collection_stats").html(data.collection_stats)
          if MongodbLoggerJS.tail_log_started
            fcallback = -> MongodbLoggerJS.tail_logs(log_last_id)
            setTimeout fcallback, 2000
