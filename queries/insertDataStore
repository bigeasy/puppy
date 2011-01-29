INSERT INTO DataStore(applicationId, alias, password, dataServerId, created)
SELECT ?, ?, ?, id, CURRENT_TIMESTAMP
FROM DataServer
WHERE engine = ?
