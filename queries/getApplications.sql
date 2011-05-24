SELECT a.id as "application__id",
       a.isHome as "application__isHome",
       COALESCE(
        (SELECT alu.ready
           FROM ApplicationLocalUser AS alu
          WHERE alu.applicationId = a.id
          ORDER
             BY alu.id
          LIMIT 1), FALSE) AS "application__ready",
       a.created as "application__created",
       a.modified as "application__modified",
       acc.id as "application__account__id",
       acc.email as "application__account__email",
       acc.sshKey as "application__account__sshKey",
       acc.created as "application__account__created",
       acc.modified as "application__account__modified"
  FROM Application AS a
  JOIN Account AS acc ON a.accountId = acc.id
 WHERE acc.id = $1
   AND NOT a.isHome
