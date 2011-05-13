SELECT COUNT(*) AS localUserCount
  FROM LocalUser
 WHERE machineId = ?
   AND id >= ? AND id < ?
