SELECT COALESCE(MAX(id), 10000) + 1 AS "nextLocalUserId"
  FROM LocalUser
 WHERE machineId = $1 AND id < $2
