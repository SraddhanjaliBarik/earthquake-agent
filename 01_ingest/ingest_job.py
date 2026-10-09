import requests
URL = "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_hour.geojson"
try:
    print("OK", len(requests.get(URL, timeout=20).json()["features"]))
except Exception as e:
    print("BLOCKED:", e)

import datetime, time
PATH = "/Volumes/earthquake_agent/raw/landing"
end = time.time() + 10*60
while time.time() < end:
    try:
        r = requests.get(URL, timeout=30); r.raise_for_status()
        ts = datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%S")
        dbutils.fs.put(f"{PATH}/quakes_{ts}.json", r.text, True)
    except Exception as e:
        print("failed:", e)
    time.sleep(60)

files = dbutils.fs.ls("/Volumes/earthquake_agent/raw/landing")
print(len(files), "files")
for f in files[-5:]:
    print(f.name, f.size)
