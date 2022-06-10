SELECT client_addr AS client, usename AS "user", application_name AS name, state, sync_state AS mode,
(pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) / 1024)::int as pending,
(pg_wal_lsn_diff(sent_lsn, write_lsn) / 1024)::int as write,
(pg_wal_lsn_diff(write_lsn,flush_lsn) / 1024)::int as flush,
(pg_wal_lsn_diff(flush_lsn,replay_lsn) / 1024)::int as replay,
(pg_wal_lsn_diff(pg_current_wal_lsn(),replay_lsn))::int / 1024 as total_lag
FROM pg_stat_replication;


select name, setting, setting::int * 16 || 'MB' AS setting_in_mb
from pg_settings
where name in ('min_wal_size', 'max_wal_size');


SHOW server_version;

\c - postgres
SELECT type, database, user_name, auth_method FROM pg_hba_file_rules();

CREATE DATABASE db1;
\c db1;
CREATE TABLE t(
    id integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    s text
);
INSERT INTO t(s) VALUES ('Привет, мир!'), (''), (NULL);

COPY t TO stdout;
COPY t TO stdout WITH (NULL '<NULL>', DELIMITER ',');
COPY (SELECT * FROM t WHERE s IS NOT NULL) TO stdout;
COPY t TO stdout WITH (FORMAT CSV);
TRUNCATE TABLE t;
 \pset null '\\N'


