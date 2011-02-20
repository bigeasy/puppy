SELECT lu.machineId AS localUser__machineId,
       lu.id AS localUser__id,
       lu.modified AS localUser_modified,
       lu.created AS localUser_created,
       m.id AS localUser__machine__id,
       m.hostname AS localUser__machine__hostname,
       m.modified AS localUser__machine__modified,
       m.created AS localUser__machine__created,
       app.id AS localUser__application__id,
       app.created AS localUser__application__created,
       app.modified AS localUser__application__modified,
       acc.id AS localUser__application__account__id,
       acc.email AS localUser__application__account__email,
       acc.ready AS localUser__application__account__ready,
       acc.created AS localUser__application__account__created,
       acc.modified AS localUser__application__account__modified
  FROM LocalUser AS lu
  JOIN Machine AS m ON lu.machineId = m.id
  JOIN ActivationLocalUser AS aclu ON aclu.machineId = lu.machineId AND aclu.localUserId = lu.id
  JOIN Activation AS act ON aclu.code = act.code
  JOIN ApplicationLocalUser AS alu ON alu.machineId = lu.machineId AND alu.localUserId = lu.id
  JOIN Application AS app ON alu.applicationId = app.id
  JOIN Account AS acc ON app.accountId = acc.id
 WHERE act.email = ? AND act.activated = 0
