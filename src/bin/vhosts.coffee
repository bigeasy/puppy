http      = require "http"
url       = require "url"

require("exclusive").createSystem __filename, (system) ->
  syslog = system.syslog
  argv = process.argv.slice 2

  vhosts = {}
  max = 0
  queryHosts = ->
    system.sql "getVirtualHosts", [ max ], "host", (hosts) ->
      count = 0
      for host in hosts
        vhosts[host.name] = "#{host.ip}:#{host.port}"
        max = host.id
        count++
      if count
        console.log("LOGGING!")
        syslog.send("local5", "info", "Added #{count} virtual hosts, max host #{max}.")

  queryHosts()
  setInterval queryHosts, 1000

  port = parseInt(argv.shift() || "8080", 10)

  server = http.createServer (request, response) ->
    query = url.parse(request.url)
    # The request has the host in URL. Does this matter?
    host = query.host or request.headers.host or ""
    nameAndPort = /(.*)(?::\d+)$/.exec(host)
    vhost = vhosts[if nameAndPort then nameAndPort[1] else host]
    if not vhost
      response.writeHead 400, { "Content-Type": "text/plain" }
      response.end "Bad request for host #{host}."

    # We have a proxy, so create a proxy and invoke it.
    else
      [ hostname, port ] = vhost.split /:/
      proxy = http.createClient parseInt(port, 10), hostname
      forward = proxy.request request.method, request.url, request.headers
      proxy.addListener "error", (error) ->
        if error.errno is process.ECONNREFUSED
          console.log error
      forward.addListener "response", (backward) ->
        response.writeHead backward.statusCode, backward.headers
        backward.addListener "data", (chunk) -> response.write chunk
        backward.addListener "end", () -> response.end()
      request.addListener "data", (chunk) -> forward.write chunk, "binary"
      request.addListener "end", () -> forward.end()

  server.listen port
