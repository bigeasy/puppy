{OptionParser}  = require "coffee-script/optparse"
fs = require "fs"
format = require("./puppy").format

reattempt = (configuration, attempt) ->
  configuration.reset()
  setAlias(configuration, attempt + 1)

setAlias = (configuration, attempt) ->
  usage = """
  usage: puppy [OPTIONS] db:alias [DATABASE] [ALIAS]

  description:
    Change the alias of database. The alias is meaningful name for the database
    to use in your application in lieu of the auto-generated database id.
    A valid aliases has no whitespace and can contain letters, digits,
    hyphens, underscores and dollar signs.
    
    You can select the database to alias using either the database identifier,
    or the existing alias. When using the existing alias, you must specify the
    application to which the database is assigned.

    example: puppy --app blog db:alias journal diary
    example: puppy db:fetch d3428 storage

    see:     puppy db:fetch
  """

  if configuration.options.arguments.length < 2
    configuration.usage "Required arguments missing.", usage
  else if configuration.options.arguments.length > 2
    configuration.usage "Too many arguments.", usage

  [existing, alias] = configuration.options.arguments

  validAlias = /^[-\d\w_$]+$/
  if /^d\d+/.test(alias)
    configuration.usage "New alias looks too much like a system identifier.", usage
  if not validAlias.test(existing)
    configuration.usage "Invalid characters in database identifier or alias.", usage
  if not validAlias.test(alias)
    configuration.usage "Invalid characters in alias.", usage

  # Async branch below requires this to be pulled out into a function.
  remote = (params) ->
    configuration.private "/puppy/private/bin/db_alias_try", params, (command) ->
      command.assert (stdout) ->
        response = JSON.parse(stdout)
        if response.constraintViolation
            configuration.error "Application t#{params.applicationId} already has a data store with alias \"#{alias}\"."
        else if response.notFound
          if attempt is 0
            reattempt(configuration, attempt)
          else
            configuration.error "No such database \"#{existing}\"."
        else
          switch configuration.output
            when "json"
              process.stdout.write stdout
              process.stdout.write "\n"
            when "list"
              dataStores = [[
                "Account", "AppId", "DatabaseId", "Alias", "Status"
              ]]
              dataStore = response.dataStore
              dataStores.push [
                dataStore.application.account.email
                "t#{dataStore.application.id}"
                "d#{dataStore.id}"
                dataStore.alias
                dataStore.status
              ]
              process.stdout.write format(dataStores)

  if configuration.application.isHome
    if not (match = /^d?(\d+)$/.exec(existing))
      configuration.usage "Invalid database identifier.", usage
    dataStoreId = parseInt match[1], 10
    configuration.applications (applications) ->
      found = false
      for application in applications
        for dataStore in (application.dataStores or [])
          if dataStore.id is dataStoreId
            configuration.application = application
            break
      if not configuration.application.isHome
        remote({ applicationId: configuration.application.id, dataStoreId, alias })
      else if attempt is 0
        reattempt(configuration, attempt)
      else
        configuration.error "No such database \"#{existing}\"."
  else
    found = false
    if match = /^d?(\d+)$/.exec(existing)
      dataStoreId = parseInt match[1], 10
      for dataStore in configuration.application.dataStores
        if dataStore.id is dataStoreId
          found = true
          break
    else
      for dataStore in configuration.application.dataStores
        if dataStore.alias is existing
          dataStoreId = dataStore.id
          found = true
          break
    if found
      remote({ applicationId: configuration.application.id, dataStoreId, alias })
    else if attempt is 0
      reattempt(configuration, attempt)
    else
      configuration.error "No such alias \"#{existing}\" in application."

module.exports.command =
  description: "Change database alias."
  application: true
  account: true
  execute: (configuration) ->
    setAlias(configuration, 0)
