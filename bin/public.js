(function() {
  var body, spawn, stdin, syslog;
  spawn = require("child_process").spawn;
  body = "";
  syslog = new (require("common/syslog").Syslog)({
    tag: "public_proxy",
    pid: true
  });
  stdin = process.openStdin();
  stdin.on("data", function(chunk) {
    body += chunk.toString();
    return body.length > 1024 * 16 ? process.exit(1) : null;
  });
  stdin.on("end", function() {
    var command, public, stderr;
    command = JSON.parse(body);
    if (!/^\/puppy\/bin\/(account_register|account_home)$/.test(command[0])) {
      process.stdout.write("" + (command[0]) + "\n");
      process.exit(1);
    }
    command.unshift("puppy");
    command.unshift("-u");
    stderr = [];
    public = spawn("sudo", command);
    public.stdout.on("data", function(chunk) {
      return process.stdout.write(chunk.toString());
    });
    public.stderr.on("data", function(chunk) {
      return stderr.push(chunk.toString());
    });
    return public.on("exit", function(code) {
      if (code || stderr.length) {
        syslog.send("err", "Recieved unexpected error messages with exit code " + code + ".", {
          stderr: stderr.join(""),
          code: code
        });
      }
      return process.exit(code);
    });
  });
}).call(this);
