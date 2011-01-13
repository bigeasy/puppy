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
