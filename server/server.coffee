# register plugin, server-side component
# These handlers are launched with the wiki server. 

fs = require 'fs'
path = require 'path'
# lookup = require 'dns-lookup'
lookup = (want,done) -> done(null,null,null)  # todo replace with proper dns lookup

startServer = (params) ->
  app = params.app
  argv = params.argv

  # settings = null
  # fs.readFile path.resolve(argv.status, 'plugins', 'register', 'settings.json'), (err, text) ->
  #   return console.log('register settings', err) if err
  #   settings = JSON.parse text

  admin = (req, res, next) ->
    if app.securityhandler.isAdmin(req)
      next()
    else
      a = "no admin specified" unless argv.admin
      u = "not logged in" unless req.session?.passport?.user || req.session?.email || req.session?.friend
      res.status(403).send "Must be admin user, #{a||u}"

  farm = (req, res, next) ->
    if argv.farm
      next()
    else
      res.status(403).send {error: 'Must be wiki farm to make subdomains'}

  owner = (req, res, next) ->
    return res.status(401).send("must be owner") unless app.securityhandler.isAuthorized(req)
    next()

  # O W N E R

  app.post '/plugin/register/new', owner, farm, (req, res) ->
    e400 = (msg) -> res.status(400).send(msg)
    e409 = (msg) -> res.status(409).send(msg)
    e500 = (msg) -> res.status(500).send(msg)
    return e400 "Missing data" unless data = req.body.data
    return e400 "Missing context" unless context =req.body.context
    return e409 "Can't route www subdomain" if data.domain == 'www'

    [site,port] = context.site.split ':'
    [host,_] = req.headers.host.split ':'
    return e400 "Can't register from remote site" unless site is host
    return e400 "Unsupported subdomain name" unless data.domain.match ///^[a-z][a-z0-9]{1,7}$///
    want = "#{data.domain}.#{site}"
    wantPath =  path.resolve(argv.data, '..', "#{data.domain}.#{site}")
    lookup want, (err, ip, family) ->
      return e409 "Can't resolve wildcard #{want}" if err?.code == 'ENOTFOUND'
      return e500 "#{err}" if err

      fs.readFile "#{argv.status}/owner.json", 'utf8', (err, owner) ->
        return e500 "#{err}" if err

        fs.mkdir "#{wantPath}", (err) ->
          return e500 "#{err}" if err

          fs.mkdir "#{wantPath}/status", (err) ->
            return e500 "#{err}" if err

            fs.writeFile "#{wantPath}/status/owner.json", owner, (err) ->
              return e500 "#{err}" if err

              got = want + if port then ":#{port}" else ''
              res.setHeader 'Content-Type', 'application/json'
              res.send JSON.stringify {status: 'ok', site: got}

  app.get '/plugin/register/using', farm, owner, (req, res) ->
    looking = argv.data.split('/')
    like = looking.pop()
    where = looking.join('/')
    fs.readFile "#{argv.status}/owner.json", 'utf8', (err, owner) ->
      return e500 "#{err}" if err
      fs.readdir where, {withFileTypes:true}, (err, files) ->
        have = files.filter (file) -> file.isDirectory() && file.name.match ///^[a-z][a-z0-9]{1,7}\.#{like}$///
        mine = have.filter (file) ->
          try
            other = fs.readFileSync "#{where}/#{file.name}/status/owner.json", 'utf8'
            return JSON.parse(owner).name == JSON.parse(other).name
          catch
            return false
        payload = mine.map (file) -> {site: file.name, owned:true, pages:0}
        res.json(payload)


  # D E L E G A T E

  newOwner = (data, done) ->
    ownerfile =
      name: data.owner
      friend:
        secret: data.code
    done null, JSON.stringify(ownerfile,null,2)

  app.post '/plugin/register/delegate', owner, farm, (req, res) ->
    e400 = (msg) -> res.status(400).send(msg)
    e409 = (msg) -> res.status(409).send(msg)
    e500 = (msg) -> res.status(500).send(msg)
    return e400 "Missing data" unless data = req.body.data
    return e400 "Missing context" unless context =req.body.context
    return e400 "Missing owner name" unless data.owner
    return e400 "Missing reclaim code" unless data.code
    return e409 "Can't route www subdomain" if data.domain == 'www'

    [site,port] = context.site.split ':'
    [host,_] = req.headers.host.split ':'
    return e400 "Can't register from remote site" unless site is host
    return e400 "Unsupported subdomain name" unless data.domain.match ///^[a-z][a-z0-9]{1,7}$///
    want = "#{data.domain}.#{site}"
    return e400 "Unsupported subdomain name" unless data.domain.match ///^[a-z][a-z0-9]{1,7}$///
    return e400 "Unsupported reclaim code" unless data.code.match ///^[[0-9a-f]{5,64}$///
    wantPath =  path.resolve(argv.data, '..', "#{data.domain}.#{site}")
    lookup want, (err, ip, family) ->
      return e409 "Can't resolve wildcard #{want}" if err?.code == 'ENOTFOUND'
      return e500 "#{err}" if err

      # fs.readFile "#{argv.status}/owner.json", 'utf8', (err, owner) ->
      newOwner data, (err, owner) ->
        return e500 "#{err}" if err

        fs.mkdir "#{wantPath}", (err) ->
          return e500 "#{err}" if err

          fs.mkdir "#{wantPath}/status", (err) ->
            return e500 "#{err}" if err

            fs.writeFile "#{wantPath}/status/owner.json", owner, (err) ->
              return e500 "#{err}" if err

              got = want + if port then ":#{port}" else ''
              res.setHeader 'Content-Type', 'application/json'
              res.send JSON.stringify {status: 'ok', site: got}

  app.get '/plugin/register/delegated', farm, owner, (req, res) ->
    looking = argv.data.split('/')
    like = looking.pop()
    where = looking.join('/')
    fs.readFile "#{argv.status}/owner.json", 'utf8', (err, owner) ->
      return e500 "#{err}" if err
      fs.readdir where, {withFileTypes:true}, (err, files) ->
        have = files.filter (file) -> file.isDirectory() && file.name.match ///^[a-z][a-z0-9]{1,7}\.#{like}$///
        mine = have.filter (file) ->
          try
            other = fs.readFileSync "#{where}/#{file.name}/status/owner.json", 'utf8'
            return JSON.parse(owner).name != JSON.parse(other).name
          catch
            return false
        payload = mine.map (file) -> {site: file.name, owned:true, pages:0}
        res.json(payload)


  # C U S T O M

  custom = null
  fs.readFile "#{argv.status}/register.js", 'utf8', (err, module) ->
    custom = await import("data:text/javascript;base64,#{btoa(module)}")

  app.post '/plugin/register/custom', owner, farm, (req, res) ->
    e400 = (msg) -> res.status(400).send(msg)
    e501 = (msg) -> res.status(501).send(msg)
    return e400 "Missing data" unless data = req.body.data
    return e400 "Missing context" unless context =req.body.context
    console.log('custom post',{context,data,custom})
    return e501 "No register module" unless custom
    custom.post argv, data, (err, status) ->
      return e400 status if err
      res.status(200).send(status)

  app.get '/plugin/register/custom', farm, (req, res) ->
    e400 = (msg) -> res.status(400).send(msg)
    e501 = (msg) -> res.status(501).send(msg)
    return e501 "No register module" unless custom
    custom.get argv, req, (err,status) ->
      return e400 err if err
      res.status(200).send(status)

module.exports = {startServer}
