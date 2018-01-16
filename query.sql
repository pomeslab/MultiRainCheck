-- Run script in bash via:
--     cat query.sql | heroku pg:psql $DATABASE_URL --app nodejspsql

-- Create TEMPORARY TABLE logtemp
-- (This table wlil only exist during this session/connection)
-- Note: haven't figured out how to import the log file I have locally yet

--CREATE TEMP TABLE logtemp (
--login char(15),
--rc integer, rj integer,
--qc integer, qj integer,
--hc integer, hj integer,
--cluster char(15),
--D date, T time
--);

-- State before running this file: logtemp TABLE is loaded with new rows already

/* 24 Hour Log Table:
Action 1: Insert rows from logtemp (the new rows) into the log24h TABLE
Action 2: Filter out data that has existed for greater than 24 hours
*/

-- Action 1: Insert new rows
INSERT INTO log24h SELECT * FROM logtemp;

-- Action 2: Filter out existing data > 24 hours
DELETE FROM log24h
WHERE d+t < (select now() at TIME ZONE 'America/Toronto' - interval '24 hours');

/* 31 Days Log Table:
Action 1: Conditional Insertion
    If the date of the inserted row is OLD, update the total and pts
    If the date of the inserted row is NEW, insert the rows
        Note: date refers to YYYY-MM-DD in this case
Action 2: Filter out data that has existed for greater than 31 days
*/

-- Action 1: Conditional Insertion (Update then insert new (order matters))
-- For existing (login, cluster, date) rows
UPDATE log31d
SET
    rc = log31d.rc + logtemp.rc,
    rj = log31d.rj + logtemp.rj,
    qc = log31d.qc + logtemp.qc,
    qj = log31d.qj + logtemp.qj,
    hc = log31d.hc + logtemp.hc,
    hj = log31d.hj + logtemp.hj,
    pts = log31d.pts + 1
FROM logtemp
WHERE EXISTS (
  SELECT *
  FROM log31d
  WHERE
    logtemp.login = log31d.login AND
    logtemp.d = log31d.d AND
    logtemp.cluster = log31d.cluster
  );
-- For new (login, cluster, date) rows
INSERT INTO log31d (
  login,
  rc,rj,qc,qj,hc,hj,
  cluster,d, pts)
SELECT
  logtemp.login,
  logtemp.rc,logtemp.rj,logtemp.qc,logtemp.qj,logtemp.hc,logtemp.hj,
  logtemp.cluster,logtemp.d,1
FROM logtemp
WHERE NOT EXISTS(
  SELECT *
  FROM log31d
  WHERE
    logtemp.login = log31d.login AND
    logtemp.d = log31d.d AND
    logtemp.cluster = log31d.cluster
  );

-- Action 2: Filter out existing data > 31 days
DELETE FROM log31d
WHERE d < (select now() at TIME ZONE 'America/Toronto' - interval '31 days');

/* 60 Month (5 year) Log Table:
Action 1: Conditional Insertion
    If the date of the inserted row is NEW, insert the rows
    If the date of the inserted row is OLD, update the toal and pts
        Note: date refers to YYYY-MM in this case
Action 2: Filter out data that has existed for greater than 60 months ( 5 yrs )
*/

-- Action 1: Conditional Insertion (Update then insert new (order matters))
-- For existing (login, cluster, date) rows
UPDATE log60m
SET
    rc = log60m.rc + logtemp.rc,
    rj = log60m.rj + logtemp.rj,
    qc = log60m.qc + logtemp.qc,
    qj = log60m.qj + logtemp.qj,
    hc = log60m.hc + logtemp.hc,
    hj = log60m.hj + logtemp.hj,
    pts = log60m.pts + 1
FROM logtemp
WHERE EXISTS (
  SELECT *
  FROM log60m
  WHERE
    logtemp.login = log60m.login AND
    to_char(logtemp.d,'yyyy-mm') = to_char(log60m.d,'yyyy-mm') AND
    logtemp.cluster = log60m.cluster
  );

-- For new (login, cluster, date) rows
INSERT INTO log60m (
  login,
  rc,rj,qc,qj,hc,hj,
  cluster,d, pts)
SELECT
  logtemp.login,
  logtemp.rc,logtemp.rj,logtemp.qc,logtemp.qj,logtemp.hc,logtemp.hj,
  logtemp.cluster,to_date(to_char(logtemp.d,'YYYY-MM'),'YYYY-MM'),1
FROM logtemp
WHERE NOT EXISTS(
  SELECT *
  FROM log60m
  WHERE
    logtemp.login = log60m.login AND
    to_char(logtemp.d,'yyyy-mm') = to_char(log60m.d,'yyyy-mm') AND
    logtemp.cluster = log60m.cluster
  );

-- Action 2: Filter out existing data > 5 years

DELETE FROM log60m
WHERE d < (select now() at TIME ZONE 'America/Toronto' - interval '5 years');
