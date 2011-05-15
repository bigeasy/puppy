SELECT ds.id AS dataStore__id,
       ds.applicationId AS dataStore__applicationId,
       ds.dataServerId AS dataStore__dataServerId,
       ds.alias AS dataStore__alias,
       ds.password AS dataStore__password,
       ds.modified AS dataStore__modified,
       ds.created AS dataStore__created,
       s.id AS dataStore__dataServer__id,
       s.engine AS dataStore__dataServer__engine,
       s.hostname AS dataStore__dataServer__hostname,
       s.port AS dataStore__dataServer__port,
       s.modified AS dataStore__dataServer__modified,
       s.created AS dataStore__dataServer__created
  FROM DataStore AS ds
  JOIN DataServer AS s ON ds.dataServerId = s.id
  JOIN ApplicationLocalUser AS alu ON ds.applicationId = alu.applicationId
  JOIN Machine AS m ON alu.machineId = m.id
 WHERE m.hostname = ? AND alu.localUserId = ?