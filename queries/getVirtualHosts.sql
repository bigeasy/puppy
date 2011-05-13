SELECT v.id AS host__id,
       v.name AS host__name,
       v.ip AS host__ip,
       v.port AS host__port
  FROM VirtualHost AS v
 WHERE id > ?
 ORDER
    BY id
