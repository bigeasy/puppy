CREATE OR REPLACE FUNCTION update_timestamp() RETURNS trigger AS $update_timestamp$
    BEGIN
        NEW.modified := current_timestamp;
        RETURN NEW;
    END;
$update_timestamp$ LANGUAGE plpgsql
\g
CREATE TABLE Activation (
    code            VARCHAR(32) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    sshKey          TEXT,
    activated       BOOLEAN NOT NULL DEFAULT FALSE,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (code)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON Activation
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE UNIQUE INDEX Activation_Email ON Activation(email)
\g
CREATE TABLE Account (
    id              SERIAL NOT NULL,
    email           VARCHAR(255) NOT NULL,
    ready           BOOLEAN NOT NULL DEFAULT FALSE,
    sshKey          TEXT,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON Account
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE TABLE Application (
    id              SERIAL NOT NULL,
    accountId       INTEGER NOT NULL,
    isHome          BOOLEAN NOT NULL,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON Application
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE TABLE ApplicationLocalUser (
    id              SERIAL NOT NULL,
    machineId       INTEGER NOT NULL,
    localUserId     INTEGER NOT NULL,
    applicationId   INTEGER NOT NULL,
    ready           BOOLEAN NOT NULL DEFAULT FALSE,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON ApplicationLocalUser
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE UNIQUE INDEX ApplicationLocalUser_LocalUser ON ApplicationLocalUser(machineId, localUserId)
\g
CREATE INDEX ApplicationLocalUser_ApplicationId ON ApplicationLocalUser(applicationId)
\g
CREATE TABLE ActivationLocalUser (
    machineId       INTEGER NOT NULL,
    localUserId     INTEGER NOT NULL,
    code            VARCHAR(32) NOT NULL,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (machineId, localUserId)
)
\g
CREATE UNIQUE INDEX ActivationLocalUser_Code ON ActivationLocalUser(code)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON ActivationLocalUser
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE TABLE LocalUserLocalPort (
    id              SERIAL NOT NULL,
    machineId       INTEGER NOT NULL,
    localUserId     INTEGER NOT NULL,
    port            INTEGER NOT NULL,
    service         INTEGER NOT NULL,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON LocalUserLocalPort
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE UNIQUE INDEX LocalUserLocalPort_LocalPort ON LocalUserLocalPort(machineId, port)
\g
CREATE INDEX LocalUserLocalPort_LocalUser ON LocalUserLocalPort(machineId, localUserId)
\g
CREATE TABLE Machine (
    id              SERIAL NOT NULL,
    hostname        VARCHAR(255) NOT NULL,
    ip              VARCHAR(32) NOT NULL,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON Machine
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE TABLE LocalUser (
    machineId       INTEGER NOT NULL,
    id              INTEGER NOT NULL,
    policy          BOOLEAN NOT NULL DEFAULT FALSE, -- whether the user had a policy (app), or not (account).
    ready           BOOLEAN NOT NULL DEFAULT FALSE, -- whether the account is ready for use.
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (machineId, id)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON LocalUser
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE TABLE LocalPort (
    machineId       INTEGER NOT NULL,
    port            INTEGER NOT NULL,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (machineId, port)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON LocalPort
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE TABLE Hostname (
    id              SERIAL NOT NULL,
    machineId       INTEGER NOT NULL,
    port            INTEGER NOT NULL,
    hostname        VARCHAR(255) NOT NULL,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (machineId, port) REFERENCES LocalPort (machineId, port)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON Hostname
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE TABLE ReservedPort (
    port INTEGER NOT NULL,
    PRIMARY KEY (port)
)
\g
CREATE TABLE DataServer (
    id              SERIAL NOT NULL,
    engine          VARCHAR(32),
    hostname        VARCHAR(2048),
    port            INTEGER,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON DataServer
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE TABLE DataStore (
    id              SERIAL NOT NULL,
    applicationId   INTEGER NOT NULL,
    dataServerId    INTEGER NOT NULL,
    password        VARCHAR(32),
    alias           VARCHAR(256),
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (dataServerId) REFERENCES DataServer (id),
    FOREIGN KEY (applicationId) REFERENCES Application (id)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON DataStore
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE TABLE Job (
    id              SERIAL NOT NULL,
    machineId       INTEGER NOT NULL,
    command         TEXT,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (machineId) REFERENCES Machine (id)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON DataStore
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE TABLE VirtualHost (
    id              SERIAL NOT NULL,
    name            VARCHAR(512) NOT NULL,
    ip              VARCHAR(32),
    port            INTEGER,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON VirtualHost
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE TABLE Property(
    name            VARCHAR(256) NOT NULL,
    value           TEXT,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (name)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON Property
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
CREATE TABLE Domain(
    id              SERIAL NOT NULL,
    applicationId   INTEGER NOT NULL, 
    name            VARCHAR(512) NOT NULL,
    modified        TIMESTAMP DEFAULT now(),
    created         TIMESTAMP DEFAULT now(),
    PRIMARY KEY (id),
    FOREIGN KEY (applicationId) REFERENCES Application (id)
)
\g
CREATE TRIGGER update_timestamp BEFORE INSERT OR UPDATE ON Domain
FOR EACH ROW EXECUTE PROCEDURE update_timestamp()
\g
