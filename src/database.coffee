fs = require "fs"
configuration = fs.readFileSync("/home/database/configuration", "utf8").split(/\s+/)
process.stdout.write JSON.stringify
  host: configuration[0]
  password: configuration[1]
