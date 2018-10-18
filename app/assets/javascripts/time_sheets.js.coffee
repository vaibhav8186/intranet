# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$(document).ready ->
  $('.dropdown-submenu a.test').on 'click', (e) ->
    $(this).next('ul').toggle()
    e.stopPropagation()
    e.preventDefault()
    return
  return