INSERT INTO Account (email, sshKey)
VALUES ($1, $2)
RETURNING id
