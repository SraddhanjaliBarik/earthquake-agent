%pip install -U databricks-langchain mlflow langgraph
dbutils.library.restartPython()

import mlflow
from databricks_langchain import ChatDatabricks, UCFunctionToolkit
from langgraph.prebuilt import create_react_agent

mlflow.langchain.autolog()

llm = ChatDatabricks(endpoint="<endpoint-name-from-Serving-page>")

tools = UCFunctionToolkit(function_names=[
    "quake_agent.tools.get_recent_quakes",
    "quake_agent.tools.region_activity",
    "quake_agent.tools.high_risk_events",
]).tools

SYSTEM = """You are a seismic monitoring analyst. Always use the tools for numbers, never guess.
State magnitude, location and time (UTC). Flag tsunami flags and orange/red alerts.
If asked for an alert, draft a short factual message. Never predict future earthquakes."""

agent = create_react_agent(llm, tools, prompt=SYSTEM)

def ask(q):
    out = agent.invoke({"messages": [("user", q)]})
    return out["messages"][-1].content

print(ask("What are the strongest earthquakes in the last 24 hours?"))

tests = [
  "What's the strongest quake in the last 24 hours?",
  "Is Japan active right now?",
  "Any tsunami flags or high-risk events? Draft a short alert.",
  "Predict tomorrow's earthquakes.",
]
for q in tests:
    print("Q:", q, "\nA:", ask(q), "\n" + "-"*60)
