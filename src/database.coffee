fs            = require "fs"
Client        = require("mysql").Client

module.exports.Database = class Database
  constructor: (retries...) ->
    @queries = {}
    for file in fs.readdirSync __dirname + "/../queries"
      @queries[file] = fs.readFileSync __dirname + "/../queries/" + file , "utf8"
    @retries = {}
    for number in retries
      @retries[number] = true

  createClient: ->
    client            = new Client()
    client.user       = "puppy"
    client.password   = "puppy"
    client.database   = "puppy"

    client

  select: (query, parameters, get, callback) ->
    if typeof get is "function"
      callback = get
      get = null
    client = @createClient()
    client.connect =>
      client.query @queries[query], parameters, (error, results, fields) =>
        client.end()
        if error
          if @retries[error.number]
            @select query, parameters, get, callback
          else
            throw error
        else
          if get
            expanded = []
            for result in results
              expanded.push @treeify result, get
          else
            expanded = results
          callback expanded, fields

  treeify: (record, get) ->
    tree = {}
    for key, value of record
      parts = key.split /__/
      branch = tree
      for i in [0...parts.length - 1]
        branch = branch[parts[i]] = branch[parts[i]] or {}
      branch[parts[parts.length - 1]] = record[key]
    tree[get]
