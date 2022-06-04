expand = (text) ->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

detag = (text) ->
  text
    .replace /<.+?>/g, ''

error = (text) ->
  "<div class=error style='color:#F88;'>#{text}</div>"

form = (item) ->
  subdomain = if item.privilege == 'delegate' then 'delegate' else 'subdomain'
  fields = if item.privilege == 'delegate'
    """
      <input type=text name=domain size=50 placeholder="full domain name" pattern="[a-z][a-z0-9]{1,7}\.#{window.location.hostname}" required>
      <input type=text name=owner size=50 placeholder="user's full name" required>
      <input type=email name=email size=50 placeholder="user's email" required>
    """
  else
    """
      <input type=text name=domain size=50 placeholder="full domain name" pattern="[a-z][a-z0-9]{1,7}\.#{window.location.hostname}" required>
    """
  """
    <div style="background-color:#eee; padding:15px;">
      <center>
      <p><img src='/favicon.png' width=16> <span style='color:gray;'>#{window.location.host}</span></p>
      <p>#{expand item.text}</p>
      <p>show owner's <button class=existing>Existing</button> #{subdomain}s
        <span class=existing></span>
      </p>
      <div class=fields>#{fields}</div>
      <p>owner can <button class=register>Register</button> additional #{subdomain}</p>
      <span class=result></span>

      </center>
    </div>
  """


submit = ($item, item) ->
  data = {}
  valid = true
  $item.find('.error').remove()
  for input in $item.find('.fields input')
    if input.checkValidity()
      data[input.name] = input.value.split('.')[0]
    else
      valid = false
      input.insertAdjacentHTML 'afterend', error(input.validationMessage)
  return unless valid

  trouble = (e) ->
    $item.find('span.result').html error "#{e.status} #{e.statusText}<br>#{detag e.responseText||''}"

  redirect = (e) ->
    $item.find('span.result').html "registered<br><a href=//#{e.site} target=_blank>#{e.site}</a>"

  context =
    site: $item.parents('.page').find('h1').attr('title').split("\n")[0]
    slug: $item.parents('.page').attr('id')
    item: item.id

  endpoint = if item.privilege == 'delegate' then 'delegate' else 'new'
  $.ajax
    type: 'POST'
    url: "/plugin/register/#{endpoint}"
    data: JSON.stringify({data, context})
    contentType: "application/json; charset=utf-8"
    dataType: 'json'
    success: redirect
    error: trouble

emit = ($item, item) ->
  $item.html form item
  port = if (window.location.port) then ':' + window.location.port else ''
  $item.find('button.existing').click ->
    using = if item.privilege == 'delegate' then 'delegated' else 'using'
    fetch("/plugin/register/#{using}")
      .then (res) ->
        if !res.ok
          $item.find('span.existing').html(error "#{res.status} #{res.statusText}")
          return null
        res.json()
      .then (list) ->
        html = list.map (item) ->
          # "#{item.site} (#{if item.owned then 'mine' else 'others'})"
          "<a href=//#{item.site}#{port}>#{item.site}</a>"
        if !html.length then html = ['<i>no subdomains here</i>']
        html.unshift('<br>')
        $item.find('span.existing').html(html.join("<br>"))
  $item.find('button.register').click ->
    submit $item, item
  $item.find('span.existing, a').click ->
    event.preventDefault()
    page = $item.parents '.page' unless event.shiftKey
    wiki.doInternalLink 'welcome-visitors',page,event.target.innerText+port

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item
  $item.find('input').dblclick (e) -> e.stopPropagation()

window.plugins.register = {emit, bind} if window?
module.exports = {expand} if module?

