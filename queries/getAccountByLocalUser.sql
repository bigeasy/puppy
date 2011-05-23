SELECT acc.id AS "account__id",
       acc.email AS "account__email",
       acc.sshKey AS "account__sshKey",
       acc.created AS "account__created",
       acc.modified AS "account__modified"
  FROM Machine AS m
  JOIN ApplicationLocalUser AS alu ON alu.machineId = m.id
  JOIN Application AS app ON alu.applicationId = app.id
  JOIN Account AS acc ON app.accountId = acc.id
 WHERE m.hostname = $1 AND alu.localUserId = $2
