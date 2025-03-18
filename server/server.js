// register plugin, server-side component
// These handlers are launched with the wiki server.

import fs from 'node:fs'
import fsp from 'node:fs/promises'
import path from 'node:path'

// lookup = require 'dns-lookup'
const lookup = async want => {
  return [null, null]
} // todo replace with proper dns lookup

const startServer = function (params) {
  const { app, argv } = params

  // settings = null
  // fs.readFile path.resolve(argv.status, 'plugins', 'register', 'settings.json'), (err, text) ->
  //   return console.log('register settings', err) if err
  //   settings = JSON.parse text

  const admin = function (req, res, next) {
    if (app.securityhandler.isAdmin(req)) {
      return next()
    } else {
      let a, u
      if (!argv.admin) {
        a = 'no admin specified'
      }
      if (!req.session?.passport?.user && !req.session?.email && !req.session?.friend) {
        u = 'not logged in'
      }
      return res.status(403).send(`Must be admin user, ${a || u}`)
    }
  }

  const farm = function (req, res, next) {
    if (argv.farm) {
      return next()
    } else {
      return res.status(403).send({ error: 'Must be wiki farm to make subdomains' })
    }
  }

  const owner = function (req, res, next) {
    if (!app.securityhandler.isAuthorized(req)) {
      return res.status(401).send('must be owner')
    }
    return next()
  }

  // O W N E R

  app.post('/plugin/register/new', owner, farm, async function (req, res) {
    let context, data
    const e400 = msg => res.status(400).send(msg)
    const e409 = msg => res.status(409).send(msg)
    const e500 = msg => res.status(500).send(msg)
    if (!(data = req.body.data)) {
      return e400('Missing data')
    }
    if (!(context = req.body.context)) {
      return e400('Missing context')
    }
    if (data.domain === 'www') {
      return e409("Can't route www subdomain")
    }

    const [site, port] = context.site.split(':')
    const [host] = req.headers.host.split(':')
    if (site !== host) {
      return e400("Can't register from remote site")
    }
    if (!data.domain.match(new RegExp(`^[a-z][a-z0-9]{1,7}$`))) {
      return e400('Unsupported subdomain name')
    }
    const want = `${data.domain}.${site}`
    const wantPath = path.resolve(argv.data, '..', `${data.domain}.${site}`)

    try {
      const [ip, family] = await lookup(want)
      const owner = await fsp.readFile(`${argv.status}/owner.json`, 'utf8')
      await fsp.mkdir(`${wantPath}`)
      await fsp.mkdir(`${wantPath}/status`)
      await fsp.writeFile(`${wantPath}/status/owner.json`, owner)

      const got = want + (port ? `:${port}` : '')
      res.setHeader('Content-Type', 'application/json')
      res.send(JSON.stringify({ status: 'ok', site: got }))
    } catch (err) {
      e500(`${err}`)
    }
  })

  app.get('/plugin/register/using', farm, owner, function (req, res) {
    const e500 = msg => res.status(500).send(msg)
    const looking = argv.data.split('/')
    const like = looking.pop()
    const where = looking.join('/')
    return fs.readFile(`${argv.status}/owner.json`, 'utf8', function (err, owner) {
      if (err) {
        return e500(`${err}`)
      }
      return fs.readdir(where, { withFileTypes: true }, function (err, files) {
        const have = files.filter(
          file => file.isDirectory() && file.name.match(new RegExp(`^[a-z][a-z0-9]{1,7}\\.${like}$`)),
        )
        const mine = have.filter(function (file) {
          try {
            const other = fs.readFileSync(`${where}/${file.name}/status/owner.json`, 'utf8')
            return JSON.parse(owner).name === JSON.parse(other).name
          } catch (error) {
            return false
          }
        })
        const payload = mine.map(file => ({
          site: file.name,
          owned: true,
          pages: 0,
        }))
        return res.json(payload)
      })
    })
  })

  // D E L E G A T E

  const newOwner = async function (data) {
    const ownerfile = {
      name: data.owner,
      friend: {
        secret: data.code,
      },
    }
    return JSON.stringify(ownerfile, null, 2)
  }

  app.post('/plugin/register/delegate', owner, farm, async function (req, res) {
    let context, data
    const e400 = msg => res.status(400).send(msg)
    const e409 = msg => res.status(409).send(msg)
    const e500 = msg => res.status(500).send(msg)
    if (!(data = req.body.data)) {
      return e400('Missing data')
    }
    if (!(context = req.body.context)) {
      return e400('Missing context')
    }
    if (!data.owner) {
      return e400('Missing owner name')
    }
    if (!data.code) {
      return e400('Missing reclaim code')
    }
    if (data.domain === 'www') {
      return e409("Can't route www subdomain")
    }

    const [site, port] = context.site.split(':')
    const [host] = req.headers.host.split(':')
    if (site !== host) {
      return e400("Can't register from remote site")
    }
    if (!data.domain.match(new RegExp(`^[a-z][a-z0-9]{1,7}$`))) {
      return e400('Unsupported subdomain name')
    }
    const want = `${data.domain}.${site}`
    if (!data.domain.match(new RegExp(`^[a-z][a-z0-9]{1,7}$`))) {
      return e400('Unsupported subdomain name')
    }
    if (!data.code.match(new RegExp(`^[[0-9a-f]{5,64}$`))) {
      return e400('Unsupported reclaim code')
    }
    const wantPath = path.resolve(argv.data, '..', `${data.domain}.${site}`)

    try {
      const [ip, family] = await lookup(want)
      const owner = await newOwner(data)
      await fsp.mkdir(`${wantPath}`)
      await fsp.mkdir(`${wantPath}/status`)
      await fsp.writeFile(`${wantPath}/status/owner.json`, owner)

      const got = want + (port ? `:${port}` : '')
      res.setHeader('Content-Type', 'application/json')
      return res.send(JSON.stringify({ status: 'ok', site: got }))
    } catch (err) {
      e500(`${err}`)
    }
  })

  app.get('/plugin/register/delegated', farm, owner, function (req, res) {
    const e500 = msg => res.status(500).send(msg)
    const looking = argv.data.split('/')
    const like = looking.pop()
    const where = looking.join('/')
    return fs.readFile(`${argv.status}/owner.json`, 'utf8', function (err, owner) {
      if (err) {
        return e500(`${err}`)
      }
      return fs.readdir(where, { withFileTypes: true }, function (err, files) {
        const have = files.filter(
          file => file.isDirectory() && file.name.match(new RegExp(`^[a-z][a-z0-9]{1,7}\\.${like}$`)),
        )
        const mine = have.filter(function (file) {
          try {
            const other = fs.readFileSync(`${where}/${file.name}/status/owner.json`, 'utf8')
            return JSON.parse(owner).name !== JSON.parse(other).name
          } catch (error) {
            return false
          }
        })
        const payload = mine.map(file => ({
          site: file.name,
          owned: true,
          pages: 0,
        }))
        return res.json(payload)
      })
    })
  })

  // C U S T O M

  const custom = null
  // fs.readFile "#{argv.status}/register.js", 'utf8', (err, module) ->
  //   custom = await import("data:text/javascript;base64,#{btoa(module)}")

  app.post('/plugin/register/custom', owner, farm, function (req, res) {
    let context, data
    const e400 = msg => res.status(400).send(msg)
    const e501 = msg => res.status(501).send(msg)
    if (!(data = req.body.data)) {
      return e400('Missing data')
    }
    if (!(context = req.body.context)) {
      return e400('Missing context')
    }
    console.log('custom post', { context, data, custom })
    if (!custom) {
      return e501('No register module')
    }
    return custom.post(argv, data, function (err, status) {
      if (err) {
        return e400(status)
      }
      return res.status(200).send(status)
    })
  })

  return app.get('/plugin/register/custom', farm, function (req, res) {
    const e400 = msg => res.status(400).send(msg)
    const e501 = msg => res.status(501).send(msg)
    if (!custom) {
      return e501('No register module')
    }
    return custom.get(argv, req, function (err, status) {
      if (err) {
        return e400(err)
      }
      return res.status(200).send(status)
    })
  })
}

export { startServer }
