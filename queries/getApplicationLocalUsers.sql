SELECT lu.machineId AS localUser__machineId,
       lu.id AS localUser__id,
       lu.modified AS localUser__modified,
       lu.created AS localUser__created,
       m.id AS localUser__machine__id,
       m.hostname AS localUser__machine__hostname,
       m.modified AS localUser__machine__modified,
       m.created AS localUser__machine__created,
       app.id AS localUser__application__id,
       app.isHome AS localUser__application__isHome,
       app.modified AS localUser__application__modified,
       app.created AS localUser__application__created,
       acc.id AS localUser__application__account__id,
       acc.email AS localUser__application__account__email,
       acc.sshKey AS localUser__application__account__sshKey,
       acc.created AS localUser__application__account__created,
       acc.modified AS localUser__application__account__modified
  FROM ApplicationLocalUser AS alu
  JOIN Application AS app ON alu.applicationId = app.id
  JOIN LocalUser AS lu ON lu.machineId = alu.machineId AND lu.id = alu.localUserId
  JOIN Machine AS m ON lu.machineId = m.id
  JOIN Account AS acc ON app.accountId = acc.id
 WHERE app.id = ?
 ORDER
    BY lu.machineId, lu.id