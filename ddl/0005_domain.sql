CREATE TABLE Domain(
    id              INTEGER NOT NULL AUTO_INCREMENT,
    applicationId   INTEGER NOT NULL, 
    name            VARCHAR(512) NOT NULL,
    PRIMARY KEY (id),
    FOREIGN KEY (applicationId) REFERENCES Application (id)
)
\g
