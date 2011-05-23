SELECT lu.machineId AS "localUser__machineId",
       lu.id AS "localUser__id",
       lu.modified AS "localUser__modified",
       lu.created AS "localUser__created",
       m.id AS "localUser__machine__id",
       m.hostname AS "localUser__machine__hostname",
       m.ip AS "localUser__machine__ip",
       m.modified AS "localUser__machine__modified",
       m.created AS "localUser__machine__created"
  FROM LocalUser AS lu
  JOIN Machine AS m ON lu.machineId = m.id
  JOIN ApplicationLocalUser AS alu ON alu.machineId = lu.machineId AND alu.localUserId = lu.id
 WHERE alu.id = $1
