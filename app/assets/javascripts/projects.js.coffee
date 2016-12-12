# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
$(document).ready ->

  $('#image-upload').on 'change', ->
    readURL this, '#project-image'
    return
  $('#logo-upload').on 'change', ->
    readURL this, '#project-logo'
    return

readURL = (input, src_id) ->
  if input.files and input.files[0]
    reader = new FileReader

    reader.onload = (e) ->
      $(src_id).attr 'src', e.target.result
      return

    reader.readAsDataURL input.files[0]
  return
