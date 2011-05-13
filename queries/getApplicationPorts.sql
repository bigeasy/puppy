SELECT alp.port AS port__port,
       alp.service AS port__service,
       alp.modified AS port__modified,
       alp.created AS port__created,
       m.id AS port__machine__id,
       m.hostname AS port__machine__hostname,
       m.ip AS port__machine__ip,
       m.modified AS port__machine__modified,
       m.created AS port__machine__created
  FROM ApplicationLocalPort AS alp
  JOIN Machine AS m ON alp.machineId = m.id
 WHERE alp.applicationId = ?
