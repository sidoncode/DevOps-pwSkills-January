# ELK Stack on AWS EC2 (Ubuntu) — Step by Step

Set up the **ELK stack** (Elasticsearch + Logstash + Kibana) on an **EC2 Ubuntu
server** to collect logs from a Python app and see them on a dashboard.

Just follow the steps in order.

**How it works:**

```
Python app  →  JSON log file  →  Filebeat  →  Logstash  →  Elasticsearch  →  Kibana dashboard
                        (all running on your EC2 Ubuntu server)
```

---

## Table of Contents

1. [Launch the EC2 instance](#step-1--launch-the-ec2-instance)
2. [Open the right ports](#step-2--open-the-right-ports-security-group)
3. [Connect to the server](#step-3--connect-to-the-server)
4. [Install Docker](#step-4--install-docker)
5. [Set the Elasticsearch kernel setting](#step-5--set-the-elasticsearch-kernel-setting)
6. [Make the project folders](#step-6--make-the-project-folders)
7. [Create the ELK stack file](#step-7--create-the-elk-stack-file)
8. [Configure Logstash](#step-8--configure-logstash)
9. [Configure Filebeat](#step-9--configure-filebeat)
10. [Write the Python app](#step-10--write-the-python-app)
11. [Start ELK](#step-11--start-elk)
12. [Run the Python app](#step-12--run-the-python-app)
13. [Check the logs arrived](#step-13--check-the-logs-arrived)
14. [Open Kibana in your browser](#step-14--open-kibana-in-your-browser)
15. [See your logs](#step-15--see-your-logs)
16. [Make a dashboard](#step-16--make-a-dashboard)
17. [Troubleshooting](#troubleshooting)
18. [Logs vs Metrics — ELK vs Prometheus + Grafana](#logs-vs-metrics--elk-vs-prometheus--grafana)
19. [Important security note](#important-security-note)

---

## Step 1 — Launch the EC2 instance

1. In the AWS console, go to **EC2** → **Launch instance**.
2. **Name:** `elk-server`
3. **OS image:** Ubuntu Server 22.04 (or 24.04) LTS.
4. **Instance type:** at least **t3.large** (2 vCPU, 8 GB RAM). ELK is
   memory-hungry — anything smaller will crash.
5. **Key pair:** create or choose one so you can SSH in.
6. **Storage:** at least **30 GB** (logs add up fast).
7. Click **Launch instance**.

---

## Step 2 — Open the right ports (Security Group)

Edit the instance's **Security Group** and add these inbound rules:

| Type | Port | Source | Why |
|---|---|---|---|
| SSH | 22 | **My IP** | To connect to the server |
| Custom TCP | 5601 | **My IP** | To open Kibana in your browser |

> ⚠️ Set the source to **My IP**, not `0.0.0.0/0`. We turn security off in this
> setup to keep it simple, so only allow your own IP.

---

## Step 3 — Connect to the server

From your computer's terminal (use your key file and the instance's public IP):

```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

Everything from here on runs **on the server**, unless a step says otherwise.

---

## Step 4 — Install Docker

Run these one block at a time:

```bash
# Update the system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com | sudo sh

# Let your user run docker without sudo
sudo usermod -aG docker ubuntu

# Check Docker Compose is available (it's built in)
docker compose version
```

Now log out and back in (`exit`, then SSH again) so the group change takes effect.

---

## Step 5 — Set the Elasticsearch kernel setting

Elasticsearch needs this or it won't start:

```bash
sudo sysctl -w vm.max_map_count=262144

# Make it stick after a reboot
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```

---

## Step 6 — Make the project folders

```bash
mkdir -p ~/elk-python/{logstash,filebeat,app,logs}
cd ~/elk-python
```

---

## Step 7 — Create the ELK stack file

Create the file with `nano docker-compose.yml` and paste this in
(save with `Ctrl+O`, `Enter`, then exit with `Ctrl+X`):

```yaml
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:8.14.1
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms1g -Xmx1g"
    ports:
      - "9200:9200"

  kibana:
    image: docker.elastic.co/kibana/kibana:8.14.1
    environment:
      - ELASTICSEARCH_HOSTS=http://elasticsearch:9200
    ports:
      - "5601:5601"
    depends_on:
      - elasticsearch

  logstash:
    image: docker.elastic.co/logstash/logstash:8.14.1
    volumes:
      - ./logstash/logstash.conf:/usr/share/logstash/pipeline/logstash.conf:ro
    ports:
      - "5044:5044"
    depends_on:
      - elasticsearch

  filebeat:
    image: docker.elastic.co/beats/filebeat:8.14.1
    user: root
    volumes:
      - ./filebeat/filebeat.yml:/usr/share/filebeat/filebeat.yml:ro
      - ./logs:/var/log/app:ro
    command: ["--strict.perms=false"]
    depends_on:
      - logstash
```

---

## Step 8 — Configure Logstash

Create `nano logstash/logstash.conf`:

```ruby
input {
  beats {
    port => 5044
  }
}

filter {
  date {
    match  => ["timestamp", "ISO8601"]
    target => "@timestamp"
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "python-logs"
  }
}
```

---

## Step 9 — Configure Filebeat

Create `nano filebeat/filebeat.yml`:

```yaml
filebeat.inputs:
  - type: filestream
    id: python
    paths:
      - /var/log/app/*.log
    parsers:
      - ndjson:
          target: ""

output.logstash:
  hosts: ["logstash:5044"]
```

---

## Step 10 — Write the Python app

Create `nano app/app.py`:

```python
import logging, time, random
from datetime import datetime, timezone
from pythonjsonlogger import jsonlogger

# Set up a logger that writes JSON to logs/app.log
logger = logging.getLogger("myapp")
logger.setLevel(logging.INFO)
handler = logging.FileHandler("logs/app.log")

class JsonFormatter(jsonlogger.JsonFormatter):
    def add_fields(self, log_record, record, message_dict):
        super().add_fields(log_record, record, message_dict)
        log_record["timestamp"] = datetime.now(timezone.utc).isoformat()
        log_record["level"] = record.levelname

handler.setFormatter(JsonFormatter("%(timestamp)s %(level)s %(message)s"))
logger.addHandler(handler)

# Create some fake logs so the dashboard has something to show
endpoints = ["/users", "/orders", "/login", "/checkout"]
while True:
    status = random.choice([200, 200, 200, 404, 500])
    info = {"endpoint": random.choice(endpoints),
            "status_code": status,
            "latency_ms": round(random.uniform(5, 800), 1)}
    if status >= 500:
        logger.error("Request failed", extra=info)
    else:
        logger.info("Request handled", extra=info)
    time.sleep(1)
```

---

## Step 11 — Start ELK

```bash
cd ~/elk-python
docker compose up -d
```

Wait about 2 minutes for everything to start, then check:

```bash
docker compose ps
```

---

## Step 12 — Run the Python app

Install Python's package and start the app:

```bash
sudo apt install -y python3-pip
pip install python-json-logger
python3 app/app.py
```

Leave it running — it keeps adding logs to `logs/app.log`.

> Tip: to keep it running after you disconnect, stop it (`Ctrl+C`) and start it
> with `nohup python3 app/app.py &` instead. Then you can safely close SSH.

---

## Step 13 — Check the logs arrived

Open a **second SSH session** (or use `nohup` above) and run:

```bash
curl "http://localhost:9200/python-logs/_count"
```

If you see a number bigger than 0, it's working! ✅

---

## Step 14 — Open Kibana in your browser

On your own computer, go to:

```
http://YOUR_EC2_PUBLIC_IP:5601
```

**Create a data view (so Kibana can find your logs):**

1. Click the menu (☰) → **Stack Management** → **Data Views**.
2. Click **Create data view**.
3. Name: `python-logs`
4. Index pattern: `python-logs`
5. Timestamp field: `@timestamp`
6. Click **Save**.

---

## Step 15 — See your logs

1. Click the menu (☰) → **Discover**.
2. Pick `python-logs` at the top left.
3. Set the time (top right) to **Last 15 minutes**.

You'll see your logs! Try typing these in the search bar:

- `level: "ERROR"` → only errors
- `status_code: 500` → failed requests

---

## Step 16 — Make a dashboard

**First, make a chart:**

1. Menu (☰) → **Dashboard** → **Create dashboard** → **Create visualization**.
2. Pick **Bar** chart.
3. Drag `@timestamp` to the bottom (horizontal) axis.
4. The count goes on the up (vertical) axis automatically.
5. Under "Break down by", choose `level`.
6. Click **Save and return**.

Now you have a chart showing logs over time, split by level (info vs error).

**Add a second chart the same way:**

- Pick **Pie**, and slice it by `endpoint` to see which parts of your app are busiest.

**Then save the dashboard:**

- Click **Save**, name it `Python Logs`, and you're done.

Turn on auto-refresh (top right) to watch it update live.

---

## Troubleshooting

| Problem | Try this |
|---|---|
| Kibana page won't open | Check port 5601 is open to **your IP** in the Security Group |
| Everything is slow / crashing | Instance too small — use t3.large or bigger |
| Elasticsearch won't start | Run the `sysctl` command from Step 5 again |
| Kibana says "not ready" | Wait 2 more minutes |
| Log count is still 0 | Make sure `app.py` is running and check `docker compose logs logstash` |
| "Connection refused" in browser | Wait longer; run `docker compose logs kibana` to check status |

Handy commands (run on the server):

```bash
docker compose ps        # see what's running
docker compose logs -f   # watch all logs live
docker compose down      # stop everything
```

---

## Logs vs Metrics — ELK vs Prometheus + Grafana

You'll often hear about **Prometheus + Grafana** alongside ELK. They are **not
competitors** — they solve different problems and are often used **together**.

### The core difference

- **Logs** are text records of events — *"user 4821 hit /checkout and got a 500
  error at 09:14:22."* They answer **"what exactly happened?"** → this is what
  **ELK** is built for.
- **Metrics** are numbers measured over time — *CPU 73%, 1,200 requests/sec,
  latency 340ms.* They answer **"how is the system behaving right now?"** → this
  is what **Prometheus + Grafana** is built for.

(Prometheus is the database that stores the numbers. Grafana is the dashboard
that draws them.)

### Quick comparison

| | ELK | Prometheus + Grafana |
|---|---|---|
| Data type | Logs (text/events) | Metrics (numbers over time) |
| Main question | "What happened?" | "How is it behaving?" |
| Best at | Search, debugging, reading errors | Real-time health, trends, alerting |
| Storage cost | Heavier (stores full text) | Very light (just numbers) |
| Alerting | Possible, but heavier | Lightweight and built-in |

### When to choose ELK

- You need to **read and search actual log messages** (debugging, stack traces).
- You're investigating a specific error or tracing one request.
- You need audit trails or security event logs.
- Example: *"Show me every failed login from this IP last Tuesday."*

### When to choose Prometheus + Grafana

- You want **real-time system health** monitoring (uptime, CPU, memory, latency).
- You care about **numbers and trends** over time.
- You want **easy alerting** — *"page me if error rate > 5% for 5 minutes."*
- You're monitoring servers, containers, or Kubernetes.

### The honest answer: use both

1. **Prometheus + Grafana** tells you *something is wrong* (latency spiked).
2. You jump into **Kibana (ELK)** to read the logs and find out *why*.

### Simple rule of thumb

- Reading errors, audit trails, "what happened?" → **ELK**
- System health dashboards + alerting on thresholds → **Prometheus + Grafana**
- A serious production system → **both**

---

## Important security note

This setup has **security turned off**, which is fine for testing but **not safe
for real production use** on the open internet. Before using it for real:

- Turn Elasticsearch security back on (passwords + TLS).
- Put Kibana behind HTTPS.
- Keep the Security Group locked to your own IP.

---

## That's it! ✅

You now have:

1. An EC2 Ubuntu server running ELK.
2. A Python app writing logs.
3. Logs flowing into Elasticsearch.
4. A live Kibana dashboard you can open from your browser.

**Next step:** replace the fake logs in `app.py` with your real app's logging —
just keep using `logger.info(...)` and `logger.error(...)` with `extra={...}`
for the extra fields.
