# register plugin, server-side component
# These handlers are launched with the wiki server. 

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
    lookup want, (err, ip, family) ->
      return e409 "Can't resolve wildcard #{want}" if err?.code == 'ENOTFOUND'
      return e500 "#{err}" if err

      e409 "Not ready to create #{want}"

# get admin's owner.json
# create want/status dirs
# write owner.json

module.exports = {startServer}
