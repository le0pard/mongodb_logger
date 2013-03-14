root = global ? window

class root.MongodbLoggerAnalytics
  constructor: (@mongoData) ->
    return unless @mongoData and @mongoData.data and @mongoData.data.length
    @chartContainer = 'analyticData'
    @_resultsData = []
    @_collectAllData()
    @_drawGraph()
  _collectAllData: =>
    headers = @mongoData.headers
    for row in @mongoData.data
      date = if row._id.hasOwnProperty("hour")
        new Date(row._id.year, parseInt(row._id.month) - 1, row._id.day, row._id.hour, 0, 0)
      else if row._id.hasOwnProperty("day")
        new Date(row._id.year, parseInt(row._id.month) - 1, row._id.day)
      else
        new Date(row._id.year, parseInt(row._id.month) - 1, 0)
      @_resultsData.push
        x: (date.getTime() / 1000)
        y: row.value.count
  _drawGraph: =>
    width = $("##{@chartContainer}").width() - 100
    height = 600
    $("##{@chartContainer}").empty()

    @graph = new Rickshaw.Graph(
      element: $("##{@chartContainer}")[0]
      width: width
      height: height
      renderer: "line"
      interpolation: "linear"
      series: [
        color: 'steelblue'
        data: @_resultsData
        name: "Results"
      ]
    )
    @graph.render()
    hoverDetail = new Rickshaw.Graph.HoverDetail(
      graph: @graph
      formatter: (series, x, y) =>
        date = "<span class=\"date\">" + new Date(x * 1000).toUTCString() + "</span>"
        swatch = "<span class=\"detail_swatch\" style=\"background-color: " + series.color + "\"></span>"
        content = swatch + series.name + ": " + parseInt(y) + "<br>" + date
        content
    )
    xAxis = new Rickshaw.Graph.Axis.Time(
      graph: @graph
    )
    xAxis.render()
    yAxis = new Rickshaw.Graph.Axis.Y(
      graph: @graph
    )
    yAxis.render()

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