INSERT INTO DataStore(applicationId, alias, password, dataServerId)
SELECT $1, $2, $3, id
FROM DataServer
WHERE engine = $4
RETURNING id
