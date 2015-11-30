-- Drop tables and views
DROP MATERIALIZED VIEW IF EXISTS cases;
DROP TABLE IF EXISTS collected_cases CASCADE;

-- Create the table to store all the case records collected
CREATE TABLE collected_cases (
  case_number    varchar(20) NOT NULL,
  name           varchar(255) DEFAULT '' NOT NULL,
  date_of_birth  timestamp,
  party_type     varchar(255) DEFAULT '' NOT NULL,
  court          varchar(255) DEFAULT '' NOT NULL,
  case_type      varchar(255) DEFAULT '' NOT NULL,
  case_status    varchar(255) DEFAULT '' NOT NULL,
  filing_date    timestamp,
  case_caption   varchar(500) DEFAULT '' NOT NULL,
  collected_at   timestamp DEFAULT current_timestamp NOT NULL
);

-- Create a view to get the most recent collected case records
CREATE MATERIALIZED VIEW cases
  AS ( SELECT collected_cases.*
       FROM collected_cases
       JOIN ( SELECT case_number, MAX(collected_at)
              FROM collected_cases
              GROUP BY case_number ) c
         ON ( c.case_number = collected_cases.case_number
              AND c.max = collected_cases.collected_at ));

-- Create a function to refresh the case view
CREATE OR REPLACE FUNCTION refresh_cases()
  RETURNS TRIGGER AS $$
  BEGIN
    REFRESH MATERIALIZED VIEW cases;
    RETURN NEW;
  END
  $$ LANGUAGE plpgsql;

-- Create a trigger to refresh the view after each collection
CREATE TRIGGER refresh_cases_trigger
  AFTER insert
  ON collected_cases
  FOR EACH STATEMENT
  EXECUTE PROCEDURE refresh_cases();
