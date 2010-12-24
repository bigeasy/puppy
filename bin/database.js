var fs = require("fs");
var password = fs.readFileSync("/home/database/password", "utf8");
process.stdout.write(password);
