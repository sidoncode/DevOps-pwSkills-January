# CI/CD Pipeline Tutorial
### GitHub → AWS CodePipeline → ECR → ECS (Fargate)

A hands-on, beginner-friendly tutorial. By the end, you'll have a real pipeline: push code to GitHub, and AWS automatically builds it, stores it, and runs it live — no manual deploys.

**Estimated time:** 45–60 minutes

---

## 📖 Glossary (read this first)

| Term | What it means |
|---|---|
| **GitHub** | Where your source code lives |
| **ECR** (Elastic Container Registry) | Storage for your Docker images |
| **CodeBuild** | Builds your Docker image and pushes it to ECR |
| **CodePipeline** | Connects everything and runs it automatically on every push |
| **ECS** (Elastic Container Service) | Runs your app, live |
| **Fargate** | Runs ECS containers without you managing any servers |
| **Task definition** | A blueprint describing your container (image, CPU, memory, port) |
| **Service** | Keeps your task running continuously, restarts it if it crashes |

**The flow, in one sentence:**
> You push code to GitHub → CodePipeline notices → CodeBuild builds a Docker image and pushes it to ECR → CodePipeline tells ECS to run the new image.

---

## ⚠️ Three Things That Break This Pipeline (read before you start)

These are the three real issues most people hit. Knowing them up front will save you a lot of time.

1. **Names must match exactly, everywhere.** Your ECR repo name, your task definition's container name, and `CONTAINER_NAME` in `buildspec.yml` must all be *identical* — same spelling, same case. A mismatch here is the #1 cause of pipeline failures, and AWS's error message for it (`The AWS ECS container <name> does not exist`) only shows up in the Deploy stage, not the Build stage — so it's easy to miss.
2. **`$AWS_ACCOUNT_ID` is not automatic.** CodeBuild gives you `$AWS_DEFAULT_REGION` for free, but not your account ID. The buildspec in this tutorial handles it for you (see Part 4) — just don't delete that line.
3. **"Run Task" ≠ "Create Service."** ECS has two similar-looking pages. Run Task launches a container once and stops. Create Service keeps it running and is what CodePipeline deploys to. Always use **Create Service**.

Keep these three in mind as you go — they're called out again at the exact steps where they matter.

---

## ✅ Prerequisites

- [ ] AWS account
- [ ] AWS CLI installed and configured (`aws configure`) — optional, console works too
- [ ] GitHub account
- [ ] Docker installed — optional, only needed to test locally

---

## Part 1 — Create the Sample App

A minimal Node.js app: 3 files total.

### 1.1 Create a project folder
```bash
mkdir sample-cicd-app
cd sample-cicd-app
```

### 1.2 Create `app.js`
```javascript
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
  res.send('Hello from my CI/CD Pipeline! Version 1');
});

app.listen(port, () => console.log(`App running on port ${port}`));
```

### 1.3 Create `package.json`
```json
{
  "name": "sample-cicd-app",
  "version": "1.0.0",
  "main": "app.js",
  "scripts": { "start": "node app.js" },
  "dependencies": { "express": "^4.19.2" }
}
```

### 1.4 Create `Dockerfile`
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### ✔️ Checkpoint
```
sample-cicd-app/
├── app.js
├── package.json
└── Dockerfile
```

*(Optional)* Test locally:
```bash
docker build -t sample-cicd-app .
docker run -p 3000:3000 sample-cicd-app
# open http://localhost:3000
```

---

## Part 2 — Push to GitHub

### 2.1 Create an empty repo
On github.com: **New repository** → name `sample-cicd-app` → do **not** add a README → **Create repository**.

### 2.2 Push your code
```bash
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<your-username>/sample-cicd-app.git
git push -u origin main
```

### ✔️ Checkpoint
Refresh your GitHub repo — you should see all 3 files.

---

## Part 3 — Create an ECR Repository (image storage)

### 3.1 Create the repository
**Console:** ECR → Repositories → **Create repository** → name: `sample-cicd-app` → Create

**CLI:**
```bash
aws ecr create-repository --repository-name sample-cicd-app --region <your-region>
```

### ✔️ Checkpoint
Copy the **Repository URI**:
```
<account-id>.dkr.ecr.<region>.amazonaws.com/sample-cicd-app
```
You'll need this in Part 5.

> 💡 Click **"View push commands"** on the repository page — AWS gives you the exact login/build/tag/push commands pre-filled with your account ID and region.

---

## Part 4 — Add the Build Instructions

### 4.1 Create `buildspec.yml`
Place this in the **root** of your project (same folder as `Dockerfile`):

```yaml
version: 0.2

env:
  variables:
    IMAGE_REPO_NAME: "sample-cicd-app"
    CONTAINER_NAME: "sample-cicd-app"

phases:
  pre_build:
    commands:
      - echo Logging in to ECR...
      - AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
      - aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com
      - REPOSITORY_URI=$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/$IMAGE_REPO_NAME
      - IMAGE_TAG=$(echo $CODEBUILD_RESOLVED_SOURCE_VERSION | cut -c 1-7)

  build:
    commands:
      - echo Building Docker image...
      - docker build -t $REPOSITORY_URI:$IMAGE_TAG .
      - docker tag $REPOSITORY_URI:$IMAGE_TAG $REPOSITORY_URI:latest

  post_build:
    commands:
      - echo Pushing Docker image to ECR...
      - docker push $REPOSITORY_URI:$IMAGE_TAG
      - docker push $REPOSITORY_URI:latest
      - printf '[{"name":"%s","imageUri":"%s"}]' $CONTAINER_NAME $REPOSITORY_URI:$IMAGE_TAG > imagedefinitions.json

artifacts:
  files:
    - imagedefinitions.json
```

**What each part does:**
- `pre_build` — logs in to ECR, and works out your account ID and a short image tag from the git commit hash
- `build` — builds the Docker image from your `Dockerfile`
- `post_build` — pushes the image to ECR, then writes `imagedefinitions.json`, a small file that tells CodePipeline exactly which image to deploy
- `CONTAINER_NAME` here **must exactly match** the container name you'll set in Part 5 — see the warning at the top of this tutorial

### 4.2 Push it
```bash
git add buildspec.yml
git commit -m "Add buildspec"
git push
```

---

## Part 5 — Set Up ECS (where your app runs)

We'll use **Fargate**, so there are no servers to manage.

### 5.1 Create a cluster
**Console:** ECS → Clusters → **Create cluster** → name `sample-cicd-cluster` → infrastructure: **Fargate** → Create

**CLI:**
```bash
aws ecs create-cluster --cluster-name sample-cicd-cluster
```

### 5.2 Task execution role
This lets ECS pull images from ECR and write logs. The ECS console **creates this automatically** (`ecsTaskExecutionRole`) the first time you create a task definition — you usually don't need to do anything here.

Only needed manually if the console doesn't offer to create it:
```bash
aws iam create-role --role-name ecsTaskExecutionRole \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ecs-tasks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

aws iam attach-role-policy --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

### 5.3 Create the Task Definition

> 🎯 **Critical step.** The container name you set here must **exactly match** `CONTAINER_NAME` in `buildspec.yml`. Write it down. Case-sensitive.

**Console:**
1. ECS → **Task definitions** → **Create new task definition**
2. Family name: `sample-cicd-task`
3. Launch type: **Fargate**
4. CPU: 0.25 vCPU, Memory: 0.5 GB
5. Container name: `sample-cicd-app` ← must match `buildspec.yml`'s `CONTAINER_NAME`
6. Image URI: your ECR Repository URI from Part 3, with `:latest` appended:
   ```
   <account-id>.dkr.ecr.<region>.amazonaws.com/sample-cicd-app:latest
   ```
7. Container port: `3000`
8. Leave the rest default → **Create**

> The image doesn't exist in ECR yet — that's fine, CodePipeline pushes it in Part 7.

> 💡 **Can't find "Image URI"?** It's inside a **"Container - 1"** section further down the page, not on the first screen with family/CPU/memory. If there's a **"Configure via JSON"** toggle near the top, you can also just paste this instead (works identically, and is immune to console layout changes):
> ```json
> {
>   "family": "sample-cicd-task",
>   "networkMode": "awsvpc",
>   "requiresCompatibilities": ["FARGATE"],
>   "cpu": "256",
>   "memory": "512",
>   "executionRoleArn": "ecsTaskExecutionRole",
>   "containerDefinitions": [
>     {
>       "name": "sample-cicd-app",
>       "image": "<account-id>.dkr.ecr.<region>.amazonaws.com/sample-cicd-app:latest",
>       "portMappings": [{ "containerPort": 3000, "protocol": "tcp" }],
>       "essential": true
>     }
>   ]
> }
> ```

### 5.4 Create the Service

> ⚠️ ECS has two similar pages: **"Run Task"** (runs once, then stops) and **"Create Service"** (stays running, and is what CodePipeline updates). Use Create Service:
> ECS → Clusters → `sample-cicd-cluster` → **Services** tab → **Create**

1. Task definition family: `sample-cicd-task` → revision: **Latest**
2. Environment: **AWS Fargate**, existing cluster
3. Service name: `sample-cicd-service`
4. Desired tasks: `1`
5. Networking:
   - VPC: default is fine
   - Subnets: leave all selected
   - Security group: allow inbound **Custom TCP, port 3000, source Anywhere (0.0.0.0/0)** — edit the default security group's rules, or create a new one
   - Public IP: **Turned on**
6. **Create**

### ✔️ Checkpoint
Cluster → Services tab → `sample-cicd-service` shows status `ACTIVE` (0/1 running tasks is expected until Part 7 deploys a real image).

---

## Part 6 — Connect GitHub to AWS

1. **Developer Tools → Settings → Connections → Create connection**
2. Provider: **GitHub** → name: `github-connection` → **Connect to GitHub**
3. A popup asks you to authorize the AWS Connector for GitHub → sign in → select your `sample-cicd-app` repo (or all repos) → **Install**
4. Back in the console, click **Connect**
5. Confirm status shows **Available**. If stuck on **Pending**, refresh the page.

One-time setup, reusable for future pipelines.

---

## Part 7 — Create the Pipeline

### 7.1 Start the wizard
CodePipeline → **Create pipeline** → name: `sample-cicd-pipeline` → Service role: **New service role** → Next

### 7.2 Source stage
- Source provider: **GitHub (via GitHub App)**
- Connection: `github-connection`
- Repository: `sample-cicd-app`, Branch: `main`
- Keep "Start the pipeline on source code change" **checked** — this is what makes Part 9 automatic
- Next

### 7.3 Build stage
- Build provider: **AWS CodeBuild**
- **Create project:**
  - Name: `sample-cicd-build`
  - Environment image: Managed image, Amazon Linux, Standard runtime
  - ✅ Check **"Privileged"** — required for building Docker images
  - Buildspec: **Use a buildspec file** (auto-detects `buildspec.yml`)
- Save → Next

> ⚠️ **Do this right after creating the project:** CodeBuild's auto-generated role can pull from ECR but not push. Go to **IAM → Roles**, find `codebuild-sample-cicd-build-service-role`, and attach the **`AmazonEC2ContainerRegistryPowerUser`** policy. Skipping this causes a "no basic auth credentials" error on push.

### 7.4 Deploy stage
- Deploy provider: **Amazon ECS**
- Cluster: `sample-cicd-cluster`
- Service: `sample-cicd-service`
- Image definitions file: `imagedefinitions.json` (default)
- Next → **Create pipeline**

### ✔️ Checkpoint
The pipeline runs immediately. Watch all three stages turn green:
```
Source ✅  →  Build ✅  →  Deploy ✅
```
Takes 3–5 minutes the first time. If Deploy fails with a container name error, go back to the warning in 5.3/4.1 — the names don't match yet.

---

## Part 8 — See It Live

1. ECS → Clusters → `sample-cicd-cluster` → Services → `sample-cicd-service` → **Tasks**
2. Click the running task → **Networking** tab → copy the **Public IP**
3. Open `http://<public-ip>:3000` in your browser
4. You should see:
   ```
   Hello from my CI/CD Pipeline! Version 1
   ```

---

## Part 9 — Prove the Automation Works

1. Edit `app.js`:
   ```javascript
   res.send('Hello from my CI/CD Pipeline! Version 2 🚀');
   ```
2. Push:
   ```bash
   git add app.js
   git commit -m "Update to v2"
   git push
   ```
3. Watch CodePipeline start automatically within seconds.
4. Once green, refresh the same public IP.
5. You'll see **"Version 2 🚀"** — no manual deploy step needed.

---

## 🧯 Troubleshooting

| Problem | Fix |
|---|---|
| Build fails: "permission denied" pushing to ECR | Attach `AmazonEC2ContainerRegistryPowerUser` to the CodeBuild role (Part 7.3) |
| Build fails: "docker: not found" or permission errors | Make sure **"Privileged"** is checked on the CodeBuild project |
| ECR login fails: `dial tcp: lookup .dkr.ecr.<region>.amazonaws.com: no such host` | `$AWS_ACCOUNT_ID` came back empty — confirm the `AWS_ACCOUNT_ID=$(aws sts get-caller-identity ...)` line is present in `pre_build` (Part 4) |
| Deploy fails: "The AWS ECS container `<name>` does not exist" | Container name mismatch — `CONTAINER_NAME` in `buildspec.yml` must exactly match the container name in your task definition (Part 5.3) |
| Task stuck in a restart loop: `CannotPullContainerError ... not found` | Usually downstream of the row above — Deploy never actually succeeded. Fix the name mismatch, push again, and this clears on its own |
| Ended up on "Run Task" instead of "Create Service" | Cluster → **Services** tab (not Tasks) → Create |
| Deploy fails: can't find `imagedefinitions.json` | Confirm `buildspec.yml`'s `artifacts` section matches Part 4 exactly |
| Can't reach the app in browser | Check the security group allows inbound TCP on port `3000` |
| GitHub connection stuck on "Pending" | Refresh the page — status sometimes lags behind the popup finishing |
| Pipeline doesn't start after a push | Confirm "Start the pipeline on source code change" was checked (7.2), and you pushed to `main` |
| Everything looks right but still fails | Check every service (ECR, ECS, CodeBuild, CodePipeline) is in the **same AWS region** |

---

## Summary

| Step | What happened | Tool |
|---|---|---|
| 1 | Wrote a tiny app + Dockerfile | Your machine |
| 2 | Pushed code | GitHub |
| 3 | Created image storage | ECR |
| 4 | Defined the build steps | `buildspec.yml` |
| 5 | Created somewhere to run it | ECS + Fargate |
| 6 | Linked GitHub to AWS | GitHub App connection |
| 7 | Wired it all together | CodePipeline |
| 8 | Saw it live | Public IP |
| 9 | Proved it's automatic | Git push → auto-deploy |

**Next steps once this works:**
- Add a Load Balancer for a stable URL that doesn't change on redeploy
- Add a test phase in `buildspec.yml` before the build
- Use separate pipelines for `dev` and `prod` environments

**Clean up when you're done** (to avoid ongoing charges): delete the ECS service, cluster, CodeBuild project, pipeline, and ECR repository.
