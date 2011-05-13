SELECT MAX(lu.policy) AS version
  FROM LocalUser AS lu
  JOIN Machine AS m ON lu.machineId = m.id
 WHERE m.hostname = ?
