SELECT lp.machineId AS localPort__machineId,
       lp.port AS localPort__port,
       lp.modified AS localPort__modified,
       lp.created AS localPort__created,
       m.id AS localPort__localUser__machine__id,
       m.hostname AS localPort__localUser__machine__hostname,
       m.modified AS localPort__localUser__machine__modified,
       m.created AS localPort__localUser__machine__created,
       lu.machineId AS localPort__localUser__machineId,
       lu.id AS localPort__localUser__id,
       lu.ready AS localPort__localUser__ready,
       lu.policy AS localPort__localUser__policy,
       lu.modified AS localPort__localUser__modified,
       lu.created AS localPort__localUser__created
  FROM LocalPort AS lp
  JOIN Machine AS m ON lp.machineId = m.id
  JOIN LocalUserLocalPort AS lulp ON lulp.machineId = lp.machineId AND lulp.port = lp.port
  JOIN LocalUser AS lu ON lulp.machineId = lu.machineId AND lulp.localUserId = lu.id
 WHERE m.hostname = ?
