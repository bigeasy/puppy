UPDATE ApplicationLocalUser
   SET ready = 1
 WHERE machineId = (SELECT id FROM Machine WHERE hostname = ?) AND localUserId = ?
