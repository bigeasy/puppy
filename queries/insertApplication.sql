INSERT INTO Application(accountId, isHome)
VALUES($1, $2)
RETURNING id
