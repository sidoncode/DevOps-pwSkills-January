# Prometheus + Grafana Demo on AWS EC2 — Ubuntu 26.04 (with Dummy Data & PromQL)

A complete hands-on demo you can finish in ~30 minutes on a single Ubuntu 26.04 EC2 instance.

---

## Step 0 — Launch the EC2 Instance

1. Go to **EC2 → Launch Instance**
2. Settings:
   - **AMI:** Ubuntu Server 26.04 LTS
   - **Type:** t2.micro / t3.micro (free tier is fine for a demo)
   - **Key pair:** create/select one
3. **Security Group — open these inbound ports** (source: My IP for safety):

| Port | Purpose |
|------|---------|
| 22   | SSH |
| 9090 | Prometheus UI |
| 3000 | Grafana UI |
| 9100 | Node Exporter |
| 8000 | Dummy metrics app |

4. SSH in (note: Ubuntu's default user is `ubuntu`, not `ec2-user`):
```bash
ssh -i mykey.pem ubuntu@<EC2_PUBLIC_IP>
```

5. Update packages first:
```bash
sudo apt update && sudo apt upgrade -y
```

---

## Step 1 — Install Prometheus

```bash
# Create user & dirs
sudo useradd --no-create-home --shell /bin/false prometheus
sudo mkdir -p /etc/prometheus /var/lib/prometheus

# Download (check latest at https://prometheus.io/download/)
cd /tmp
wget https://github.com/prometheus/prometheus/releases/download/v2.53.0/prometheus-2.53.0.linux-amd64.tar.gz
tar xvf prometheus-2.53.0.linux-amd64.tar.gz
cd prometheus-2.53.0.linux-amd64

sudo cp prometheus promtool /usr/local/bin/
sudo cp -r consoles console_libraries /etc/prometheus/
sudo cp prometheus.yml /etc/prometheus/
sudo chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
```

> Tip: Ubuntu also has `sudo apt install prometheus`, but the manual install above gives you a newer version and matches most tutorials/production setups.

Create a systemd service:

```bash
sudo tee /etc/systemd/system/prometheus.service > /dev/null <<'EOF'
[Unit]
Description=Prometheus
After=network.target

[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now prometheus
sudo systemctl status prometheus
```

✅ Check: open `http://<EC2_PUBLIC_IP>:9090` — you should see the Prometheus UI.

---

## Step 2 — Install Node Exporter (real system metrics)

```bash
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-amd64.tar.gz
tar xvf node_exporter-1.8.1.linux-amd64.tar.gz
sudo cp node_exporter-1.8.1.linux-amd64/node_exporter /usr/local/bin/

sudo useradd --no-create-home --shell /bin/false node_exporter

sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<'EOF'
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter
```

✅ Check: `curl localhost:9100/metrics` should dump hundreds of metrics.

---

## Step 3 — Dummy Data Generator (Python)

This simulates an e-commerce app: orders, revenue, active users, and request latency.

**Important for Ubuntu 26.04:** the system Python is "externally managed" (PEP 668), so a plain `pip3 install` will fail. Use a virtual environment:

```bash
sudo apt install -y python3-venv

python3 -m venv /home/ubuntu/metrics-venv
/home/ubuntu/metrics-venv/bin/pip install prometheus_client
```

Create the app:

```bash
tee /home/ubuntu/dummy_app.py > /dev/null <<'EOF'
from prometheus_client import start_http_server, Counter, Gauge, Histogram
import random, time

ORDERS = Counter('shop_orders_total', 'Total orders', ['payment_method', 'status'])
REVENUE = Counter('shop_revenue_dollars_total', 'Total revenue in dollars')
ACTIVE_USERS = Gauge('shop_active_users', 'Currently active users')
LATENCY = Histogram('shop_request_duration_seconds', 'Request latency',
                    buckets=[0.05, 0.1, 0.25, 0.5, 1, 2.5])

if __name__ == '__main__':
    start_http_server(8000)
    print("Dummy metrics on :8000/metrics")
    while True:
        method = random.choice(['card', 'card', 'card', 'upi', 'paypal'])
        status = random.choices(['success', 'failed'], weights=[95, 5])[0]
        ORDERS.labels(payment_method=method, status=status).inc()
        if status == 'success':
            REVENUE.inc(round(random.uniform(10, 200), 2))
        ACTIVE_USERS.set(random.randint(50, 500))
        LATENCY.observe(random.expovariate(1/0.3))
        time.sleep(random.uniform(0.2, 1.5))
EOF
```

Run it as a service (note the venv Python in ExecStart):

```bash
sudo tee /etc/systemd/system/dummy-app.service > /dev/null <<'EOF'
[Unit]
Description=Dummy Metrics App
After=network.target

[Service]
User=ubuntu
ExecStart=/home/ubuntu/metrics-venv/bin/python /home/ubuntu/dummy_app.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now dummy-app
```

✅ Check: `curl localhost:8000/metrics | grep shop_`

---

## Step 4 — Tell Prometheus to Scrape Everything

Edit the config:

```bash
sudo tee /etc/prometheus/prometheus.yml > /dev/null <<'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'dummy_shop'
    static_configs:
      - targets: ['localhost:8000']
EOF

sudo systemctl restart prometheus
```

✅ Check: Prometheus UI → **Status → Targets** — all 3 targets should show **UP**.

---

## Step 5 — Install Grafana (apt repo, keyring method)

```bash
sudo apt install -y apt-transport-https software-properties-common wget

# Add Grafana's GPG key the modern way (apt-key is removed in newer Ubuntu)
sudo mkdir -p /etc/apt/keyrings
wget -q -O - https://apt.grafana.com/gpg.key | \
  gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null

echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | \
  sudo tee /etc/apt/sources.list.d/grafana.list

sudo apt update
sudo apt install -y grafana
sudo systemctl enable --now grafana-server
```

✅ Open `http://<EC2_PUBLIC_IP>:3000` — login `admin` / `admin` (it will ask you to change the password).

---

## Step 6 — Connect Grafana to Prometheus

1. Grafana → **Connections → Data sources → Add data source**
2. Choose **Prometheus**
3. URL: `http://localhost:9090`
4. Click **Save & Test** → should say "Successfully queried the Prometheus API"

Bonus: import a ready-made dashboard — **Dashboards → New → Import → ID `1860`** (Node Exporter Full). Instant pretty graphs of your EC2 box.

---

## Step 7 — PromQL Cheat Sheet (try these!)

Run these in Prometheus (`:9090` → Graph tab) or in a Grafana panel.

### Dummy shop metrics

```promql
# Orders per second, by payment method (rate over 5 min)
rate(shop_orders_total[5m])

# Total orders in the last hour
increase(shop_orders_total[1h])

# Orders per second grouped by payment method only
sum by (payment_method) (rate(shop_orders_total[5m]))

# Failure rate (%) of orders
100 * sum(rate(shop_orders_total{status="failed"}[5m]))
    / sum(rate(shop_orders_total[5m]))

# Revenue per minute
rate(shop_revenue_dollars_total[5m]) * 60

# Current active users
shop_active_users

# 95th percentile request latency
histogram_quantile(0.95, rate(shop_request_duration_seconds_bucket[5m]))
```

### Node Exporter (real EC2 metrics)

```promql
# CPU usage % (all cores)
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage %
100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)

# Disk space used % on root
100 - (node_filesystem_avail_bytes{mountpoint="/"} * 100
     / node_filesystem_size_bytes{mountpoint="/"})

# Network received bytes/sec
rate(node_network_receive_bytes_total[5m])

# System uptime in hours
(time() - node_boot_time_seconds) / 3600
```

### PromQL concepts in 30 seconds

| Function | Use for | Example |
|----------|---------|---------|
| `rate()` | per-second rate of a **Counter** | `rate(x_total[5m])` |
| `increase()` | total change over a window | `increase(x_total[1h])` |
| `sum by (label)` | aggregate across series | `sum by (status) (...)` |
| `histogram_quantile()` | percentiles from Histograms | p95, p99 latency |
| `{label="value"}` | filter series | `{status="failed"}` |
| `[5m]` | range vector (look-back window) | needed by rate/increase |

---

## Step 8 — Build a Demo Dashboard in Grafana

1. **Dashboards → New → New dashboard → Add visualization**
2. Suggested panels:
   - **Time series:** `sum by (payment_method) (rate(shop_orders_total[5m]))` — title "Orders/sec"
   - **Stat:** `shop_active_users` — title "Active Users"
   - **Stat:** `increase(shop_revenue_dollars_total[1h])` — title "Revenue (1h)"
   - **Gauge:** the CPU query above — title "CPU %"
   - **Time series:** `histogram_quantile(0.95, rate(shop_request_duration_seconds_bucket[5m]))` — "p95 Latency"
3. Set refresh to **5s** (top right) and watch dummy data flow live. 🎉

---

## Quick Troubleshooting

- Target shows DOWN → `sudo systemctl status <service>` and `curl localhost:<port>/metrics`
- Can't reach UIs → recheck Security Group inbound rules (and `sudo ufw status` — if UFW is active, `sudo ufw allow 9090,3000,9100,8000/tcp`)
- Config typo → validate: `promtool check config /etc/prometheus/prometheus.yml`
- `pip install` errors about "externally-managed-environment" → you skipped the venv in Step 3
- Note: version numbers above (2.53.0 / 1.8.1) may be outdated — grab the latest from the GitHub releases pages if downloads fail.

## Cleanup

Terminate the EC2 instance when done to avoid charges.
