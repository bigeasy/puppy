require("common/private").createSystem __filename, (system) ->
  [ hostname, uid ] = process.argv.slice(2)
  system.sql "getLocalUser", [ hostname, uid ], "localUser", (results) ->
    if results.length is 0
      throw new Error system.err "Cannot find user u#{uid} on #{hostname}."
    localUser = results.shift()
    unless localUser.ready
      system.sql "setLocalUserReady", [ hostname, uid ], (results) ->
        if results.affectedRows is 0
          throw new system.err "Cannot find user u#{uid} on #{hostname}."
