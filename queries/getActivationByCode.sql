SELECT code as "activation__code",
       email as "activation__email",
       sshKey as "activation__sshKey",
       activated as "activation__activated",
       created as "activation__created",
       modified as "activation__modified"
  FROM Activation
 WHERE code = $1
