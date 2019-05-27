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
    view: view,                  
    data_url: '/users.json',
    stream_after: 2,           
    fetch_data_limit: 200
  }

  approved = data.filter((d) ->
    d.status == "approved"
  )
  if($('#user_stream_table').length)
    $("#user_stream_table").stream_table(options, data) if typeof data isnt "undefined"

  $('#show').click ->
    if $(this).text() == 'Show Approved'
      $(this).text('Show All')
      $('tr[hide]').removeAttr('hidden')
      $('#user_note_text').text('Showing approved users only.')
      st = $("#user_stream_table").data('st')
      st.data = []
      st.addData(approved)
    else
      $(this).text('Show Approved')
      $('tr[hide]').attr('hidden', 'true')
      $('#user_note_text').text('Showing all users.')
      st = $("#user_stream_table").data('st')
      st.data = []
      st.addData(data)
  
  $('#download_btn').click -> 
    if $('#show').text() == 'Show All'
      window.location.href = '/users.xlsx' 
    else
      window.location.href = '/users.xlsx'+'?'+ 'status=all'
