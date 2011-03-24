#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
#!/usr/bin/env node
(function() {
  var OptionParser, createDate, fs, inspect, makeDashes, merge, months, options, parser, readBuffer, readExceptions, readLog, sendOutput, tz, writeExceptions;
  OptionParser = require("coffee-script/lib/optparse").OptionParser;
  tz = require("timezone").tz;
  inspect = require("util").inspect;
  merge = require("coffee-script").helpers.merge;
  fs = require("fs");
  months = {
    Jan: 0,
    Feb: 1,
    Mar: 2,
    Apr: 3,
    May: 4,
    Jun: 5,
    Jul: 6,
    Aug: 7,
    Sep: 8,
    Oct: 9,
    Nov: 10,
    Dec: 11
  };
  createDate = function(year, month, date, hours, minutes, seconds) {
    return new Date(year, month, date, hours, minutes, seconds);
  };
  parser = new OptionParser([["-n", "--lines [COUNT]", "number of lines to display"], ["-o", "--output [FORMAT]", "number of lines to display"]]);
  try {
    options = parser.parse(process.argv.slice(2));
  } catch (e) {
    options.help();
  }
  options.lines || (options.lines = 4);
  options.output || (options.output = "text");
  readExceptions = function(stderr, exceptions) {
    var body, column, exception, file, json, line, location, match, message, method, pid, process, program, snippet, stack, uid, _ref, _ref2;
    stderr = stderr.split("\n");
    stderr.pop();
    stack = [];
    while (stderr.length && (match = /^\s{4}at\s(\S+)\s+\(([^:]+):(\d+):(\d+)\)$/.exec(stderr[stderr.length - 1]) || (match = /^\s{4}at(.*)\s([^:]+):(\d+):(\d+)$/.exec(stderr[stderr.length - 1])))) {
      _ref = match.slice(1), method = _ref[0], file = _ref[1], line = _ref[2], column = _ref[3];
      stack.unshift({
        method: method,
        file: file,
        line: line,
        column: column
      });
      stderr.pop();
    }
    if (stack.length) {
      if (stderr.length >= 4 && stderr[0] === "" && (location = /^(.*):(\d+)$/.exec(stderr[1])) && (column = /^(\s*)\^$/.exec(stderr[3]))) {
        snippet = {
          file: location[1],
          text: stderr[2],
          line: parseInt(location[2], 10),
          column: column[1].length + 1
        };
        stderr = stderr.slice(4);
      }
      json = [];
      if (/^\s{4}}/.test(stderr[stderr.length - 2])) {
        while (!/^\s{4}{$/.test(line = stderr.pop())) {
          json.unshift(line);
        }
        json.unshift(line);
        json = json.join("\n");
        stderr.pop();
      }
      exception = {
        stack: stack
      };
      process = null;
      message = stderr.join("\n -> ");
      if (match = /^Error:\s([\w_]+)\[(\d+)\/(\d+)\]:\s(.*)$/.exec(message)) {
        _ref2 = match.slice(1), program = _ref2[0], pid = _ref2[1], uid = _ref2[2], body = _ref2[3];
        message = "Error: " + body;
        process = {
          pid: parseInt(pid),
          uid: parseInt(uid),
          program: program
        };
      } else {
        exception.message = message;
      }
      exception = {
        message: message,
        stack: stack
      };
      if (json.length) {
        try {
          exception.json = JSON.parse(json);
        } catch (e) {
          exception.json = json;
          exception.jsonInvalid = true;
        }
      }
      if (snippet) {
        exception.location = snippet;
      }
      if (process) {
        exception.process = process;
      }
      exceptions.push(exception);
      if (exception.json && exception.json.stderr) {
        return readExceptions(exception.json.stderr, exceptions);
      }
    }
  };
  readBuffer = function(buffer, end, contents, output, callback) {
    var chunkSize, date, exceptions, host, i, json, line, lines, match, message, offset, pid, program, record, rest, _ref, _ref2, _ref3;
    chunkSize = 1024 * 2;
    offset = end - chunkSize;
    if (offset <= 0) {
      contents = buffer.toString("utf8", 0, end) + contents;
    } else {
      contents = buffer.toString("utf8", offset, end) + contents;
    }
    lines = contents.split(/\n/);
    lines.pop();
    contents = contents.substring(0, lines[0].length + 1);
    lines.shift();
    while (lines.length && output.length < options.lines) {
      line = lines.pop();
      match = /^(\w{3})\s+(\d{1,2})\s(\d{2}):(\d{2}):(\d{2})\s([-_\w\d]+)\s+(.*)$/.exec(line);
      if (!match) {
        continue;
      }
      date = [(new Date()).getFullYear(), months[match[1]]];
      [].splice.apply(date, [2, 4].concat(_ref = (function() {
        var _results;
        _results = [];
        for (i = 2; i <= 5; i++) {
          _results.push(parseInt(match[i], 10));
        }
        return _results;
      })())), _ref;
      date = createDate.apply(null, date);
      _ref2 = match.slice(6, 8), host = _ref2[0], rest = _ref2[1];
      if (match = /^((?:private|public|worker|janitor)[_\w]*)\[(\d+)\]:\s+(.*?)(\s+{.*)?$/.exec(rest)) {
        _ref3 = match.slice(1, 5), program = _ref3[0], pid = _ref3[1], message = _ref3[2], json = _ref3[3];
        record = {
          date: date,
          host: host,
          program: program,
          pid: pid,
          message: message
        };
        if (json) {
          try {
            record.json = JSON.parse(json);
          } catch (e) {
            record.json = json;
            record.jsonInvalid = true;
          }
          if (record.json.stderr) {
            exceptions = [];
            readExceptions(record.json.stderr, exceptions);
            if (exceptions.length > 0) {
              record.exceptions = exceptions;
            }
          }
        }
        output.unshift(record);
      }
    }
    if (offset > 0 && output.length < options.lines) {
      return readBuffer(buffer, offset, contents, output, callback);
    } else {
      return callback();
    }
  };
  readLog = function(fd, buffer, contents, size, output, callback) {
    var position;
    if (size === 0) {
      return callback();
    } else {
      position = buffer.length >= size ? 0 : size - buffer.length;
      return fs.read(fd, buffer, 0, buffer.length, position, function(error, read) {
        return readBuffer(buffer, read, contents, output, function() {
          return readLog(fd, buffer, contents, size - read, output, callback);
        });
      });
    }
  };
  makeDashes = function(prefix, suffix) {
    var dashes, length;
    dashes = new Array((78 - prefix.length) / 2).join(" -");
    if (suffix != null) {
      length = dashes.length - suffix.length - 1;
      if (length % 2) {
        length--;
      }
      dashes = dashes.substring(0, length);
      return "" + prefix + " -" + dashes + " " + suffix;
    } else {
      return "" + prefix + " -" + dashes;
    }
  };
  writeExceptions = function(exceptions, message) {
    var element, exception, json, stderr, stdout, suffix, _i, _len, _ref;
    exception = exceptions.shift();
    if (exception.process) {
      suffix = (function() {
        return "" + this.program + "[" + this.pid + "/" + this.uid + "]";
      }).apply(exception.process);
      process.stdout.write("\n  " + (makeDashes(message, suffix)) + "\n");
    } else {
      process.stdout.write("\n  " + (makeDashes(message)) + "\n");
    }
    if (exception.location) {
      (function() {
        process.stdout.write("  " + this.file + ":" + this.line + ".\n");
        process.stdout.write("  " + this.text + "\n");
        return process.stdout.write("  " + (new Array(this.column).join(" ")) + "^\n");
      }).apply(exception.location);
    }
    process.stdout.write("" + (exception.message.replace(/^([^\S\n]*\S.*)$/mg, "  $1")) + "\n");
    if (exception.json) {
      if (exceptions.length) {
        exception.json.stderr = "v-V-v Nested exception: See below. v-V-v";
      } else if ((exception.json.stderr != null) && exception.json.stderr.length) {
        stderr = exception.json.stderr;
        exception.json.stderr = "v-V-v See below. v-V-v";
      }
      if ((exception.json.stdout != null) && exception.json.stdout.length) {
        stdout = exception.json.stdout;
        exception.json.stdout = "v-V-v See below. v-V-v";
      }
      json = inspect(exception.json, false, 1000).replace(/^([^\S\n]*\S.*)$/mg, "    $1");
      process.stdout.write("" + json + "\n");
    }
    _ref = exception.stack;
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      element = _ref[_i];
      if (element.method) {
        process.stdout.write("    at " + element.method + " (" + element.file + ":" + element.line + ":" + element.column + ")\n");
      } else {
        process.stdout.write("    at " + element.file + ":" + element.line + ":" + element.column + "\n");
      }
    }
    if (exceptions.length) {
      writeExceptions(exceptions, "Nested exception");
    } else if (stderr) {
      process.stdout.write("\n  " + (makeDashes("Output from stderr")) + "\n");
      process.stdout.write(stderr.replace(/^([^\S\n]*\S.*)$/mg, "  $1"));
    }
    if (stdout) {
      process.stdout.write("\n  " + (makeDashes("Output from stdout")) + "\n");
      return process.stdout.write(stdout.replace(/^([^\S\n]*\S.*)$/mg, "  $1"));
    }
  };
  sendOutput = function(output) {
    var dashes, json, prefix, record, separator, stderr, stdout, suffix, _i, _len, _ref, _results;
    switch (options.output) {
      case "raw":
      case "json":
        process.stdout.write(JSON.stringify(output, null, 2));
        return process.stdout.write("\n");
      default:
        separator = "";
        _results = [];
        for (_i = 0, _len = output.length; _i < _len; _i++) {
          record = output[_i];
          process.stdout.write(separator);
          separator = "\n";
          prefix = "" + (tz("%Y/%m/%d %H:%M:%S", record.date)) + " on " + record.host;
          suffix = "" + record.program + "[" + record.pid + "]";
          dashes = new Array(80 - (prefix.length + suffix.length + 1)).join("-");
          process.stdout.write("" + prefix + " " + dashes + " " + suffix + "\n\n");
          process.stdout.write("" + record.message + "\n");
          _ref = [null, null], stderr = _ref[0], stdout = _ref[1];
          if (record.json) {
            if (record.exceptions) {
              record.json.stderr = "v-V-v Uncaught exception: See below. v-V-v";
            } else if ((record.json.stderr != null) && record.json.stderr.length) {
              stderr = record.json.stderr;
              record.json.stderr = "v-V-v  See below. v-V-v";
            }
            if ((record.json.stdout != null) && record.json.stdout.length) {
              stdout = record.json.stderr;
              record.json.stdout = "v-V-v  See below. v-V-v";
            }
            json = inspect(record.json, false, 1000).replace(/^([^\S\n]*\S.*)$/mg, "  $1");
            process.stdout.write("" + json + "\n");
          }
          if (record.exceptions) {
            writeExceptions(record.exceptions, "Uncaught exception");
          } else if (stderr) {
            process.stdout.write("\n  " + (makeDashes("Output from stderr")) + "\n");
            process.stdout.write(stderr.replace(/^([^\S\n]*\S.*)$/mg, "  $1"));
          }
          _results.push(stdout ? (process.stdout.write("\n  " + (makeDashes("Output from stdout")) + "\n"), process.stdout.write(stdout.replace(/^([^\S\n]*\S.*)$/mg, "  $1"))) : void 0);
        }
        return _results;
    }
  };
  fs.open("/var/log/messages", "r", function(error, fd) {
    var buffer;
    if (error) {
      throw error;
    }
    buffer = new Buffer(1024 * 1024 * 64);
    return fs.fstat(fd, function(error, stats) {
      var contents, output;
      if (error) {
        throw error;
      }
      contents = "";
      output = [];
      return readLog(fd, buffer, "", stats.size, output, function() {
        return sendOutput(output);
      });
    });
  });
}).call(this);
