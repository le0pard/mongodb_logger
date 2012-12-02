root = global ? window

root.MongodbLoggerMain = 
  tailLogsUrl: null
  tailLogStarted: false
  logInfoOffset: null
  logInfoPadding: 15
  isChartsReady: false
  
  init: ->
    # spinner
    $(document).ajaxStart => $('#ajaxLoader').show()
    $(document).ajaxStop => $('#ajaxLoader').hide()
    # tail logs buttons
    $(document).on 'click', '#tailLogsLink', (event) =>
      MongodbLoggerMain.tailLogsUrl = $(event.currentTarget).attr('data-url')
      $('#tailLogsBlock').addClass('started')
      MongodbLoggerMain.tailLogs(null)
      return false
    $(document).on 'click', '#tailLogsStopLink', (event) =>
      MongodbLoggerMain.tailLogStarted = false
      $('#tailLogsBlock').removeClass('started')
      return false
    # log info click
    $(document).on 'click', '.log_info', (event) =>
      element = $(event.currentTarget)
      element.parents('table').find('tr').removeClass('current')
      element.addClass('current')
      $('#logInfo').load(element.data('url'))
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
    # select filter types (integer, string, date)
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
    # delete one filter
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
      $.ajax 
        url: url
        dataType: 'json' 
        data: data
        type: "POST"
        success: (data, textStatus, jqXHR) =>
          MongodbLoggerMain.build_analytic_charts(data)
      return false
    # keydown by logs  
    $(document).on 'keydown', '*', (event) =>
      console.log event.keyCode
      switch event.keyCode
        when 37 # left
          MongodbLoggerMain.move_by_logs('begin')
        when 38 # up
          MongodbLoggerMain.move_by_logs('up')
        when 39 # right
          MongodbLoggerMain.move_by_logs('end')
        when 40 # down
          MongodbLoggerMain.move_by_logs('down')
          
    # init pjax
    this.initPjax()
    this.initOnPages()
    
  initPjax: ->
    # pjax
    $('a[data-pjax]').pjax()
    $('body').bind 'pjax:start', () => $('#ajaxLoader').show()
    $('body').bind 'pjax:end', () => 
      $('#ajaxLoader').hide()
      # stop tailing
      MongodbLoggerMain.tailLogStarted = false
      # scroll on top
      $('html, body').stop().animate({ scrollTop: 0 }, 'slow') if ($(window).scrollTop() > 100)
      # init pages
      MongodbLoggerMain.initOnPages()
  # init this on pjax
  initOnPages: ->
    # code highlight
    $('pre code').each (i, e) -> hljs.highlightBlock(e, '  ')
    # callendars  
    $( ".datepicker, .filter_values input.date" ).datepicker
      dateFormat: "yy-mm-dd"
      changeMonth: true
      changeYear: true
      yearRange: 'c-50:c+10'
    # log info window
    if $("#logInfo").length > 0
      MongodbLoggerMain.logInfoOffset = $("#logInfo").offset()
      $(window).scroll =>
        if $(window).scrollTop() > MongodbLoggerMain.logInfoOffset.top
          $("#logInfo").stop().animate
            marginTop: $(window).scrollTop() - MongodbLoggerMain.logInfoOffset.top + MongodbLoggerMain.logInfoPadding
        else
          $("#logInfo").stop().animate
            marginTop: 0
  # tail logs function
  tailLogs: (logLastId = null) ->
    url = MongodbLoggerMain.tailLogsUrl
    if logLastId? && logLastId.length > 0
      url = "#{MongodbLoggerMain.tailLogsUrl}/#{logLastId}" 
    else
      MongodbLoggerMain.tailLogStarted = true
      logLastId = ""
    if MongodbLoggerMain.tailLogStarted
      $.ajax
        url: url
        dataType: "json"
        success: (data) ->
          if data.time
            $('#tailLogsTime').text(data.time)
            if data.log_last_id?
              logLastId = data.log_last_id
            if data.content? && data.content.length > 0
              elements = $(data.content)
              elements.addClass('newlog')
              $('#logs_list tr:first').after(elements).effect("highlight", {}, 1000)
            if data.collection_stats && $("#collection_stats").length > 0
              $("#collection_stats").html(data.collection_stats)
          setTimeout((-> MongodbLoggerMain.tailLogs(logLastId)), 2000) if MongodbLoggerMain.tailLogStarted
  # move using keys by logs
  move_by_logs: (direction) ->
    if $('#logs_list').length > 0 && $('#logs_list').find('tr.current').length > 0
      current_element = $('#logs_list').find('tr.current')
      switch direction
        when 'begin'
          element = $('#logs_list tr:first').next("tr")
          if element.length > 0
            element.find('td:first').trigger('click')
            $(window).scrollTop(element.height() + element.offset().top - 100)
            return false
        when 'end'
          element = $('#logs_list tr:last')
          if element.length > 0
            element.find('td:first').trigger('click')
            $(window).scrollTop(element.height() + element.offset().top - 100)
            return false
        when 'down'
          element = current_element.next("tr")
          if element.length > 0
            element.find('td:first').trigger('click')
            if MongodbLoggerMain.is_scrolled_into_view(element)
              $(window).scrollTop($(window).scrollTop() + element.height())
            else
              $(window).scrollTop(element.height() + element.offset().top - 100)
            return false
        when 'up'
          element = current_element.prev("tr")
          if element.length > 0
            element.find('td:first').trigger('click')
            if MongodbLoggerMain.is_scrolled_into_view(element)
              $(window).scrollTop($(window).scrollTop() - element.height())
            else
              $(window).scrollTop(element.height() + element.offset().top - 100)
            return false
  # check in selected element is visible for user          
  is_scrolled_into_view: (elem) ->
    docViewTop = $(window).scrollTop()
    docViewBottom = docViewTop + $(window).height()
    elemTop = $(elem).offset().top
    elemBottom = elemTop + $(elem).height()
    return ((docViewTop < elemTop) && (docViewBottom > elemBottom))

$ ->
  MongodbLoggerMain.init()