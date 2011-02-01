require.paths.unshift("/puppy/lib/node")

http      = require "http"
url       = require "url"
syslog    = new (require("common/syslog").Syslog)({ tag: "vhosts", pid: true })
db        = require("common/database")

module.exports.command = (argv) ->
  db.createDatabase syslog, (database) ->
    vhosts = {}
    max = 0
    queryHosts = ->
      database.select "getVirtualHosts", [ max ], "host", (hosts) ->
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
      console.log request.url
      console.log url.parse(request.url, true)
      console.log query
      console.log request
      query = url.parse(request.url)
      if query.host
        vhost = vhosts[query.host]
      else if request.headers.host
        vhost = vhosts[request.headers.host]
      if not vhost
        response.writeHeader 400, { "Content-Type": "text/plain" }
        response.end "Bad Request."

      # We have a proxy, so create a proxy and invoke it.
      else
        [ hostname, port ] = vhost.split /:/
        proxy = http.createClient parseInt(port, 10), hostname
        forward = proxy.request request.method, request.url, request.headers
        proxy.addListener "error", (error) ->
          if error.errno is process.ECONNREFUSED
            console.log error
        forward.addListener "response", (backward) ->
          response.writeHeader backward.statusCode, backward.headers
          backward.addListener "data", (chunk) -> response.write chunk
          backward.addListener "end", () -> response.end()
        request.addListener "data", (chunk) -> forward.write chunk, "binary"
        request.addListener "end", () -> forward.end()

    server.listen port

