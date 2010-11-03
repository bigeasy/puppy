fs = require "fs"

module.exports =
  command: (file) ->
    file = path.normalize(file)
    match = /^(\/home\/u\d+)\//.exec(file)
    throw new Error("Bad path #{file}") unless match
    home = match[1]
    try
      stat = fs.statSync(home)
    catch e
      if e.errno is process.binding('net').ENOENT
        throw new Error("Home does not exist #{file}") if not stat
      throw e
    body = fs.readFileSync(file, "utf8")
    fs.unlinkSync(file)
    { uid: stat.uid, command: if body then JSON.parse(body) else null }
