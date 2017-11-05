# register plugin, server-side component
# These handlers are launched with the wiki server. 

startServer = (params) ->
  app = params.app
  argv = params.argv

  app.post '/plugin/register/new', (req, res) ->
    console.log req.body
    res.json {status: 'ok'}

module.exports = {startServer}
