# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->
  $('.company_name').hover(
    ->  $(this).children('.actions').show() 
    ->  $(this).children('.actions').hide()
  ) 

  $("#csv_file").on 'change', ->
    $('#import_csv_file').submit()
 
  template = Mustache.compile($.trim($("#template").html()));
  
  view = (record, index) ->
    record.first_contact = record.contact_persons[0]
    record.remaining = record.contact_persons.slice(1) if record.contact_persons.length > 1
    return template({record: record, index: index});

  options = {
    view: view                  
    data_url: '/vendors.json'
    stream_after: 2           
    fetch_data_limit: 500
    fields: (record) -> 
                return [ 
                            record.category,
                            record.company,
                            $.map record.contact_persons, (c) -> c.name
                        ].join(' ')  
                    
  }
  if($('#vendor_stream_table').length) 
    $("#vendor_stream_table").stream_table(options, data) if typeof data isnt "undefined"


