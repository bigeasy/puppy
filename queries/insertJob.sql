INSERT INTO Job (machineId, command)
SELECT id, $1
  FROM Machine
 WHERE hostname = $2
