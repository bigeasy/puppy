SELECT COALESCE(MAX(port) + 1, 9000) AS nextLocalPort
  FROM LocalPort
 WHERE machineId = ?
