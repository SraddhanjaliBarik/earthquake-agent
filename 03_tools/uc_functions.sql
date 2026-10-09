CREATE OR REPLACE FUNCTION quake_agent.tools.get_recent_quakes(min_mag DOUBLE, hours_back INT)
RETURNS TABLE (event_id STRING, magnitude DOUBLE, place STRING, event_time TIMESTAMP,
               depth_km DOUBLE, tsunami_flag INT, pager_alert STRING)
COMMENT 'Earthquakes at or above min_mag in the last hours_back hours, strongest first.'
RETURN SELECT event_id, magnitude, place, event_time, depth_km, tsunami_flag, pager_alert
       FROM quake_agent.pipeline.gold_latest_quakes
       WHERE magnitude >= min_mag
         AND event_time >= current_timestamp() - make_interval(0,0,0,0,hours_back,0,0)
       ORDER BY magnitude DESC LIMIT 25;

CREATE OR REPLACE FUNCTION quake_agent.tools.region_activity(region_text STRING)
RETURNS TABLE (region STRING, quake_count BIGINT, max_magnitude DOUBLE,
               avg_magnitude DOUBLE, last_event TIMESTAMP)
COMMENT 'Activity summary for regions matching region_text, e.g. Japan, Alaska, Chile.'
RETURN SELECT * FROM quake_agent.pipeline.gold_region_activity
       WHERE lower(region) LIKE concat('%', lower(region_text), '%');

CREATE OR REPLACE FUNCTION quake_agent.tools.high_risk_events()
RETURNS TABLE (event_id STRING, magnitude DOUBLE, place STRING, event_time TIMESTAMP,
               tsunami_flag INT, pager_alert STRING)
COMMENT 'Events with magnitude >= 6, a tsunami flag, or an orange/red PAGER alert.'
RETURN SELECT event_id, magnitude, place, event_time, tsunami_flag, pager_alert
       FROM quake_agent.pipeline.gold_latest_quakes
       WHERE magnitude >= 6 OR tsunami_flag = 1 OR pager_alert IN ('orange','red')
       ORDER BY event_time DESC LIMIT 20;
