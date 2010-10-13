connect     = require "connect"
url         = require "url"
fs          = require "fs"
Client      = require("mysql").Client
nun         = require "nun"
path        = require "path"

port        = parseInt(process.argv[4] || "8086", 10)
mountPoint  = process.argv[3] || ""
domain      = process.argv[2] || "http://localhost#{if port is 80 then "" else port}"

identifiers =
  id: {}
  directory: {}
  nextIdentifier: 0

getIdentifier = (directory) ->
  id = identifiers.id[directory]
  if not id
    id = identifiers.nextIdentifier++
    identifiers.id[directory] = id
    identifiers.directory[id] = directory
  id


configuration = JSON.parse(fs.readFileSync(__dirname + "/../configuration.js"))
configuration.directory = path.join(configuration.directory, "/")
console.log configuration
getIdentifier(configuration.directory)

createClient = ->
  client            = new Client()
  client.user       = "verity"
  client.password   = "verity"
  client.database   = "verity"

  client

select = (query, parameters, callback) ->
  client = createClient()
  client.connect ->
    client.query query, parameters, (error, results, fields) ->
      throw error if error
      callback results, fields
      client.end()

treeify = (record, get, split) ->
  split or= /__/
  tree = {}
  for key, value of record
    parts = key.split split
    branch = tree
    for i in [0...parts.length - 1]
      branch = branch[parts[i]] = branch[parts[i]] or {}
    branch[parts[parts.length - 1]] = record[key]
  tree[get]

templateMimeType = (template) ->
  switch /\.(\w+)\.nun/.exec(template)[1]
    when "css" then "text/css"
    else "text/html"

sendError = (response, code) ->
  response.writeHead(code, {})
  response.end()

mount = (path) ->
  (configuration.mount or "") + path

fileType = (stat) ->
  if stat.isFile()
    "file"
  else if stat.isDirectory()
    "directory"
  else if stat.isBlockDevice()
    "blockDevice"
  else if stat.isCharacterDevice()
    "characterDevice"
  else if stats.isSymbolicLink()
    "symlink"
  else if stats.isFIFO()
    "fifo"
  else
    "socket"

sendObject = (response, object) ->
  json = JSON.stringify(object)
  response.writeHead 200,
    "Content-Type": "text/plain"
    "Content-Length": json.length
  response.end(json)

dirStat = (directory, files, index, callback) ->
  if index is files.length
    callback(files)
  else
    fs.lstat directory + files[index], (error, stat) ->
      full =  path.join(directory, "/", files[index])
      files[index] =
        data:
          title: files[index]
          attr:
            type: fileType(stat)
        attr: {}
      files[index].state = "closed" if stat.isDirectory()
      full += "/"
      console.log full
      files[index].attr.id = "remoteFileId_#{getIdentifier(full)}"
      dirStat(directory, files, index + 1, callback)

routes = (app) ->
  app.get mount("/editor"), (request, response) ->
    sendTemplate response, "/editor.html.nun", {}
  app.get mount("/directory.json"), (request, response) ->
    query = url.parse(request.url, true).query
    directory = identifiers.directory[query.directory]
    if directory
      fs.readdir directory, (error, files) ->
        dirStat directory, files, 0, (files) ->
          sendObject response, files
    else
      sendError response, 404

sendTemplate = (response, template, model) ->
  model.url = domain + mountPoint
  response.writeHead 200, { "Content-Type": templateMimeType(template) }
  nun.render __dirname + "/../templates/nun" + template, model, {}, (error, output) ->
    throw error if error
    output.on "data", (data) ->
      response.write data
    output.on "end", ->
      response.end ""

provider = connect.staticProvider __dirname + "/../public"
staticProvider = (req, res, next) ->
  actual = req.url
  if req.method is "GET"
    parsed = url.parse actual
    if parsed.pathname.indexOf(mountPoint) == 0
      parsed.pathname = parsed.pathname.substring mountPoint.length
      req.url = url.format parsed

  result = provider req, res, next
  req.url = actual
  result

server = connect.createServer(
  connect.logger(),
  connect.bodyDecoder(),
  connect.router(routes),
  staticProvider
)

module.exports =
  listen: -> server.listen configuration.port
