INSERT INTO ActivationLocalUser(
    machineId, localUserId, code
)
SELECT machineId, id, $1
  FROM LocalUser as lu
 -- Select from the local users associated with the activation application
 -- local user.
 WHERE lu.ready = TRUE
   AND (lu.machineId, lu.id) IN (SELECT machineId, localUserId
                                   FROM ApplicationLocalUser
                                  WHERE applicationId = 1)
  -- Exclude those already associated.
   AND NOT EXISTS (SELECT *
                     FROM ActivationLocalUser
                    WHERE machineId = lu.machineId
                      AND localUserId = lu.id)
 -- Must limit. If there are two options available, they will both be inserted,
 -- causing the unique index on the code to assert.
 LIMIT 1
