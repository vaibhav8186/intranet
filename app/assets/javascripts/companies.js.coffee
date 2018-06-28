$(document).ready ->
  template = Mustache.compile($.trim($('#company_template').html()))
  view = (record, index) ->
    template
      record: record
      index: index

  options =
    view: view
    data_url: '/companies.json'
    stream_after: 2
    fetch_data_limit: 10

  if($('#company_stream_table').length)
    $('#company_stream_table').stream_table options, data if typeof data isnt "undefined"
