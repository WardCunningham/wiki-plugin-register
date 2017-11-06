# register plugin, server-side component
# These handlers are launched with the wiki server. 

lookup = require 'dns-lookup'
fs = require 'fs'

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
    lookup want, (err, ip, family) ->
      return e409 "Can't resolve wildcard #{want}" if err?.code == 'ENOTFOUND'
      return e500 "#{err}" if err

      console.log 'new', argv.d, want

      fs.readFile "#{argv.status}/owner.json", 'utf8', (err, owner) ->
        return e500 "#{err}" if err

        fs.mkdir "#{argv.d}/#{want}", (err) ->
          return e500 "#{err}" if err

          fs.mkdir "#{argv.d}/#{want}/status", (err) ->
            return e500 "#{err}" if err

            fs.writeFile "#{argv.d}/#{want}/status/owner.json", owner, (err) ->
              return e500 "#{err}" if err

              got = want + if port then ":#{port}" else ''
              res.setHeader 'Content-Type', 'application/json'
              res.send JSON.stringify {status: 'ok', site: got}


module.exports = {startServer}
