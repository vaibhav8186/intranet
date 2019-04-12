$(document).ready ->
  $('.user_name').hover(
    ->  $(this).children('.actions').show() 
    ->  $(this).children('.actions').hide()
  ) 

  

  template = Mustache.compile($.trim($("#template").html()));
  
  view = (record, index) ->
    if record.employee_detail
      record.id = record.employee_detail.employee_id
    if record.public_profile  
      record.image = record.public_profile.image.thumb.url
      record.mobile_number = record.public_profile.mobile_number
      record.name = record.public_profile.first_name + " "+record.public_profile.last_name
    record.is_slug = record._slugs
    record.is_approved = record.status == "approved"
    return template({record: record, index: index});
    

  options = {
    view: view                  
    data_url: '/users.json'
    stream_after: 2           
    fetch_data_limit: 500
    fields: (record) -> 
      [
        record.email,
        record.public_profile.first_name,
        record.public_profile.last_name
      ].join('')
  }
  if($('#user_stream_table').length)
    $("#user_stream_table").stream_table(options, approved) if typeof approved isnt "undefined"


