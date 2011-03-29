INSERT INTO ApplicationLocalUser(
    applicationId, machineId, localUserId, created
)
SELECT ?, machineId, id, CURRENT_TIMESTAMP()
  FROM LocalUser as lu
 WHERE lu.ready = 1
   AND lu.machineId = ?
   AND lu.policy = ?
   AND NOT EXISTS (SELECT *
                     FROM ApplicationLocalUser
                    WHERE machineId = lu.machineId
                      AND localUserId = lu.id)
 LIMIT 1
