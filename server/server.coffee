# register plugin, server-side component
# These handlers are launched with the wiki server. 

lookup = require 'dns-lookup'

startServer = (params) ->
  app = params.app
  argv = params.argv

  app.post '/plugin/register/new', (req, res) ->
    e400 = (msg) -> res.status(400).send(msg)
    e409 = (msg) -> res.status(409).send(msg)
    e500 = (msg) -> res.status(500).send(msg)
    return e400 "Missing data" unless data = req.body.data
    return e400 "Missing context" unless context =req.body.context
    [site,port] = context.site.split ':'
    want = "#{data.domain}.#{site}"
    lookup want, (err, ip, family) ->
      console.log 'lookup', err
      return e409 "Can't resolve wildcard #{want}" if err?.code == 'ENOTFOUND'
      return e500 "#{err}" if err
      e409 "Not ready to create #{want}"

module.exports = {startServer}
