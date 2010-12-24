var spawn = require("child_process").spawn;
var body = "";
var syslog = new (require("common/syslog").Syslog)({ tag: "public_transition", pid: true })

var stdin = process.openStdin();
stdin.on("data", function (chunk) {
  body += chunk.toString()
  if (body.length > 1024 * 16) {
    process.exit(1);
  }
})

stdin.on("end", function () {
  command = JSON.parse(body);

  if (command[0] != "/opt/bin/public") {
    process.stdout.write("#{command[0]}\n");
    process.exit(1);
  }
  
  command.unshift("puppy");
  command.unshift("-u");

  var stderr = []
  public = spawn("sudo", command);
  public.stdout.on("data", function (chunk) { process.stdout.write(chunk.toString()) });
  public.stderr.on("data", function (chunk) { stderr.push(chunk.toString()) });
  public.on("exit", function (code) {
    if (code || stderr.length) {
      syslog.send( "err",
        "Recieved unexpected error messages with exit code #{code}.",
        { stderr: stderr.join(""), code: code });
    }
    process.exit(code);
  })
});
