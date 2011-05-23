INSERT INTO Account (email, sshKey, ready)
VALUES ('messages@prettyrobots.com', 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAs73WEWWB4mTg32qWMoqNmrnOQN7ijjj6kloigxtpGPwuozAtqlsCGjh8xyXnvRYJm2BEaVoX5eNG1F2vHXZu2ZUwH8PISMMEXFf4+1NWRJ693Bq99n4mmY3f05spI8sBkVHCmSWwqW3q6aLjh02398tNLvl6rdDbJ6UANNV/7W/haXy7RgeXQwLEJHwFtzSslbjWcmYfebzex2ueFf87kf4GdYccnIJLM1xY0Fd9dmNhIA8HEpCbVE0Up1Rg2jms7WAjuc9qhem0Qo+ayXYZSDzxzVTCpZS7p0zUw6ZtYJfjI/B46HgFeRBm5wk95il+QEA6dzNIZTzhzrS+Na2m8Q== junk', TRUE)
\g
INSERT INTO Application (accountId, isHome)
VALUES (1, TRUE)
\g
INSERT INTO Machine (hostname, ip)
VALUES ('dvor.prettyrobots.com', '127.0.0.1')
\g
INSERT INTO LocalUser(machineId, id)
VALUES (1, 20000)
\g
INSERT INTO ApplicationLocalUser(machineId, localUserId, applicationId)
VALUES(1, 20000, 1)
\g
INSERT INTO ActivationLocalUser(machineId, localUserId, code)
VALUES(1, 20000, '')
\g
INSERT INTO DataServer(engine, hostname, port)
VALUES('postgresql', 'localhost', 5432)
\g
INSERT INTO Property(name, value) VALUES('applicationHost', 'dvor.prettyrobots.com')
\g
