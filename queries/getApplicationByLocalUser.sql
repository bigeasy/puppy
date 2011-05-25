SELECT app.id as "application__id",
       app.isHome as "application__isHome",
       app.created as "application__created",
       app.modified as "application__modified",
       acc.id as "application__account__id",
       acc.created as "application__account__email",
       acc.created as "application__account__sshKey",
       acc.created as "application__account__created",
       acc.modified as "application__account__modified"
  FROM Application AS app
  JOIN Account AS acc ON app.accountId = acc.id
  JOIN ApplicationLocalUser AS alu ON app.id = alu.applicationId
  JOIN Machine AS m ON alu.machineId = m.id
 WHERE m.hostname = $1 AND alu.localUserId = $2
