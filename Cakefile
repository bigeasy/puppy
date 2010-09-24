fs              = require("fs")
{exec, spawn}   = require("child_process")
path            = require("path")
idl             = require("idl")

compile = (sources) ->
  coffee =          spawn "coffee", "-c -o lib".split(/\s/).concat(sources)
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
    else if branch is "master"
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
  package = JSON.parse fs.readFileSync "package.json", "utf8"
  console.log(package)
  idl.generate "#{package.name}.idl", "index.html"

task "compile", "compile the CoffeeScript into JavaScript", ->
  path.exists "./lib", (exists) ->
    fs.mkdirSync("./lib", parseInt(755, 8)) if not exists
    sources = fs.readdirSync("src")
    sources = "src/" + source for source in sources when source.match(/\.coffee$/)
    compile sources

task "clean", "rebuild the CoffeeScript docco documentation.", ->
  currentBranch (branch) ->
    if branch is "master"
      exec "rm -rf documentation lib _site site/idl.css index.html", (err) ->
        throw err if err
