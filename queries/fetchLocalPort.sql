-- Insert a local port assocation into the local user local port table selecting
-- from the local ports that are not already in the table.
INSERT INTO LocalUserLocalPort (
    machineId, localUserId, service, port
)
SELECT machineId, $1, $2, port
  FROM LocalPort as lp
 WHERE NOT EXISTS (SELECT *
                     FROM LocalUserLocalPort
                    WHERE machineId = lp.machineId
                      AND port = lp.port)
   AND NOT EXISTS (SELECT * FROM ReservedPort WHERE port = lp.port)
   AND lp.machineId = $3
-- Get only one.
 LIMIT 1
