CREATE OR REFRESH STREAMING TABLE bronze_quakes AS
SELECT explode(features) AS f, current_timestamp() AS ingest_ts
FROM STREAM read_files('/Volumes/quake_agent/raw/landing/',
                       format => 'json', multiLine => true);

CREATE OR REFRESH STREAMING TABLE silver_quakes (
  CONSTRAINT valid_mag EXPECT (magnitude IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_geo EXPECT (latitude BETWEEN -90 AND 90
                           AND longitude BETWEEN -180 AND 180) ON VIOLATION DROP ROW
) AS
SELECT f.id AS event_id, f.properties.mag AS magnitude, f.properties.place AS place,
       timestamp_millis(f.properties.time) AS event_time,
       timestamp_millis(f.properties.updated) AS updated_time,
       f.properties.tsunami AS tsunami_flag, f.properties.alert AS pager_alert,
       f.geometry.coordinates[0] AS longitude, f.geometry.coordinates[1] AS latitude,
       f.geometry.coordinates[2] AS depth_km
FROM STREAM bronze_quakes;

CREATE OR REFRESH MATERIALIZED VIEW gold_latest_quakes AS
SELECT * FROM silver_quakes
QUALIFY row_number() OVER (PARTITION BY event_id ORDER BY updated_time DESC) = 1;

CREATE OR REFRESH MATERIALIZED VIEW gold_region_activity AS
SELECT coalesce(nullif(regexp_extract(place, ',\\s*(.*)$', 1), ''), place) AS region,
       count(*) AS quake_count, max(magnitude) AS max_magnitude,
       avg(magnitude) AS avg_magnitude, max(event_time) AS last_event
FROM gold_latest_quakes GROUP BY 1;
