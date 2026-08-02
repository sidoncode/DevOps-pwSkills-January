# AWS CodeDeploy on EC2 — Easy Step-by-Step Tutorial

This guide walks you through deploying a simple web app to an EC2 instance using **AWS CodeDeploy**, from zero. Every step is explained in plain language. Follow them in order.

---

## What is CodeDeploy? (30-second version)

CodeDeploy is an AWS service that **automatically copies your app onto your servers and runs it** for you. Instead of manually SSH-ing into a server and copying files, you package your app, hand it to CodeDeploy, and it does the deployment.

**The 4 things you need to make it work:**

1. Two **IAM roles** (permissions) — one for CodeDeploy, one for your EC2 instance.
2. An **EC2 instance** with the **CodeDeploy agent** installed on it.
3. Your app bundled with a special file called **`appspec.yml`**.
4. A CodeDeploy **application** + **deployment group** that ties it all together.

---

## Prerequisites

- An AWS account with permission to use IAM, EC2, S3, and CodeDeploy.
- The **AWS CLI** installed and configured on your computer (`aws configure`).
- Basic comfort with the terminal.

> 💡 We'll deploy to an **Amazon Linux 2023** instance in this guide. Commands are given for that OS.

---

## Step 1 — Create the IAM role for the EC2 instance

The EC2 instance needs permission to talk to CodeDeploy and download files from S3.

1. Go to the **IAM Console** → **Roles** → **Create role**.
2. **Trusted entity type:** AWS service → **Use case: EC2** → Next.
3. Attach these two policies (search and tick each):
   - `AmazonEC2RoleforAWSCodeDeploy` (lets the instance read your S3 bundle)
   - `AmazonSSMManagedInstanceCore` (optional but handy for troubleshooting)
4. Name it: **`EC2CodeDeployRole`** → **Create role**.

You now have a role your instance can wear.

---

## Step 2 — Create the IAM role for CodeDeploy itself

CodeDeploy needs its own permission to manage your instances.

1. **IAM Console** → **Roles** → **Create role**.
2. **Trusted entity type:** AWS service → **Use case: CodeDeploy** → pick **CodeDeploy** → Next.
3. The policy `AWSCodeDeployRole` is attached automatically → Next.
4. Name it: **`CodeDeployServiceRole`** → **Create role**.

> ✅ You should now have **two** roles: `EC2CodeDeployRole` and `CodeDeployServiceRole`.

---

## Step 3 — Launch an EC2 instance

1. Go to the **EC2 Console** → **Launch instances**.
2. **Name:** `codedeploy-demo`
3. **AMI:** Amazon Linux 2023
4. **Instance type:** `t2.micro` (free tier eligible)
5. **Key pair:** create or select one (so you can SSH in).
6. **Network settings:** allow **SSH (22)** and **HTTP (80)** in the security group.
7. **Advanced details** → **IAM instance profile:** select **`EC2CodeDeployRole`**.
8. Expand **Advanced details → Tags** (or add tags after launch). Add this tag — CodeDeploy uses it to find your instance:
   - **Key:** `Name`  **Value:** `codedeploy-demo`
9. **Launch instance.**

> ⚠️ The IAM role and the tag are the two things people most often forget. Double-check both.

---

## Step 4 — Install the CodeDeploy agent on the instance

SSH into your instance:

```bash
ssh -i your-key.pem ec2-user@<YOUR_INSTANCE_PUBLIC_IP>
```

Then run these commands (Amazon Linux 2023):

```bash
sudo yum update -y
sudo yum install -y ruby wget

# Download the installer.
# Replace the region below if you are not in us-east-1.
# Format: https://aws-codedeploy-<region>.s3.<region>.amazonaws.com/latest/install
wget https://aws-codedeploy-us-east-1.s3.us-east-1.amazonaws.com/latest/install

chmod +x ./install
sudo ./install auto

# Check it is running:
sudo systemctl status codedeploy-agent
```

You should see **`active (running)`**. If not, run `sudo systemctl start codedeploy-agent`.

> 💡 Find the installer URL for your exact region in the AWS docs by searching "CodeDeploy agent install by region". The region in the URL **must** match where your instance lives.

---

## Step 5 — Prepare your app bundle

On your **local computer**, create a folder and these files. This is a tiny app that installs a web server and shows a page.

```
my-app/
├── appspec.yml
├── index.html
└── scripts/
    ├── install_dependencies.sh
    ├── start_server.sh
    └── stop_server.sh
```

### `appspec.yml`
This file is the heart of CodeDeploy. It tells CodeDeploy **where to put files** and **what scripts to run, and when**.

```yaml
version: 0.0
os: linux
files:
  - source: /index.html
    destination: /var/www/html/
hooks:
  BeforeInstall:
    - location: scripts/install_dependencies.sh
      timeout: 300
      runas: root
  ApplicationStop:
    - location: scripts/stop_server.sh
      timeout: 300
      runas: root
  ApplicationStart:
    - location: scripts/start_server.sh
      timeout: 300
      runas: root
```

### `index.html`
```html
<!DOCTYPE html>
<html>
  <head><title>CodeDeploy Demo</title></head>
  <body>
    <h1>🎉 Deployed with AWS CodeDeploy!</h1>
  </body>
</html>
```

### `scripts/install_dependencies.sh`
```bash
#!/bin/bash
yum install -y httpd
```

### `scripts/start_server.sh`
```bash
#!/bin/bash
systemctl start httpd
systemctl enable httpd
```

### `scripts/stop_server.sh`
```bash
#!/bin/bash
# The "|| true" stops the deploy from failing on the very first run
# when httpd isn't installed/running yet.
systemctl stop httpd || true
```

> ⚠️ **Important:** the `appspec.yml` file must sit at the **root** of your bundle. Paths inside it are relative to that root.

---

## Step 6 — Upload your app to S3

CodeDeploy pulls your app from an S3 bucket (or GitHub). We'll use S3.

1. Create a bucket (bucket names are globally unique — change `myname`):

```bash
aws s3 mb s3://myname-codedeploy-demo --region us-east-1
```

2. From **inside** your `my-app` folder, zip and push the bundle up to S3 in one command:

```bash
cd my-app

aws deploy push \
  --application-name MyDemoApp \
  --s3-location s3://myname-codedeploy-demo/app.zip \
  --source .
```

The `aws deploy push` command zips your folder and uploads it. Keep the S3 path (`s3://myname-codedeploy-demo/app.zip`) handy for later.

> 💡 The `--application-name` here is just a label at this point. You'll formally create that application in the next step.

---

## Step 7 — Create the CodeDeploy application

1. Go to the **CodeDeploy Console** → **Applications** → **Create application**.
2. **Application name:** `MyDemoApp`
3. **Compute platform:** **EC2/On-premises**
4. **Create application.**

Or use the CLI:

```bash
aws deploy create-app \
  --application-name MyDemoApp
```

---

## Step 8 — Create a deployment group

A deployment group tells CodeDeploy **which instances** to deploy to and **which role** to use.

**Via Console:**

1. Inside `MyDemoApp` → **Create deployment group**.
2. **Deployment group name:** `MyDemoDeploymentGroup`
3. **Service role:** select **`CodeDeployServiceRole`** (from Step 2).
4. **Deployment type:** **In-place**.
5. **Environment configuration:** tick **Amazon EC2 instances**.
   - **Key:** `Name`  **Value:** `codedeploy-demo`
   - It should say it matched **1 unique instance**. ✅ If it says 0, your tag or region is wrong.
6. **Deployment settings:** `CodeDeployDefault.AllAtOnce` (fine for one instance).
7. **Load balancer:** untick "Enable load balancing" (we don't have one).
8. **Create deployment group.**

**Or use the CLI** (replace the ARN with your `CodeDeployServiceRole` ARN):

```bash
aws deploy create-deployment-group \
  --application-name MyDemoApp \
  --deployment-group-name MyDemoDeploymentGroup \
  --service-role-arn arn:aws:iam::508375325436:role/CodeDeployServiceRole \
  --deployment-config-name CodeDeployDefault.AllAtOnce \
  --ec2-tag-filters Key=Name,Value=codedeploy-demo,Type=KEY_AND_VALUE
```

---

## Step 9 — Deploy! 🚀

**Via Console:**

1. Inside your deployment group → **Create deployment**.
2. **Revision location:** choose **My application is stored in Amazon S3**.
3. **Revision location (S3):** paste `s3://myname-codedeploy-demo/app.zip`.
4. **Revision file type:** `.zip`.
5. **Create deployment.**

Watch the progress screen. Each lifecycle event (Stop → BeforeInstall → Install → Start) turns green as it succeeds. This usually takes under a minute.

**Or use the CLI:**

```bash
aws deploy create-deployment \
  --application-name MyDemoApp \
  --deployment-group-name MyDemoDeploymentGroup \
  --s3-location bucket=myname-codedeploy-demo,key=app.zip,bundleType=zip
```

---

## Step 10 — Verify it worked

Open your instance's **public IP** in a browser:

```
http://<YOUR_INSTANCE_PUBLIC_IP>
```

You should see **🎉 Deployed with AWS CodeDeploy!**

Congratulations — that's a full CodeDeploy pipeline. 🎊

---

## Deploying an update

To ship a change, just repeat the loop:

1. Edit `index.html` (or any file).
2. Run `aws deploy push ...` again (Step 6) to upload a new `app.zip`.
3. Run `aws deploy create-deployment ...` again (Step 9).

CodeDeploy handles stopping the old version and starting the new one.

---

## Troubleshooting cheat-sheet

| Problem | Likely cause / fix |
|---|---|
| Deployment group matched **0 instances** | Tag `Name=codedeploy-demo` is missing, or you're looking in the wrong region. |
| Deployment stuck / fails immediately | CodeDeploy agent not running. SSH in and run `sudo systemctl status codedeploy-agent`. |
| "Access Denied" pulling from S3 | The EC2 instance is missing the **`EC2CodeDeployRole`** instance profile. |
| A lifecycle script fails | Check the log on the instance: `cat /opt/codedeploy-agent/deployment-root/deployment-logs/codedeploy-agent-deployments.log` |
| `ApplicationStop` fails on first deploy | Add `|| true` to your stop script (already done above). |
| Agent install URL 404 | The region in the installer URL must match your instance's region. |

---

## Clean up (avoid charges)

When you're done experimenting:

1. **Terminate** the EC2 instance (EC2 Console).
2. **Delete** the S3 bucket contents and bucket.
3. **Delete** the CodeDeploy application.
4. Optionally delete the two IAM roles.

---

## Quick mental model recap

```
Your code  →  appspec.yml + scripts  →  zip  →  S3
                                                  │
                                     CodeDeploy (uses CodeDeployServiceRole)
                                                  │
                                    finds EC2 by tag  →  agent on instance
                                    (instance uses EC2CodeDeployRole)
                                                  │
                                    runs your hooks  →  app is live
```

That's it. Once you understand these moving parts, everything else in CodeDeploy (blue/green deploys, Auto Scaling groups, CI/CD pipelines) is just a variation on this same flow.
