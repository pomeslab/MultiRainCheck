# Trap To Kill All Background Tasks On Exit
# trap "killall background" INT TERM EXIT
# Clear logtemp database if scrpit is exited, terminated, interrupted
# trap "heroku pg:psql DATABASE_URL --app nodejspsql -c 'DELETE FROM logtemp'" EXIT TERM INT

# Current Directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Heroku Database
export DATABASE_URL='yourserveraddressgoeshere'

echo "Database: $DATABASE_URL"

# Set Time Interval (First Argument or default of 30 mins)
min_interval=${1:-30}
echo "Collecting Data at an interval of $min_interval minutes"

# Create Tables
psql $DATABASE_URL -c "
  -- Create log24h Table
  CREATE TABLE IF NOT EXISTS log24h (
  login text,
  rc integer, rj integer,
  qc integer, qj integer,
  hc integer, hj integer,
  cluster text,
  D date, T time
  );

  -- Create log31d Table
  CREATE TABLE IF NOT EXISTS log31d (
  login text,
  rc integer, rj integer,
  qc integer, qj integer,
  hc integer, hj integer,
  cluster text,
  D date, pts integer
  );

  -- Create log60m Table
  CREATE TABLE IF NOT EXISTS log60m (
  login text,
  rc integer, rj integer,
  qc integer, qj integer,
  hc integer, hj integer,
  cluster text,
  D date, pts integer
  );

  -- Create logtemp Table
  CREATE TABLE IF NOT EXISTS logtemp (
  login text,
  rc integer, rj integer,
  qc integer, qj integer,
  hc integer, hj integer,
  cluster text,
  D date, T time
  );
"

# Infinite Loop for Updates
# while true; do
while true; do
    # Remove previous log file (make sure only new data is uploaded)
    if [ -e $DIR/log ]; then
      rm -r $DIR/log
    fi

    # Execute main script to obtain data
    # ('log' is the output if connection is successful)
    $DIR/main.sh

    # Check if log file exists
    if [ -e $DIR/log ]; then
        psql $DATABASE_URL -c "

        -- Clear temporary log table (used for head data)
        DELETE FROM logtemp;

        -- Insert rows into log table
        INSERT INTO logtemp VALUES $(cat $DIR/log);

        -- Body of the Code: add rows, update averages, filter data
        $(cat $DIR/query.sql)
      "
    fi

    # Wait X seconds before iterating again:
    # Heroku calculations: minimum of 7 minute sleep time for hobby-dev database
    # 15 minutes = 15*60 = 900
    echo "Next Update: $(date --date="$min_interval  minutes")"
    sleep $(($min_interval * 60))
done
