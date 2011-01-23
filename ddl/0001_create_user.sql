CREATE TABLE Activation (
    code            VARCHAR(32) NOT NULL,
    email           VARCHAR(255) NOT NULL,
    sshKey          TEXT,
    activated       INTEGER NOT NULL,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (code)
)
\g
CREATE UNIQUE INDEX Activation_Email ON Activation(email)
\g
CREATE TABLE Account (
    id              INTEGER NOT NULL AUTO_INCREMENT,
    email           VARCHAR(255) NOT NULL,
    sshKey          TEXT,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (id)
)
\g
CREATE TABLE Application (
    id              INTEGER NOT NULL AUTO_INCREMENT,
    accountId       INTEGER NOT NULL,
    isHome          INTEGER NOT NULL,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (id)
)
\g
CREATE TABLE ApplicationLocalUser (
    id              INTEGER NOT NULL AUTO_INCREMENT,
    machineId       INTEGER NOT NULL,
    localUserId     INTEGER NOT NULL,
    applicationId   INTEGER NOT NULL,
    status          INTEGER NOT NULL DEFAULT 0,
    modified        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP NOT NULL DEFAULT 0,
    PRIMARY KEY (id)
)
\g
CREATE UNIQUE INDEX ApplicationLocalUser_LocalUser ON ApplicationLocalUser(machineId, localUserId)
\g
CREATE INDEX ApplicationLocalUser_ApplicationId ON ApplicationLocalUser(applicationId)
\g
CREATE TABLE ActivationLocalUser (
    machineId       INTEGER NOT NULL,
    localUserId     INTEGER NOT NULL,
    code            VARCHAR(32) NOT NULL,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (machineId, localUserId)
)
\g
CREATE UNIQUE INDEX ActivationLocalUser_Code ON ActivationLocalUser(code)
\g
CREATE TABLE LocalUserLocalPort (
    id              INTEGER NOT NULL AUTO_INCREMENT,
    machineId       INTEGER NOT NULL,
    localUserId     INTEGER NOT NULL,
    port            INTEGER NOT NULL,
    service         INTEGER NOT NULL,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (id)
)
\g
CREATE UNIQUE INDEX LocalUserLocalPort_LocalPort ON LocalUserLocalPort(machineId, port)
\g
CREATE INDEX LocalUserLocalPort_LocalUser ON LocalUserLocalPort(machineId, localUserId)
\g
CREATE TABLE Machine (
    id              INTEGER NOT NULL AUTO_INCREMENT,
    hostname        VARCHAR(255) NOT NULL,
    ip              VARCHAR(32) NOT NULL,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (id)
)
\g
CREATE TABLE LocalUser (
    machineId       INTEGER NOT NULL,
    id              INTEGER NOT NULL,
    policy          INTEGER NOT NULL DEFAULT 0,
    ready           INTEGER NOT NULL DEFAULT 0,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (machineId, id)
)
\g
CREATE TABLE LocalPort (
    machineId       INTEGER NOT NULL,
    port            INTEGER NOT NULL,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (machineId, port)
)
\g
CREATE TABLE Hostname (
    id              INTEGER NOT NULL AUTO_INCREMENT,
    machineId       INTEGER NOT NULL,
    port            INTEGER NOT NULL,
    hostname        VARCHAR(255) NOT NULL,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (id),
    FOREIGN KEY (machineId, port) REFERENCES LocalPort (machineId, port)
)
\g
CREATE TABLE ReservedPort (
    port INTEGER NOT NULL,
    PRIMARY KEY (port)
)
\g
CREATE TABLE DataServer (
    id              INTEGER NOT NULL AUTO_INCREMENT,
    engine          VARCHAR(32),
    hostname        VARCHAR(2048),
    port            INTEGER,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (id)
)
\g
CREATE TABLE DataStore (
    id              INTEGER NOT NULL AUTO_INCREMENT,
    applicationId   INTEGER NOT NULL,
    dataServerId    INTEGER NOT NULL,
    password        VARCHAR(32),
    name            VARCHAR(256),
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (id),
    FOREIGN KEY (dataServerId) REFERENCES DataServer (id),
    FOREIGN KEY (applicationId) REFERENCES Application (id)
)
\g
CREATE TABLE Job (
    id              INTEGER NOT NULL AUTO_INCREMENT,
    machineId       INTEGER NOT NULL,
    command         TEXT,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (id),
    FOREIGN KEY (machineId) REFERENCES Machine (id)
)
\g
