http = require "http"
url  = require "url"

port = parseInt(process.argv.shift() || 8080, 10)

vhosts =
  "swimlane.prettyrobots.com": 10001

server = http.createServer (request, response) ->
  console.log request.url
  console.log request.host
  query = url.parse(request.url)
  if query.host
    port = vhosts[query.host]
  else if request.headers.host
    port = vhosts[request.headers.host]
  if not port
    request.sendHeader 400, { "Content-Type": "text/plain" }
    request.end "Bad Request."

  # We have a proxy, so create a proxy and invoke it.
  else
    proxy = http.createClient port, "localhost"
    forward = proxy.request request.method, request.url, request.headers
    forward.addListener "response", (backward) ->
      backward.addListener "data", (chunk) -> response.write chunk
      backward.addListener "end", () -> response.end()
    request.addListener "data", (chunk) -> forward.write chunk, "binary"
    request.addListener "end", () -> forward.end()

server.listen port
