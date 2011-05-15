SELECT m.id AS machine__id,
       m.hostname AS machine__hostname,
       m.modified AS machine__modified,
       m.created AS machine__created
  FROM Machine AS m
 WHERE m.hostname = $1