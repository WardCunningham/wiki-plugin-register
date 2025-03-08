const expand = text => {
  return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

const detag = text => {
  return text.replace(/<.+?>/g, '')
}

const error = text => {
  return `<div class=error style='color:#F88;'>${text}</div>`
}

const form = item => {
  const subdomain = item.privilege == 'delegate' ? 'delegate' : 'subdomain'
  const fields =
    item.privilege == 'delegate'
      ? `
      <input type=text name=domain size=50 placeholder="full domain name" pattern="[a-z][a-z0-9]{1,7}\.${window.location.hostname}" required>
      <input type=text name=owner size=50 placeholder="user's full name" required>
      <input type=text name=code size=50 placeholder="user's reclaim code" pattern="[0-9a-f]{5,64}" required>
    `
      : `
      <input type=text name=domain size=50 placeholder="full domain name" pattern="[a-z][a-z0-9]{1,7}\.${window.location.hostname}" required>
    `
  return `
    <div style="background-color:#eee; padding:15px;">
      <center>
      <p><img src='/favicon.png' width=16> <span style='color:gray;'>${window.location.host}</span></p>
      <p>${expand(item.text)}</p>
      <p>show owner's <button class=existing>Existing</button> ${subdomain}s
        <span class=existing></span>
      </p>
      <div class=fields>${fields}</div>
      <p>owner can <button class=register>Register</button> additional ${subdomain}</p>
      <span class=result></span>
      </center>
    </div>
  `

  // <input type=email name=email size=50 placeholder="user's email" required>
}

const submit = ($item, item) => {
  const data = {}
  let valid = true
  $item.find('.error').remove()
  for (const input of $item.find('.fields input')) {
    if (input.checkValidity()) {
      data[input.name] = input.value
    } else {
      valid = false
      input.insertAdjacentHTML('afterend', error(input.validationMessage))
    }
  }
  if (!valid) return

  data['domain'] = data['domain'].split('.')[0] // we send only the subdomain name

  const trouble = e => {
    $item.find('span.result').html(error(`${e.status} ${e.statusText}<br>${detag(e.responseText || '')}`))
  }

  const redirect = e => {
    $item.find('span.result').html(`registered<br><a href=//${e.site} target=_blank>${e.site}</a>`)
  }

  const context = {
    site: window.location.host,
    slug: $item.parents('.page').attr('id'),
    item: item.id,
  }

  const endpoint = item.privilege == 'delegate' ? 'delegate' : 'new'
  $.ajax({
    type: 'POST',
    url: `/plugin/register/${endpoint}`,
    data: JSON.stringify({ data, context }),
    contentType: 'application/json; charset=utf-8',
    dataType: 'json',
    success: redirect,
    error: trouble,
  })
}

const emit = ($item, item) => {
  $item.html(form(item))
  const port = window.location.port ? ':' + window.location.port : ''
  $item.find('button.existing').on('click', () => {
    const using = item.privilege == 'delegate' ? 'delegated' : 'using'
    fetch(`/plugin/register/${using}`)
      .then(res => {
        if (!res.ok) {
          $item.find('span.existing').html(error(`${res.status} ${res.statusText}`))
          return null
        }
        return res.json()
      })
      .then(list => {
        let html = list.map(item => {
          return `<a href=//${item.site}${port}>${item.site}</a>`
        })
        if (!html.length) html = ['<i>no subdomains here</i>']
        html.unshift('<br>')
        $item.find('span.existing').html(html.join('<br>'))
      })
  })
  $item.find('button.register').on('click', () => {
    submit($item, item)
  })
  $item.find('span.existing, a').on('click', () => {
    event.preventDefault()
    let page
    if (!event.shiftKey) page = $item.parents('.page')
    wiki.doInternalLink('welcome-visitors', page, event.target.innerText + port)
  })
}

const bind = ($item, item) => {
  $item.on('dblclick', () => wiki.textEditor($item, item))
  $item.find('input').on('dblclick', e => e.stopPropagation())
}

if (typeof window !== 'undefined') window.plugins.register = { emit, bind }
export const register = typeof window == 'undefined' ? { expand } : undefined
