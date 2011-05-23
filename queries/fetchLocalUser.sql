INSERT INTO ApplicationLocalUser(
    applicationId, machineId, localUserId
)
SELECT $1, machineId, id
  FROM LocalUser as lu
 WHERE lu.ready
   AND lu.machineId = $2
   AND lu.policy = $3
   AND NOT EXISTS (SELECT *
                     FROM ApplicationLocalUser
                    WHERE machineId = lu.machineId
                      AND localUserId = lu.id)
 LIMIT 1
RETURNING id
