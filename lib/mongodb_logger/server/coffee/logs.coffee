root = global ? window

root.MongodbLoggerMain = 
  tail_logs_url: null
  tail_log_started: false
  log_info_offset: null
  log_info_padding: 15
  is_charts_ready: false
  
  init: ->
    # spinner
    $(document).ajaxStart =>
      $('#ajax_loader').show()
    $(document).ajaxStop =>
      $('#ajax_loader').hide()
    # tail logs buttons
    $(document).on 'click', '#tail_logs_link', (event) =>
      MongodbLoggerMain.tail_logs_url = $(event.target).attr('data-url')
      $('#tail_logs_block').addClass('started')
      MongodbLoggerMain.tail_logs(null)
      return false
    $(document).on 'click', '#tail_logs_stop_link', (event) =>
      MongodbLoggerMain.tail_log_started = false
      $('#tail_logs_block').removeClass('started')
      return false
    # log info click
    $(document).on 'click', '.log_info', (event) =>
      elm_obj = $(event.target)
      url = elm_obj.data('url')
      url = elm_obj.parent('tr').data('url') if !url?
      if url?
        elm_obj.parents('table').find('tr').removeClass('current')
        elm_obj.parent('tr').addClass('current')
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
    this.init_pjax()
    this.init_on_pages()
    
  init_pjax: ->
    # pjax
    $('a[data-pjax]').pjax()
    $('body').bind 'pjax:start', () => 
      $('#ajax_loader').show()
    $('body').bind 'pjax:end', () => 
      $('#ajax_loader').hide()
      # stop tailing
      MongodbLoggerMain.tail_log_started = false
      # scroll on top
      if ($(window).scrollTop() > 100)
        $('html, body').stop().animate({ scrollTop: 0 }, 'slow')
      # init pages
      MongodbLoggerMain.init_on_pages()
  # init this on pjax
  init_on_pages: ->
    # code highlight
    $('pre code').each (i, e) ->
      hljs.highlightBlock(e, '  ')
    # callendars  
    $( ".datepicker, .filter_values input.date" ).datepicker
      dateFormat: "yy-mm-dd"
      changeMonth: true
      changeYear: true
      yearRange: 'c-50:c+10'
    # log info window
    if $("#log_info").length > 0
      MongodbLoggerMain.log_info_offset = $("#log_info").offset()
      $(window).scroll =>
        if $(window).scrollTop() > MongodbLoggerMain.log_info_offset.top
          $("#log_info").stop().animate
            marginTop: $(window).scrollTop() - MongodbLoggerMain.log_info_offset.top + MongodbLoggerMain.log_info_padding
        else
          $("#log_info").stop().animate
            marginTop: 0
  # tail logs function
  tail_logs: (log_last_id) ->
    url = MongodbLoggerMain.tail_logs_url
    if log_last_id? && log_last_id.length > 0
      url = MongodbLoggerMain.tail_logs_url + "/" + log_last_id 
    else
      MongodbLoggerMain.tail_log_started = true
      log_last_id = ""
    if MongodbLoggerMain.tail_log_started
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
          if MongodbLoggerMain.tail_log_started
            fcallback = -> MongodbLoggerMain.tail_logs(log_last_id)
            setTimeout fcallback, 2000
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
  # charts ready for usage
  init_analytic_charts: ->
    MongodbLoggerMain.is_charts_ready = true
  # build charts
  build_analytic_charts: (data) ->
    if MongodbLoggerMain.is_charts_ready is true
      if data.data?
        data_table = new google.visualization.DataTable()
        data_table.addColumn('date', 'Date')
        data_table.addColumn('number', 'Requests')
        data_table.addRows(data.data.length)
        i = 0
        for row in data.data
          data_table.setValue(i, 0, new Date(row['_id'].year, row['_id'].month - 1, row['_id'].day))
          data_table.setValue(i, 1, row.value.count)
          i += 1
          
        chart_element = $("<div></div>").attr('id', 'google-chart').css({width: 800, height: 500})
        $('#analyticData').empty().html(chart_element)
        chart = new google.visualization.AnnotatedTimeLine(document.getElementById('google-chart'))
        options = 
          title: $('#analytic_type option:selected').text()
          vAxis:
            title: 'Requests'
        chart.draw(data_table, options)

$ ->
  MongodbLoggerMain.init()