request = require("request")
qs = require("querystring")

input = (callback) ->
  data = []
  process.stdin.resume()
  process.stdin.setEncoding('utf8')
  process.stdin.on "data", (chunk) -> data.push chunk
  process.stdin.on "end", -> callback(null, data.join(""))
  process.stdin.on "error", (error) -> callback(error)

checkError = (response, message) ->
  switch Math.floor(response.statusCode / 100)
    when 4, 5
      throw new Error message

dlv = (_) ->
  [ password, key ] = input(_).split /\n/
  domain = /^(.*?)\.\s/.exec(key)[1]
  response = request "https://dlv.isc.org/session/new", _
  match = /window._auth_token = "([^"]+)"/.exec response.body
  if not match
    throw new Error "Cannot find authenticity token."
  authenticity_token = match[1]
  options =
    url: "https://dlv.isc.org/session"
    method: "POST"
    followRedirects: true
    maxRedirects: 11
    body: qs.stringify
      authenticity_token: authenticity_token
      "session[login]": "alan"
      "session[password]": password

  response = request options, _
  checkError response, "Unable to login."
  response = request "https://dlv.isc.org/", _
  match = /<a href="\/users\/(\d+)\/zones">Manage Zones<\/a>/.exec response.body
  if not match
    throw new Error "Cannot determine user."
  user = match[1]
  response = request "https://dlv.isc.org/users/#{user}/zones", _
  for line in response.body.split /\n/
    if match = /<a href="\/zones\/(\d+)".*wish to delete ([^?]+)\?/.exec line
      if match[2] is domain
        zone = match[1]
  options =
    url: "https://dlv.isc.org/zones/#{zone}/dnskeys"
    method: "POST"
    body: qs.stringify
      authenticity_token: authenticity_token
      "dnskey[record]": key
  response = request options, _
  checkError response, "Unable to post key."
  response = request "https://dlv.isc.org/zones/#{zone}", _
  match = /0 IN TXT &quot;(.*?)&quot;/.exec response.body
  if not match
    throw Error "Cannot find TXT record."
  process.stdout.write "#{match[1]}\n"

dlv (error) -> throw error if error
