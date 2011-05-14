fs = require "fs"
process.stdout.write fs.readFileSync("/home/database/configuration", "utf8")
