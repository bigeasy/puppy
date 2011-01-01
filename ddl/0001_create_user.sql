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
CREATE TABLE ApplicationLocalPort (
    id              INTEGER NOT NULL AUTO_INCREMENT,
    machineId       INTEGER NOT NULL,
    port            INTEGER NOT NULL,
    applicationId   INTEGER NOT NULL,
    service         INTEGER NOT NULL,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (id)
)
\g
CREATE UNIQUE INDEX ApplicationLocalPort_LocalPort ON ApplicationLocalPort(machineId, port)
\g
CREATE INDEX ApplicationLocalPort_ApplicationId ON ApplicationLocalPort(applicationId)
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
    status          INTEGER NOT NULL DEFAULT 0,
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