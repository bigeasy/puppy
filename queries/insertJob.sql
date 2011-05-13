INSERT INTO Job (machineId, command)
SELECT id, ?
  FROM Machine
 WHERE hostname = ?
