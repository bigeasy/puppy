SELECT m.id AS "machine__id",
       m.hostname AS "machine__hostname",
       (SELECT COUNT(*) FROM LocalUser WHERE machineId = m.id AND policy) AS "machine__localUsers",
       (SELECT COUNT(*)
          FROM LocalUser AS lu
          JOIN ApplicationLocalUser AS alu ON lu.machineId = alu.machineId AND alu.localUserId = lu.id
          WHERE lu.machineId = m.id AND lu.policy
          ) AS "machine__localUsersInUse",
       m.modified AS "machine__modified",
       m.created AS "machine__created"
  FROM Machine AS m
