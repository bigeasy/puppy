INSERT INTO Job (machineId, command, created)
SELECT id, ?, CURRENT_TIMESTAMP()
  FROM Machine
 WHERE hostname = ?
