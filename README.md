# earthquake-agent


Real-Time Earthquake Intelligence Agent (Databricks)

An AI agent that answers plain-English questions about earthquakes happening now. It ingests live USGS data, cleans it through a Bronze → Silver → Gold pipeline, and exposes the results through read-only SQL tools, an AI/BI dashboard, and a Genie space.

What it does
Pulls live earthquake data from the USGS GeoJSON feed
Cleans and deduplicates events with a streaming pipeline and data-quality rules
Lets an LLM agent answer questions by calling governed, read-only SQL functions (no guessing numbers)
Shows live counts, trends, and a world map in a dashboard
Refuses predictions, injected instructions, and write/delete requests

Architecture:
USGS GeoJSON feed
      │  (Python ingest, scheduled)
      ▼
UC Volume: earthquake_agent.raw.landing   (raw JSON files)
      │  Auto Loader
      ▼
Lakeflow pipeline (triggered, scheduled)
  Bronze  ->  Silver (quality rules)  ->  Gold
                                          ├─ gold_latest_quakes
                                          └─ gold_region_activity
      │
      ├──► Unity Catalog SQL functions (agent tools, read-only)
      │         └──► LangGraph agent + Foundation Model endpoint + MLflow tracing
      ├──► AI/BI Dashboard
      └──► Genie space (no-code Q&A)

Tech stack

Auto Loader, Lakeflow Declarative Pipelines, Delta Lake, Unity Catalog (functions), LangGraph, Databricks Foundation Model endpoint, MLflow tracing, AI/BI Dashboards, Genie.

Data
Source: USGS Earthquake GeoJSON feed (updates about every minute)
Feed used: https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson
Credit: U.S. Geological Survey. Please review USGS data-use terms before reuse.


Repo structure

earthquake-agent/
├── README.md
├── 01_ingest/ingest_job.py        # fetches the feed, writes JSON to the Volume
├── 02_pipeline/pipeline.sql       # Bronze/Silver/Gold (runs INSIDE the pipeline)
├── 03_tools/uc_functions.sql      # SQL functions (run in the SQL Editor)
├── 04_agent/agent.py              # LangGraph agent
├── 05_eval/eval_results.md        # test questions and results
└── docs/screenshots/              # dashboard and trace images


Setup
Create catalog, schemas, volume (SQL Editor):
   CREATE CATALOG IF NOT EXISTS earthquake_agent;
   CREATE SCHEMA  IF NOT EXISTS earthquake_agent.raw;
   CREATE SCHEMA  IF NOT EXISTS earthquake_agent.pipeline;
   CREATE SCHEMA  IF NOT EXISTS earthquake_agent.tools;
   CREATE VOLUME  IF NOT EXISTS earthquake_agent.raw.landing;


Ingest: run 01_ingest/ingest_job.py (schedule every 15-30 minutes).
Pipeline: create an ETL pipeline (catalog earthquake_agent, schema pipeline), add 02_pipeline/pipeline.sql, run in triggered mode.
Tools: run each statement in 03_tools/uc_functions.sql in the SQL Editor (functions cannot live inside the pipeline).
Agent: open 04_agent/agent.py in a notebook, set ENDPOINT to a chat model listed on your Serving page, then run.
Dashboard: create datasets from the Gold tables and build the visuals.
Genie: create a Genie space over the two Gold tables.


Security design
Read-only tools: the agent cannot write, delete, or send anything
Least privilege: Unity Catalog grants limited to the schemas and functions needed
Prompt-injection defense: tool output (including USGS text fields) is treated as data, never instructions
Data quality: pipeline expectations drop rows with missing magnitude or invalid coordinates; raw Bronze data is kept for audit
No secrets in the repo: tokens live in environment variables or Databricks secrets only
Auditability: MLflow traces record questions, tool calls, and answers
Human in the loop: the agent drafts alerts; a person decides whether to act

Possible extensions
Slack/Teams alert drafts with human approval
Daily LLM-generated situation report
Multi-hazard data (weather alerts, flights)
Formal evaluation with mlflow.genai.evaluate
Deploy as a serving endpoint and Databricks App on a paid workspace


