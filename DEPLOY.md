# 🚀 Deployment Guide — AquaSentinel

Full CI/CD: every push to `main` auto-deploys the **backend** (Render) and **frontend** (Vercel). Rollback = revert a commit and push.

**Estimated time:** 15 minutes (one-time setup)  
**Cost:** Free

---

## Architecture

| Service | Platform | Deploy Trigger |
|---------|----------|----------------|
| Backend (FastAPI) | Render | Auto on every push to `main` |
| Frontend (Flutter Web) | Vercel | Auto via GitHub Actions on every push to `main` |

---

## One-Time Setup

### Step 1 — Push the deployment configs

```bash
git add .
git commit -m "chore: add Render + Vercel CI/CD"
git push origin main
```

---

### Step 2 — Deploy the Backend (Render)

1. Go to [dashboard.render.com](https://dashboard.render.com)
2. Click **"New +" → "Web Service"**
3. Connect your GitHub repo: `ylruiz/11th_cassini_hackathon`
4. Configure:
   - **Name:** `aquasentinel-api`
   - **Runtime:** `Docker`
   - **Root Directory:** `services/api`
   - **Dockerfile Path:** `./Dockerfile`
   - **Port:** `8000`
5. Click **"Advanced"** and add environment variables:
   ```
   APP_ENV=production
   APP_HOST=0.0.0.0
   APP_PORT=8000
   ```
   *(Optional)* Add Copernicus credentials for real satellite data:
   ```
   COPERNICUS_CLIENT_ID=your-id
   COPERNICUS_CLIENT_SECRET=your-secret
   ```
6. Click **"Create Web Service"**
7. Wait 2–3 minutes for the green checkmark

**Backend URL:** `https://aquasentinel-api.onrender.com`

> ✅ From now on, every push to `main` automatically redeploys the backend.

---

### Step 3 — First Manual Frontend Deploy (to get Vercel IDs)

You need to create the Vercel project once to get the secrets for CI/CD.

```bash
# Update env with live backend URL
echo "API_BASE_URL=https://aquasentinel-api.onrender.com" > apps/aqua_sentinel/.env

# Build and deploy
just app-deploy-web
```

Answer Vercel's prompts:
- **Link to existing project?** → `N`
- **Project name?** → `aqua-sentinel`

Copy the deployed URL (e.g., `https://aqua-sentinel.vercel.app`).

---

### Step 4 — Get Vercel Secrets for CI/CD

```bash
# Read the Vercel project IDs from the local config
cat apps/aqua_sentinel/build/web/.vercel/project.json
```

You'll see something like:
```json
{"orgId":"team_xxxxxxxxxxxx","projectId":"prj_xxxxxxxxxxxx"}
```

Now go to [vercel.com/account/tokens](https://vercel.com/account/tokens) and create a new token.

Then add these 3 secrets to your GitHub repo:
1. Go to your repo → **Settings → Secrets and variables → Actions**
2. Click **"New repository secret"** and add:
   - `VERCEL_TOKEN` — the token you just created
   - `VERCEL_ORG_ID` — the `orgId` from `project.json`
   - `VERCEL_PROJECT_ID` — the `projectId` from `project.json`

> ✅ From now on, every push to `main` automatically builds and deploys the frontend.

---

## 🔄 Normal Workflow (after setup)

**Make a change:**
```bash
git add .
git commit -m "fix: whatever"
git push origin main
```

**What happens automatically:**
1. Render sees the push → rebuilds and deploys the backend (~3 min)
2. GitHub Actions triggers → builds Flutter web and deploys to Vercel (~5 min)

---

## ↩️ Rollback

Found a bug during the demo? Revert and push:

```bash
git revert HEAD
git push origin main
```

Both Render and Vercel will automatically redeploy the previous version.

---

## ✅ Verification Checklist

- [ ] Backend `/health` returns `{"status":"ok"}`
- [ ] Backend `/docs` shows Swagger UI
- [ ] Frontend loads at Vercel URL
- [ ] Map and data panels show water-body information
- [ ] Refreshing on `/alarms` or `/monitoring` works (no 404)
- [ ] Pushing a new commit auto-redeploys both services

---

## 🛠 Troubleshooting

### GitHub Actions fails with "No vercel credentials found"
You forgot to add the 3 secrets (`VERCEL_TOKEN`, `VERCEL_ORG_ID`, `VERCEL_PROJECT_ID`). Add them in GitHub repo settings.

### Render build fails
Test the Docker build locally:
```bash
cd services/api && docker build -t aquasentinel-api:test .
```

### Flutter build fails in CI
The workflow uses the latest stable Flutter. If you need a specific version, pin it in `.github/workflows/deploy-frontend.yml`.

### CORS errors
Verify `API_BASE_URL` in the GitHub Actions workflow matches your actual Render URL (no trailing slash).

---

## ⚡ Emergency Fallback: ngrok (5 min)

If cloud deployment hits snags right before judging:

**Terminal 1 — Backend:**
```bash
just api-start
```

**Terminal 2 — Tunnel:**
```bash
ngrok http 8000
```

**Terminal 3 — Frontend:**
```bash
echo "API_BASE_URL=https://xxxx.ngrok-free.app" > apps/aqua_sentinel/.env
just app-deploy-web
```

Then share the Vercel URL as usual.

---

## 📝 Post-Hackathon

- **Render:** Free tier spins down after 15 min of inactivity. Delete or upgrade after the event.
- **Vercel:** Hobby tier is free forever. Keep the frontend live as a portfolio piece.
- **CI/CD:** The GitHub Actions workflow stays active. Disable it in repo Settings → Actions if needed.
