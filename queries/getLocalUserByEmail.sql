SELECT lu.machineId AS localUser__machineId,
       lu.id AS localUser__id,
       lu.modified AS localUser__modified,
       lu.created AS localUser__created,
       m.id AS localUser__machine__id,
       m.hostname AS localUser__machine__hostname,
       m.modified AS localUser__machine__modified,
       m.created AS localUser__machine__created,
       app.id AS localUser__application__id,
       app.created AS localUser__application__created,
       app.modified AS localUser__application__modified,
       a.id AS localUser__application__account__id,
       a.email AS localUser__application__account__email,
       a.ready AS localUser__application__account__ready,
       a.created AS localUser__application__account__created,
       a.modified AS localUser__application__account__modified
  FROM LocalUser AS lu
  JOIN Machine AS m ON lu.machineId = m.id
  JOIN ApplicationLocalUser AS alu ON alu.machineId = lu.machineId AND alu.localUserId = lu.id
  JOIN Application AS app ON alu.applicationId = app.id
  JOIN Account AS a ON app.accountId = a.id
 WHERE a.email = ? AND app.isHome = 1
