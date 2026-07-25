# Deploy a Static Website to Amazon S3 with AWS CodePipeline

### A Beginner's Step-by-Step Guide (No Prior CI/CD Experience Needed)

---

## What You're Going to Build

By the end of this tutorial, you'll have an automated pipeline that works like this:

```
You edit your website  →  git push to GitHub  →  CodePipeline notices
        →  CodePipeline copies your files into S3  →  Site is live 🎉
```

Once it's set up, you never manually upload files to AWS again. You just push
your code to GitHub, and your website updates on its own. That "push and it
deploys automatically" idea is what people mean by **CI/CD**.

**Time needed:** about 30 minutes
**Cost:** essentially free (well within the AWS Free Tier for a small site)

---

## A Few Words You'll See (Quick Glossary)

| Term | What it means in plain English |
|------|-------------------------------|
| **S3** | Amazon's file storage. It can also serve those files as a website. |
| **Bucket** | A folder-like container in S3 where your files live. |
| **CodePipeline** | AWS's tool that automates "when code changes, deploy it." |
| **Source stage** | The step where the pipeline grabs your code from GitHub. |
| **Deploy stage** | The step where the pipeline puts your files into S3. |
| **CI/CD** | "Continuous Integration / Continuous Deployment" — auto-deploying on every change. |

---

## Before You Start (Prerequisites)

You'll need three things:

1. An **AWS account** — sign up at https://aws.amazon.com if you don't have one.
2. A **GitHub account** with a repository for your website.
3. Your **website files** (at minimum, one `index.html`).

---

## Part 1 — Put Your Website Code on GitHub

Your repository only needs your plain website files. **No AWS config files, no
YAML.** With CodePipeline, all the pipeline settings live inside AWS, not in
your repo.

A minimal repo looks like this:

```
my-website/
├── index.html
├── style.css
└── script.js
```

### Test files you can copy

If you don't have a site yet, use these to test the whole pipeline.

**index.html**
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>My CI/CD Site</title>
  <link rel="stylesheet" href="style.css">
</head>
<body>
  <h1>Hello from CodePipeline 🚀</h1>
  <p>This site was deployed automatically to S3.</p>
  <script src="script.js"></script>
</body>
</html>
```

**style.css**
```css
body {
  font-family: system-ui, sans-serif;
  text-align: center;
  margin-top: 15vh;
  background: #0f172a;
  color: #f8fafc;
}
h1 { font-size: 2.5rem; }
```

**script.js**
```javascript
console.log("Deployed via AWS CodePipeline");
```

> ⚠️ **Golden rule:** `index.html` must sit at the **root** of your repo, not
> inside a subfolder. CodePipeline copies your files straight into the bucket,
> so if `index.html` is buried in a folder, your website won't find it.

Push these files to your GitHub repo's `main` branch.

---

## Part 2 — Create and Configure the S3 Bucket

This is where your website will actually live.

### 2.1 — Create the bucket

1. Sign in to the AWS Console and open the **S3** service.
2. Click **Create bucket**.
3. Give it a **globally unique name** (e.g. `my-website-yourname-2026`).
4. Pick a **region** and remember it — you'll use the *same* region later.
5. Leave other settings for now and click **Create bucket**.

### 2.2 — Turn on website hosting

1. Click into your new bucket → **Properties** tab.
2. Scroll to the bottom: **Static website hosting** → **Edit**.
3. Choose **Enable**.
4. Set **Index document** to `index.html`.
5. (Optional) Set **Error document** to `error.html`.
6. Click **Save changes**.
7. Scroll back down — you'll see a **Bucket website endpoint** URL. **Copy it.**
   That's your live website address.

### 2.3 — Make the bucket public

By default, S3 hides everything. A public website needs to allow read access.

1. Go to the **Permissions** tab.
2. Under **Block public access**, click **Edit** → **uncheck** "Block all
   public access" → **Save** and confirm.
3. Still on Permissions, find **Bucket policy** → **Edit** → paste the policy
   below.

**Replace `YOUR-BUCKET-NAME` with your real bucket name:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadForWebsite",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::YOUR-BUCKET-NAME/*"
    }
  ]
}
```

4. Click **Save changes**.

> 💡 **What this does:** it lets anyone *read* (view) your files — exactly what
> a public website needs. It does **not** let anyone change or upload files.

---

## Part 3 — Create the Pipeline

Now we connect GitHub → S3 with CodePipeline.

> ⚠️ **Check your region!** In the top-right of the AWS Console, make sure
> you're in the **same region** as your S3 bucket before you start.

### 3.1 — Start creating

1. Open the **CodePipeline** service in the AWS Console.
2. Click **Create pipeline**.

### 3.2 — Pipeline settings

1. **Pipeline name:** something like `deploy-my-website`.
2. If asked for a pipeline category, choose the standard **Build custom pipeline** option.
3. **Service role:** choose **New service role** (AWS sets up the permissions
   for you automatically — easiest option).
4. Leave **Artifact store** on **Default location**.
5. Click **Next**.

### 3.3 — Source stage (connect GitHub)

1. **Source provider:** choose **GitHub (via GitHub App)**.
   *(AWS calls the underlying feature "CodeConnections." Older guides call it
   "GitHub Version 2" — same thing.)*
2. Click **Connect to GitHub**.
3. Give the connection a name, then **authorize** AWS to access GitHub.
   - If prompted, click **Install a new app** and allow access to your repo.
4. Back in CodePipeline, select your **repository** and **branch** (`main`).
5. Keep the default trigger settings and click **Next**.

### 3.4 — Build stage (skip it!)

A plain HTML/CSS/JS site doesn't need building.

- Click **Skip build stage** → confirm.

> 🛠️ You'd only add a build stage (using **CodeBuild**) if your site needs
> compiling first — like a React, Vue, Vite, or Hugo project. See the note at
> the end.

### 3.5 — Deploy stage (send files to S3)

1. **Deploy provider:** choose **Amazon S3**.
2. **Region:** the region your bucket is in.
3. **Bucket:** select your website bucket from Part 2.
4. ✅ **CHECK THE BOX:** **"Extract file before deploy."**
5. Leave the deployment path blank so files land at the bucket root.
6. Click **Next**.

> 🚨 **The #1 mistake beginners make:** forgetting to check **"Extract file
> before deploy."** If you skip it, S3 receives a *zipped* file instead of your
> actual website, and your page will be broken or try to download. If your
> deploy "succeeds" but the site doesn't work — this box is why.

### 3.6 — Create it

1. Review everything on the summary page.
2. Click **Create pipeline**.

---

## Part 4 — Watch Your First Deployment

The pipeline runs **automatically** the moment you create it.

- You'll see the **Source** stage turn green ✅
- Then the **Deploy** stage turn green ✅

Once both are green, open the **Bucket website endpoint** URL you copied in
Step 2.2. Your website is live on the internet! 🎉

---

## Part 5 — The Magic: Automatic Updates

From now on, you're done with manual work. To update your live site:

1. Edit a file (try changing the text in `index.html`).
2. Commit and push to GitHub:
   ```bash
   git add .
   git commit -m "Update homepage text"
   git push origin main
   ```
3. Wait about a minute, refresh your website — your change is live.

CodePipeline detected the push, grabbed the new code, and redeployed it. You
never had to log in to AWS. **That's CI/CD.** 🚀

---

## Troubleshooting (Common Beginner Issues)

| Problem | Likely cause & fix |
|---------|-------------------|
| Site shows **"Access Denied"** or XML | Public access still blocked, or bucket policy missing. Recheck Step 2.3. |
| Deploy is green but page is **broken / downloads a file** | You forgot **"Extract file before deploy."** Edit the Deploy stage and enable it. |
| Website endpoint shows **404 / Not Found** | `index.html` isn't at the bucket root, or its name doesn't match the index document. Keep files flat in the repo. |
| Pipeline **can't connect to GitHub** | The GitHub App connection wasn't authorized. Redo Step 3.3 and make sure the app can access your repo. |
| Nothing happens when I push | Make sure you pushed to the **same branch** the pipeline watches (`main`). |

---

## Where to Go Next (Optional Upgrades)

Once your basic pipeline works, here are natural next steps:

- **Add HTTPS + a custom domain:** put **Amazon CloudFront** in front of your
  bucket. This gives you `https://` and a real domain name instead of the long
  S3 endpoint URL.
- **Deploy a framework site (React, Vue, Hugo):** add a **CodeBuild** stage
  between Source and Deploy, with a small `buildspec.yml` file telling it how to
  build (e.g. `npm install` then `npm run build`), and point the Deploy stage at
  your `build`/`dist` output folder.
- **Add a manual approval step:** make the pipeline pause and wait for you to
  click "Approve" before it deploys to production.

---

## Quick Recap

You just learned how to:

1. ✅ Host a static website on Amazon S3
2. ✅ Connect a GitHub repo to AWS with CodePipeline
3. ✅ Automatically deploy your site on every `git push`
4. ✅ Troubleshoot the most common beginner mistakes

Congratulations — you've built a real CI/CD pipeline! 🎓
