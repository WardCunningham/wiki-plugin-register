# register plugin, server-side component
# These handlers are launched with the wiki server. 

fs = require 'fs'
path = require 'path'
lookup = require 'dns-lookup'

startServer = (params) ->
  app = params.app
  argv = params.argv

  admin = (req, res, next) ->
    if app.securityhandler.isAdmin(req)
      next()
    else
      a = "no admin specified" unless argv.admin
      u = "not logged in" unless req.session?.passport?.user || req.session?.email || req.session?.friend
      res.status(403).send "Must be admin user, #{a||u}"

  app.post '/plugin/register/new', admin, (req, res) ->
    e400 = (msg) -> res.status(400).send(msg)
    e409 = (msg) -> res.status(409).send(msg)
    e500 = (msg) -> res.status(500).send(msg)
    return e400 "Missing data" unless data = req.body.data
    return e400 "Missing context" unless context =req.body.context
    return e409 "Can't route www subdomain" if data.domain == 'www'

    [site,port] = context.site.split ':'
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

              fs.readFile "#{argv.status}/favicon.png", 'binary', (err, flag) ->
                return e500 "#{err}" if err

                fs.writeFile "#{wantPath}/status/favicon.png", flag, 'binary', (err) ->
                  return e500 "#(err)" if err

                  got = want + if port then ":#{port}" else ''
                  res.setHeader 'Content-Type', 'application/json'
                  res.send JSON.stringify {status: 'ok', site: got}

  app.get '/plugin/register/needs', (req, res) ->
    res.json({need: ["name", "code"], want: ["domain"]})

  app.post '/plugin/register/has', (req, res) ->
    console.log(req.body)
    res.send({status: 'ok'})


module.exports = {startServer}
