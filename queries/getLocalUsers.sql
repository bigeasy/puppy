SELECT lu.machineId AS "localUser__machineId",
       lu.id AS "localUser__id",
       lu.ready AS "localUser__ready",
       lu.policy AS "localUser__policy",
       lu.modified AS "localUser__modified",
       lu.created AS "localUser__created",
       m.id AS "localUser__machine__id",
       m.hostname AS "localUser__machine__hostname",
       m.modified AS "localUser__machine__modified",
       m.created AS "localUser__machine__created"
  FROM LocalUser AS lu
  JOIN Machine AS m ON lu.machineId = m.id
 WHERE m.id = $1
   AND lu.id >= $2 AND lu.id < $3
