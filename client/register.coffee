
expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

form = (item) ->
  """
    <div style="background-color:#eee; padding:15px;">
      <p>#{expand item.text}</p>
      <div class=input><input type=email name=email size=60 placeholder="email" required></div>
      <div class=input><input type=text name=domain size=60 placeholder="domain" pattern="[a-z][a-z0-9]{1,7}" required></div>
      <center>login to <button>Register</button></center>
    </div>
  """

submit = ($item, item) ->
  data = {}
  valid = true
  $item.find('.error').remove()
  for div in $item.find('.input')
    input = ($div = $(div)).find('input').get(0)
    if input.checkValidity()
      data[input.name] = input.value
    else
      valid = false
      $div.append "<div class=error style='color:#888;'>#{input.validationMessage}</div>"
  return unless valid
  console.log 'data', data

  trouble = (e) -> console.log 'trouble',e
  redirect = (e) -> console.log 'redirect',e

  $.ajax
    type: 'POST'
    url: '/plugin/register/new'
    data: JSON.stringify(data)
    contentType: "application/json; charset=utf-8"
    dataType: 'json'
    success: redirect
    error: trouble

emit = ($item, item) ->
  $item.html form item
  $item.find('button').click ->
    submit $item, item

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item
  $item.find('input').dblclick (e) -> e.stopPropagation()

window.plugins.register = {emit, bind} if window?
module.exports = {expand} if module?

