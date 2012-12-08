root = global ? window

class root.MongodbLoggerAnalytics
  constructor: (@mongoData) ->
    @chartContainer = 'analyticData'
    @_resultsData = 
      x: []
      y: []
    @_collectAllData()
    @_drawGraph()
  _collectAllData: =>
    headers = @mongoData.headers
    dates = []
    values = []
    for row in @mongoData.data
      date = if row._id.hasOwnProperty("hour")
        new Date(row._id.year, parseInt(row._id.month) - 1, row._id.day, row._id.hour, 0, 0)
      else if row._id.hasOwnProperty("day")
        new Date(row._id.year, parseInt(row._id.month) - 1, row._id.day)
      else
        new Date(row._id.year, parseInt(row._id.month) - 1, 0)
      dates.push(date.getTime())
      values.push(row.value.count)
    @_resultsData = 
      x: dates
      y: values
  _drawGraph: =>
    width = $("##{@chartContainer}").width() - 40
    height = 600
    $("##{@chartContainer}").empty()
    @r = Raphael(@chartContainer, width, height)
    lines = @r.linechart(10, 10, width - 40, height - 20, @_resultsData.x, @_resultsData.y,
      nostroke: false # lines between points are drawn
      axis: "0 0 1 1" # draw axes on the left and bottom
      symbol: "circle" # use a filled circle as the point symbol
      smooth: false # curve the lines to smooth turns on the chart
      dash: "-" # draw the lines dashed
    )
    for i, label of lines.axis[0].text.items
      date = new Date(parseInt(label.attr("text")))
      switch parseInt(@mongoData.unit)
        when 1
          label.attr({text: "#{date.getFullYear()}/#{date.getMonth() + 1}/#{date.getDate()}"})
        when 2
          label.attr({text: "#{date.getFullYear()}/#{date.getMonth() + 1}/#{date.getDate()} #{date.getHours() + 1} h"})
        else
          label.attr({text: "#{date.getFullYear()}/#{date.getMonth() + 1}"})
    
$ ->
  $(document).on 'submit', '#analyticForm', (e) =>
    e.preventDefault()
    form = $(e.currentTarget)
    $.ajax 
      url: form.attr('action')
      dataType: 'json' 
      data: form.serializeArray()
      type: "POST"
      success: (data, textStatus, jqXHR) =>
        mongodbLoggerAnalytic = new MongodbLoggerAnalytics(data)