SELECT act.code AS "activation__code",
       act.email AS "activation__email",
       act.sshKey AS "activation__sshKey",
       act.activated AS "activation__activated",
       act.modified AS "activation__modified",
       act.created AS "activation__created"
  FROM Activation AS act
  JOIN ActivationLocalUser AS alu USING (code)
  JOIN Machine AS m ON m.id = alu.machineId
 WHERE m.hostname = $1 AND alu.localUserId = $2 AND NOT act.activated
