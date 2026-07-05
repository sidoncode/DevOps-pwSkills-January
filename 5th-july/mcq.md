# Cloud Monitoring & Observability — Practice Quiz (Expanded)

_Similar-style questions covering AWS monitoring, Prometheus, Grafana, Datadog, Nagios, metrics, alerting, backups, failover, and more._

---

## Section A — Questions

**1.** Which AWS service records API calls and account activity for auditing purposes?
A. CloudWatch
B. CloudTrail
C. Inspector
D. GuardDuty

**2.** A CloudWatch Alarm can trigger which of the following actions automatically?
A. Rotating IAM access keys
B. Sending a notification via SNS
C. Building a Docker image
D. Provisioning a new VPC

**3.** What is the main advantage of scheduling automated snapshots?
A. It lowers CPU utilization
B. It guarantees zero downtime
C. It provides reliable point-in-time recovery
D. It removes the need for backups entirely

**4.** In AWS, which service centrally manages and automates backups across multiple resources?
A. AWS Backup
B. aws_snapshot_scheduler
C. Amazon S3 Glacier
D. AWS DataSync

**5.** A multi-AZ deployment primarily improves:
A. Storage throughput
B. High availability and fault tolerance
C. Billing predictability
D. Code deployment speed

**6.** Monitoring is essential in a DevOps workflow mainly because it:
A. Replaces the need for testing
B. Provides visibility into reliability and performance
C. Speeds up frontend rendering
D. Eliminates infrastructure cost

**7.** Which of the following is a core "golden signal" of application monitoring?
A. Number of Git branches
B. Latency
C. Lines of code
D. Number of contributors

**8.** A sudden spike in the application error rate most likely signals:
A. Increased customer satisfaction
B. A service fault or instability
C. Reduced network usage
D. Successful auto-scaling

**9.** Which metric best helps detect a gradual memory leak?
A. Request throughput
B. CPU temperature
C. Memory utilization trending upward over time
D. Number of open ports

**10.** When deciding what to monitor first, teams should prioritize:
A. The number of servers owned
B. Metrics tied to service-level objectives and business impact
C. The color scheme of dashboards
D. The size of the log files

**11.** Which open-source tool uses a pull-based model and its own query language (PromQL) for metrics?
A. Grafana
B. Prometheus
C. Splunk
D. Kibana

**12.** Datadog is most commonly adopted for:
A. Source-code version control
B. Full-stack observability across infrastructure and applications
C. Managing DNS zones
D. Compiling application binaries

**13.** Which legacy tool is well known for its plugin ecosystem and host/service checks?
A. Prometheus
B. Nagios
C. Ansible
D. CloudFormation

**14.** To diagnose a storage/disk bottleneck, which metric is most informative?
A. Network latency
B. Disk IOPS / throughput
C. CPU idle percentage
D. DNS query count

**15.** Why should databases be included in infrastructure monitoring?
A. To manage user login sessions
B. To improve CSS rendering
C. To track query performance, availability, and resource usage
D. To rotate SSL certificates

**16.** Which of the following best describes a Prometheus "Counter"?
A. A value that can go up and down
B. A cumulative value that only increases (or resets to zero)
C. A distribution of observed values into buckets
D. A textual log entry

**17.** In Grafana, the component that supplies the underlying metrics to panels is called a:
A. Dashboard
B. Data source
C. Notification channel
D. Playlist

**18.** Which metric type is best suited for measuring request-latency percentiles (p95/p99)?
A. Counter
B. Gauge
C. Histogram
D. Boolean flag

**19.** A commonly used threshold for alerting on sustained high memory usage is:
A. > 5%
B. > 25%
C. > 50%
D. > 85%

**20.** Which statement correctly distinguishes infrastructure vs. application monitoring?
A. They monitor the exact same things
B. Infrastructure monitoring watches system resources; application monitoring watches service behavior
C. Application monitoring only works on-premises
D. Infrastructure monitoring only tracks user clicks

**21.** After installing a monitoring agent on a host, the next logical step is to:
A. Delete the host's logs
B. Collect and visualize its metrics
C. Terminate the instance
D. Disable networking

**22.** Adding a Prometheus client library to your application allows it to:
A. Encrypt all outbound traffic
B. Expose internal metrics on an endpoint for scraping
C. Automatically scale the app
D. Deploy the app to Kubernetes

**23.** Which of the following would NOT typically be exposed as a useful application metric?
A. HTTP requests per second
B. Active database connections
C. The font family used in the UI
D. Request processing duration

**24.** A key characteristic of real-time (active) monitoring is:
A. Long-term trend reporting
B. Immediate detection and alerting on issues
C. Monthly billing summaries
D. Archiving old logs

**25.** Which of the following is an example of historical monitoring?
A. An instant PagerDuty alert on 99% CPU
B. A 30-day dashboard showing memory usage trends
C. A live tail of application logs
D. A real-time error-rate gauge

**26.** Why is historical monitoring valuable?
A. It replaces the need for alerts
B. It supports capacity planning and trend analysis
C. It reduces the number of instances automatically
D. It encrypts stored metrics

**27.** Which channel is frequently integrated with monitoring tools to deliver team alerts?
A. Amazon S3
B. Slack
C. AWS CodeCommit
D. Route 53

**28.** In PromQL, which function is used to calculate the per-second rate of a counter?
A. sum()
B. avg_over_time()
C. rate()
D. count()

**29.** A "Gauge" metric in Prometheus is best used to represent:
A. Total requests since startup
B. A value that can rise and fall, like current active users
C. Buckets of latency observations
D. A one-time deployment event

**30.** Which AWS service can send monitoring alarms and notifications to subscribers via email, SMS, or HTTP?
A. AWS Lambda
B. Amazon SNS
C. Amazon SQS
D. AWS Config

**31.** What default port does Prometheus expose its web UI and API on?
A. 3000
B. 8080
C. 9090
D. 9100

**32.** The Node Exporter is used to expose which kind of metrics?
A. Application business metrics
B. Host-level hardware and OS metrics
C. Container image layers
D. Database query plans

**33.** In Prometheus, the interval at which targets are pulled for metrics is called the:
A. retention period
B. scrape interval
C. evaluation window
D. refresh rate

**34.** Which PromQL function returns the total increase of a counter over a time window?
A. delta()
B. increase()
C. resets()
D. changes()

**35.** What is the default login username for a fresh Grafana installation?
A. root
B. grafana
C. admin
D. superuser

**36.** Which component of the Prometheus ecosystem is responsible for handling alerts and routing notifications?
A. Pushgateway
B. Alertmanager
C. Blackbox Exporter
D. Thanos

**37.** The four "golden signals" of monitoring are latency, traffic, errors, and:
A. saturation
B. encryption
C. replication
D. compression

**38.** Which HTTP endpoint does a Prometheus client library typically expose metrics on by default?
A. /health
B. /status
C. /metrics
D. /debug

**39.** What does "SLO" stand for in the context of monitoring?
A. System Load Optimization
B. Service-Level Objective
C. Server Log Output
D. Secure Login Operation

**40.** Which metric would best indicate that an application is receiving heavy traffic?
A. Requests per second
B. Disk temperature
C. Number of code commits
D. SSL certificate expiry

**41.** In Grafana, a "panel" is best described as:
A. A user permission group
B. A single visualization (graph, gauge, table, etc.) on a dashboard
C. A backup schedule
D. A network firewall rule

**42.** Which type of alert threshold reduces false alarms from brief, momentary spikes?
A. A threshold evaluated only once
B. A threshold that must be breached for a sustained duration ("for" clause)
C. A threshold with no time condition
D. A randomly evaluated threshold

**43.** Which of the following is a "push-based" metrics collection tool?
A. Prometheus (default mode)
B. StatsD / Graphite
C. Node Exporter
D. Blackbox Exporter

**44.** What is the primary purpose of the Prometheus Pushgateway?
A. Long-term storage of metrics
B. Allowing short-lived batch jobs to push metrics
C. Rendering dashboards
D. Managing user authentication

**45.** A p99 latency of 2 seconds means:
A. The average request takes 2 seconds
B. 99% of requests complete in 2 seconds or less
C. 99 requests took 2 seconds
D. The slowest request took 99 seconds

**46.** Which AWS feature automatically adjusts EC2 capacity based on CloudWatch metrics?
A. AWS Config
B. Auto Scaling
C. AWS Shield
D. Elastic Beanstalk cleanup

**47.** Which of the following is a benefit of using dashboards for monitoring?
A. They eliminate the need to collect metrics
B. They provide an at-a-glance visual overview of system health
C. They automatically fix incidents
D. They replace log files entirely

**48.** In observability, the "three pillars" are metrics, logs, and:
A. traces
B. tickets
C. templates
D. tokens

**49.** Which tool is commonly used alongside Prometheus for long-term, scalable metric storage?
A. Thanos or Cortex
B. Terraform
C. Jenkins
D. Vault

**50.** A rising queue depth or high CPU wait most directly indicates:
A. Low utilization
B. Resource saturation
C. Successful scaling down
D. Reduced traffic

**51.** Which statement about "alert fatigue" is correct?
A. It improves team responsiveness
B. Too many noisy alerts cause teams to ignore important ones
C. It only affects historical monitoring
D. It is unrelated to alert thresholds

**52.** What is the main role of a "heartbeat" or "up" metric?
A. To measure CPU temperature
B. To indicate whether a target/service is reachable and running
C. To count HTTP errors
D. To store logs

**53.** Which AWS service provides centralized log collection and querying for applications?
A. CloudWatch Logs
B. Amazon SNS
C. AWS Backup
D. Amazon Route 53

**54.** In Prometheus, labels are used to:
A. Encrypt metric values
B. Add dimensions/metadata to metrics for filtering and grouping
C. Schedule backups
D. Define IAM permissions

**55.** Which query would you use to find the 95th percentile latency from a histogram metric?
A. rate(...)
B. increase(...)
C. histogram_quantile(0.95, ...)
D. sum(...)

**56.** What is a "runbook" in the context of incident response?
A. A financial report
B. A documented set of steps to diagnose and resolve a known issue
C. A type of dashboard
D. A backup archive

**57.** Which of the following best defines "MTTR"?
A. Maximum Traffic Throughput Rate
B. Mean Time To Recovery/Resolution
C. Metric Tracking Time Range
D. Managed Timeout Threshold

**58.** Blackbox monitoring primarily checks a service from the perspective of:
A. Internal code execution
B. An external user (probing endpoints for availability/response)
C. The database engine
D. The CI/CD pipeline

**59.** Which practice helps ensure alerts are actionable?
A. Alerting on every minor metric change
B. Alerting only on symptoms that affect users or SLOs
C. Disabling all alerts at night
D. Sending alerts only via email logs

**60.** What is the benefit of tagging/labeling metrics by environment (e.g., prod vs. staging)?
A. It encrypts the metrics
B. It allows filtering and comparing metrics per environment
C. It reduces storage cost to zero
D. It disables scraping in staging

---

## Section B — Answer Key

| Q  | Answer | Q  | Answer |
|----|--------|----|--------|
| 1  | B. CloudTrail | 31 | C. 9090 |
| 2  | B. Sending a notification via SNS | 32 | B. Host-level hardware and OS metrics |
| 3  | C. It provides reliable point-in-time recovery | 33 | B. scrape interval |
| 4  | A. AWS Backup | 34 | B. increase() |
| 5  | B. High availability and fault tolerance | 35 | C. admin |
| 6  | B. Provides visibility into reliability and performance | 36 | B. Alertmanager |
| 7  | B. Latency | 37 | A. saturation |
| 8  | B. A service fault or instability | 38 | C. /metrics |
| 9  | C. Memory utilization trending upward over time | 39 | B. Service-Level Objective |
| 10 | B. Metrics tied to service-level objectives and business impact | 40 | A. Requests per second |
| 11 | B. Prometheus | 41 | B. A single visualization on a dashboard |
| 12 | B. Full-stack observability across infrastructure and applications | 42 | B. A threshold that must be breached for a sustained duration |
| 13 | B. Nagios | 43 | B. StatsD / Graphite |
| 14 | B. Disk IOPS / throughput | 44 | B. Allowing short-lived batch jobs to push metrics |
| 15 | C. To track query performance, availability, and resource usage | 45 | B. 99% of requests complete in 2 seconds or less |
| 16 | B. A cumulative value that only increases (or resets to zero) | 46 | B. Auto Scaling |
| 17 | B. Data source | 47 | B. They provide an at-a-glance visual overview of system health |
| 18 | C. Histogram | 48 | A. traces |
| 19 | D. > 85% | 49 | A. Thanos or Cortex |
| 20 | B. Infrastructure monitoring watches system resources; application monitoring watches service behavior | 50 | B. Resource saturation |
| 21 | B. Collect and visualize its metrics | 51 | B. Too many noisy alerts cause teams to ignore important ones |
| 22 | B. Expose internal metrics on an endpoint for scraping | 52 | B. To indicate whether a target/service is reachable and running |
| 23 | C. The font family used in the UI | 53 | A. CloudWatch Logs |
| 24 | B. Immediate detection and alerting on issues | 54 | B. Add dimensions/metadata to metrics for filtering and grouping |
| 25 | B. A 30-day dashboard showing memory usage trends | 55 | C. histogram_quantile(0.95, ...) |
| 26 | B. It supports capacity planning and trend analysis | 56 | B. A documented set of steps to diagnose and resolve a known issue |
| 27 | B. Slack | 57 | B. Mean Time To Recovery/Resolution |
| 28 | C. rate() | 58 | B. An external user probing endpoints for availability |
| 29 | B. A value that can rise and fall, like current active users | 59 | B. Alerting only on symptoms that affect users or SLOs |
| 30 | B. Amazon SNS | 60 | B. It allows filtering and comparing metrics per environment |
