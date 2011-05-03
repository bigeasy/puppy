#!/opt/bin/node

(function () {
  var paths = require.paths;
  var valid = paths[0] == "/opt/lib/node_modules" &&
              paths[1] == "/puppy/common/lib/node" &&
              paths[2] == "/puppy/exclusive/lib/node";
  if (!valid) {
    throw new Error("Invalid path: " + paths.join(":"));
  }
})();

