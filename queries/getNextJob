SELECT j.id AS job__id,
       j.machineId AS job__machineId,
       j.command AS job__command,
       j.modified AS job__modified,
       j.created AS job__created,
       m.id AS job__machine__id,
       m.hostname AS job__machine__hostname,
       m.modified AS job__machine__modified,
       m.created AS job__machine__created
  FROM Job AS j
  JOIN Machine AS m ON m.id = j.machineId
 WHERE m.hostname = ?
 ORDER
    BY j.id
 LIMIT 1
