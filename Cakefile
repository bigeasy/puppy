fs              = require("fs")
{exec, spawn}   = require("child_process")
path            = require("path")

compile = (sources, output) ->
  coffee =          spawn "coffee", "-c -o #{output}".split(/\s/).concat(sources)
  coffee.stderr.on  "data", (buffer) -> puts buffer.toString()
  coffee.on         "exit", (status) -> process.exit(1) if status != 0

currentBranch = (callback) ->
  branches =        ""
  git =             spawn "git", [ "branch" ]
  git.stdout.on     "data", (buffer) -> branches += buffer.toString()
  git.stderr.on     "data", (buffer) -> puts buffer.toString()
  git.on            "exit", (status) ->
    process.exit(1) if status != 0
    branch = /\*\s+(.*)/.exec(branches)[1]
    callback(branch)

task "gitignore", "create a .gitignore for node-ec2 based on git branch", ->
  currentBranch (branch) ->
    gitignore = '''
                .gitignore
                .DS_Store
                _site
                **/.DS_Store
                
                '''

    if branch is "gh-pages"
      gitignore += '''
                   lib
                   '''
    else if branch is "client"
      gitignore += '''
                   documentation
                   index.html
                   site/idl.css
                   lib
                   '''
    fs.writeFile(".gitignore", gitignore)

task "docco", "rebuild the CoffeeScript docco documentation.", ->
  exec "rm -rf documentation && docco src/*.coffee && cp -rf docs documentation && rm -r docs", (err) ->
    throw err if err

task "index", "rebuild the Node IDL landing page.", ->
  idl     = require("idl")
  package = JSON.parse fs.readFileSync "package.json", "utf8"
  console.log(package)
  idl.generate "#{package.name}.idl", "index.html"

task "compile", "compile the CoffeeScript into JavaScript", ->
  path.exists "./lib", (exists) ->
    fs.mkdirSync("./lib", 0755) if not exists
    sources = fs.readdirSync("src")
    sources = "src/" + source for source in sources when source.match(/\.coffee$/)
    compile sources, "./lib"

task "clean", "rebuild the CoffeeScript docco documentation.", ->
  currentBranch (branch) ->
    if branch is "client"
      exec "rm -rf documentation lib _site site/idl.css index.html", (err) ->
        throw err if err

task "server", "create a configuration for the server side.", ->
  fs.writeFileSync "./lib/location.js", """
  module.exports.server = true;
  """

task "client", "create a configuration for the client side.", ->
  fs.writeFileSync "./lib/location.js", """
  module.exports.server = false;
  """
