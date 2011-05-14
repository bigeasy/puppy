SELECT COUNT(*) AS "localUserCount"
  FROM LocalUser
 WHERE machineId = $1
   AND id >= $2 AND id < $3
