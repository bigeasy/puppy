INSERT INTO Account (email, sshKey, created)
VALUES ('alan@prettyrobots.com', 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxDVczoBmk3HR8XoZXofBE3KsCoi8BoALJTYDQzn6cFYWdkjvsWy8wciUtdCWmaCq64cGLDvbfKPZ7F0bOSdZjHCOuXL+dXAznsEJguUiyh7nDy3/6Hw9Q+hce7VWm3t7hyVgUUD7VR281ozpOjFxrMw3wkulqmG6qRU7rY1iv2gsr/UWvDF1D3vPsjp6M7+QMYQnE0ZcC1VKRDby/4Xy5izSJHkjXAlZyAfZpykoeplGVi1JSF/SOD+wFWTrO+UigLdpSi6xZmb8QnguwA6fLaqNYdSyDLFBHxzSRZCI+k43Ppr9Emifxp8/suOBMMVuZMidyAeShJsT6cdZenBA4w== alan', CURRENT_TIMESTAMP())
\g
INSERT INTO Application (accountId, inUse, created)
VALUES (1, 0, CURRENT_TIMESTAMP())
\g
INSERT INTO Machine (hostname, created)
VALUES ('portoroz.prettyrobots.com', CURRENT_TIMESTAMP())
\g
