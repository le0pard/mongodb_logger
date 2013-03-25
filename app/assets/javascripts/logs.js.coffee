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
      event.preventDefault()
      MongodbLoggerMain.tailLogsUrl = $(event.currentTarget).data('url')
      $('#tailLogsBlock').addClass('started')
      MongodbLoggerMain.tailLogs(null)
    $(document).on 'click', '#tailLogsStopLink', (event) =>
      event.preventDefault()
      MongodbLoggerMain.tailLogStarted = false
      $('#tailLogsBlock').removeClass('started')
    # log info click
    $(document).on 'click', '.log_info', (event) =>
      event.preventDefault()
      element = $(event.currentTarget)
      element.parents('table').find('tr').removeClass('current')
      element.addClass('current')
      $('#logInfo').html(MustacheTemplates["logs/info"]({ log: element.data('info') }))
    # filter tougle
    $(document).on 'click', 'div.filter_toggle', (event) =>
      event.preventDefault()
      $('div.filter').slideToggle()
      $('div.filter_toggle span.arrow-down').toggleClass('rotate')
    # additional filters
    $(document).on 'click', '#addMoreFilter', (event) =>
      event.preventDefault()
      $.ajax
        url: $(event.currentTarget).attr('href')
        success: (data) -> $('#moreFilterList').append($('<li></li>').html(data))
    # select filter types (integer, string, date)
    $(document).on 'change', 'select.filter_type', (event) =>
      event.preventDefault()
      element = $(event.currentTarget)
      url = "#{element.data('url')}/#{element.val()}"
      $.ajax
        url: url
        dataType: "json"
        success: (data) ->
          condOptions = []
          $.each data.conditions, (key, val) => condOptions.push("<option value='#{val}'>#{val}</option>")
          element.parents('div.filter_block').find('select.filter_conditions').empty().append(condOptions.join(""))
          if data.values.length
            valueInput = ['<select id="filter[more][]_value" name="filter[more][][value]">']
            $.each data.values, (key, val) => valueInput.push("<option value='#{val}'>#{val}</option>")
            valueInput.push('</select>')
          else
            valueInput = ['<input type="text" name="filter[more][][value]" value="" placeholder="value">']
          element.parents('div.filter_block').find('div.filter_values').html(valueInput.join(""))
          if "date" is element.val()
            element.parents('div.filter_block').find('div.filter_values input').datepicker
              dateFormat: "yy-mm-dd"
              changeMonth: true
              changeYear: true
              yearRange: 'c-50:c+10'
    # delete one filter
    $(document).on 'click', '.close_more_filter', (event) =>
      event.preventDefault()
      $(event.currentTarget).parents('li').remove()
    # message tabs
    $(document).on 'click', 'li.message_tab', (event) =>
      event.preventDefault()
      element = $(event.currentTarget)
      tab = element.data('tab')
      $('li.message_tab').removeClass('active')
      $('pre.tab_content').addClass('hidden')
      element.addClass('active')
      $(".#{tab}").removeClass('hidden')
    # keydown by logs
    $(document).on 'keydown', '*', (event) =>
      return if $("input").is(":focus")
      switch event.keyCode
        when 37 # left
          MongodbLoggerMain.moveByLogs('begin')
        when 38 # up
          MongodbLoggerMain.moveByLogs('up')
        when 39 # right
          MongodbLoggerMain.moveByLogs('end')
        when 40 # down
          MongodbLoggerMain.moveByLogs('down')
    # init pjax
    this.initPjax()
    this.initOnPages()
  initPjax: ->
    # pjax
    $(document).pjax('a[data-pjax]', '#mainPjax')
    $(document).on 'pjax:start', => $('#ajaxLoader').show()
    $(document).on 'pjax:end', =>
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
    $(".datepicker, .filter_values input.date").datepicker
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
    if logLastId? and logLastId.length
      url = "#{MongodbLoggerMain.tailLogsUrl}/#{logLastId}"
    else
      MongodbLoggerMain.tailLogStarted = true
    return false unless MongodbLoggerMain.tailLogStarted
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
            $('#logsList tr:first').after(elements).effect("highlight", {}, 1000)
          if data.collection_stats && $("#collection_stats").length > 0
            $("#collection_stats").html(data.collection_stats)
        setTimeout((-> MongodbLoggerMain.tailLogs(logLastId)), 2000) if MongodbLoggerMain.tailLogStarted
  # move using keys by logs
  moveByLogs: (direction) ->
    if $('#logsList').length and $('#logsList').find('tr.current').length
      currentElement = $('#logsList').find('tr.current')
      switch direction
        when 'begin'
          element = $('#logsList tr:first').next("tr")
          if element.length
            element.find('td:first').trigger('click')
            $(window).scrollTop(element.height() + element.offset().top - 100)
            return false
        when 'end'
          element = $('#logsList tr:last')
          if element.length
            element.find('td:first').trigger('click')
            $(window).scrollTop(element.height() + element.offset().top - 100)
            return false
        when 'down'
          element = currentElement.next("tr")
          if element.length
            element.find('td:first').trigger('click')
            if MongodbLoggerMain.isScrolledIntoView(element)
              $(window).scrollTop($(window).scrollTop() + element.height())
            else
              $(window).scrollTop(element.height() + element.offset().top - 100)
            return false
        when 'up'
          element = currentElement.prev("tr")
          if element.length
            element.find('td:first').trigger('click')
            if MongodbLoggerMain.isScrolledIntoView(element)
              $(window).scrollTop($(window).scrollTop() - element.height())
            else
              $(window).scrollTop(element.height() + element.offset().top - 100)
            return false
  # check in selected element is visible for user
  isScrolledIntoView: (elem) ->
    docViewTop = $(window).scrollTop()
    docViewBottom = docViewTop + $(window).height()
    elemTop = $(elem).offset().top
    elemBottom = elemTop + $(elem).height()
    return ((docViewTop < elemTop) && (docViewBottom > elemBottom))

$ ->
  MongodbLoggerMain.init()