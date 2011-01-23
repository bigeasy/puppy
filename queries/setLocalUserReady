UPDATE LocalUser
   SET ready = 1
 WHERE machineId = (SELECT id FROM Machine WHERE hostname = ?) AND id = ?
