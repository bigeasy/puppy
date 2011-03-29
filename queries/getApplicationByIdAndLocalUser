SELECT a.id as application__id,
       a.isHome as application__isHome,
       a.created as application__created,
       a.modified as application__modified,
       acc.id as application__account__id,
       acc.created as application__account__email,
       acc.created as application__account__sshKey,
       acc.created as application__account__created,
       acc.modified as application__account__modified
  FROM Application AS a
  JOIN Account AS acc ON a.accountId = acc.id
 WHERE a.id = ?
   AND EXISTS(SELECT *
                FROM ApplicationLocalUser AS alu
                JOIN Machine AS m ON alu.machineId = m.id
                JOIN Application AS app ON alu.applicationId = app.id
                JOIN Account AS acc2 ON app.accountId = acc2.id
               WHERE acc.id = acc2.id AND m.hostname = ? AND alu.localUserId = ?)
