var spawn = require("child_process").spawn;
var body = "";

var stdin = process.openStdin();
stdin.on("data", function (chunk) {
  body += chunk.toString()
  if (body.length > 1024 * 16) {
    process.exit(1);
  }
})

stdin.on("end", function () {
  command = JSON.parse(body);

  if (command[0].indexOf("/opt/share/puppy/public/bin") != 0) {
    process.exit(1);
  }
  
  process.stdout.write(command[0] + "\n");
  process.exit(1);

  command.unshift("puppy");
  command.unshift("-u");
  public = spawn("sudo", command);
  public.stdout.on("data", function (chunk) { process.stdout.write(chunk.toString()) });
  public.on("exit", function (code) { process.stdout.write(code); process.exit(code) })
});
