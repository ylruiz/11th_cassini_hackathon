# 🛰️ AquaSentinel — Long-Term Flood & Landslide Risk Prediction

**11th CASSINI Hackathon — Team Aquaorbitals**

> Satellite-powered river system modelling that predicts flood and landslide risk decades ahead — turning reactive emergency response into proactive, data-driven prevention for local authorities and insurers.

---

## 💰 The Business Problem

Floods and landslides have dramatic economic consequences across Europe:

- **Vienna flooding 2024** → costs of **~€1.5 billion**
- **Tyrol** invests around **€60 million per year** in wild-water prevention
- **Blatten, Switzerland** → **20–80 million people** affected by basin-level flooding

Existing solutions only offer **short-term prediction** — last-minute evacuations, emergency response, damage control. Local authorities and insurance companies are left reacting to disasters they could have foreseen and prevented.

**The question we answer:** *How do river systems change — and where will be at risk in 10, 20, 30, 50 years?*

---

## 🚀 Our Solution

AquaSentinel combines **Copernicus Sentinel satellite data** with **hydrological and climate models** to deliver **long-term prediction of flood and landslide-prone areas**.

Instead of "what is happening right now," we answer **"what will happen, where, and what will it cost?"**

| Horizon | What we predict |
|---------|-----------------|
| **Today** | Current risk baseline from Sentinel-1 SAR, Sentinel-2 MSI, Sentinel-3 SLSTR |
| **+10 years** | Moderate risk increase zones |
| **+20 years** | High-risk zone expansion |
| **+30 years** | Critical threshold crossings |
| **+40–50 years** | Catastrophic exposure scenarios |

### For Local Authorities
- Identify which villages and infrastructure will be in danger *before* it happens
- Plan prevention budgets with ROI data (prevention vs. cost of inaction)
- Prioritize wetland restoration, floodplain management, and early warning systems

### For Insurance Companies
- Model portfolio risk across decades, not seasons
- Price premiums based on projected exposure, not just historical claims
- Identify underpriced regions and accumulation risks early

---

## 🖥️ Live Demo

| | Link |
|---|---|
| **Web App** | `https://aquasentinel-gold.vercel.app/` *(deploy after setup)* |
| **API Docs** | `https://one1th-cassini-hackathon.onrender.com/docs` *(deploy after setup)* |
| **API Health** | `https://one1th-cassini-hackathon.onrender.com/docs#/default/health_check_health_get` |

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter Web, Flutter Map, 3D Globe, Riverpod |
| **Backend** | Python, FastAPI, Pydantic |
| **Data** | Copernicus Data Space, Sentinel-1/2/3, Climate Projection Models |
| **Deploy** | Render (Docker), Vercel (Static), GitHub Actions CI/CD |

---

## 📸 Features

### 🌍 Risk Command Center
An executive dashboard showing:
- **Total economic exposure** across monitored watersheds
- **Population at risk** today and in future scenarios
- **Priority risk hotspots** with exposure metrics and prevention ROI
- **Long-term projection timeline** (Today → +50 years)

### 🗺️ Interactive Monitoring & Simulation
- Explore 10 major European water bodies on an interactive map
- Click any hotspot to open **automated environmental analysis**
- Run **"what-if" simulations** to model how pollution, flooding, drought, or snow melt propagate through catchments over time

### 🔬 Environmental Analysis Engine
For each selected region, the system generates:
- **Problems** — detected issues with severity and source
- **Causes** — primary causes and contributing factors
- **Prevention** — feasibility, timeline, estimated cost, and cost if nothing is done
- **Impact** — ecosystem damage, affected species, recovery potential

### 🔴 Smart Alert System
- Threshold-based and anomaly-driven alerts
- Economic impact statements for every alert (€ exposure, people at risk)
- Recommended actions for authorities and utilities

---

## 🏃 Quick Start (Local)

```bash
# Setup everything
just setup

# Run backend
just api-start

# Run frontend
just app-run-web
```

---

## 🚀 Deploy

See [`DEPLOY.md`](DEPLOY.md) for full CI/CD setup.

```bash
# Push triggers auto-deploy for both frontend and backend
git push origin main
```

---

## 👥 Team

Built with 💙 by **Team Aquaorbitals** for the **11th CASSINI Hackathon** — EU Space for Water.
