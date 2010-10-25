CREATE TABLE Account (
    id          INTEGER NOT NULL AUTO_INCREMENT,
    email       VARCHAR(255) NOT NULL,
    sshKey      TEXT,
    modified    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created     TIMESTAMP DEFAULT 0,
    PRIMARY KEY (id)
)
\g
CREATE TABLE Invitation (
    id          INTEGER NOT NULL AUTO_INCREMENT,
    email       VARCHAR(255) NOT NULL,
    sshKey      TEXT,
    modified    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created     TIMESTAMP DEFAULT 0,
    PRIMARY KEY (id)
)
\g
CREATE TABLE Application (
    id          INTEGER NOT NULL AUTO_INCREMENT,
    accountId   INTEGER NOT NULL,
    inUse       INTEGER NOT NULL,
    modified    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created     TIMESTAMP DEFAULT 0,
    PRIMARY KEY (id)
)
\g
CREATE TABLE ApplicationLocalUser (
    applicationId   INTEGER NOT NULL,
    machineId       INTEGER NOT NULL,
    localUserId     INTEGER NOT NULL,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (applicationId, machineId, localUserId)
)
\g
CREATE TABLE ApplicationLocalPort (
    applicationId   INTEGER NOT NULL,
    machineId       INTEGER NOT NULL,
    localUserId     INTEGER NOT NULL,
    port            INTEGER NOT NULL,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (applicationId, machineId, localUserId, port)
)
\g
CREATE TABLE Machine (
    id              INTEGER NOT NULL AUTO_INCREMENT,
    hostname        VARCHAR(255) NOT NULL,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (id)
)
\g
CREATE TABLE LocalUser (
    machineId       INTEGER NOT NULL,
    id              INTEGER NOT NULL,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (machineId, id)
)
\g
CREATE TABLE LocalPort (
    machineId       INTEGER NOT NULL,
    localUserId     INTEGER NOT NULL,
    port            INTEGER NOT NULL,
    modified        TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    created         TIMESTAMP DEFAULT 0,
    PRIMARY KEY (machineId, localUserId, port)
)
\g
