# 🛰️ AquaSentinel — EU Space for Water

**11th CASSINI Hackathon**

> Real-time water quality monitoring and environmental risk assessment powered by Copernicus Sentinel satellite data.

---

## 🌊 The Problem

European rivers, lakes, and deltas face increasing threats from floods, chemical pollution, eutrophication, and climate-induced temperature anomalies. Traditional ground-based monitoring is sparse, slow, and expensive — leaving critical water bodies unprotected.

## 🚀 Our Solution

AquaSentinel combines **Copernicus satellite intelligence** with an **AI-assisted risk analysis engine** to deliver:

- 🗺️ **Interactive 3D globe & map** — Explore 10 major European water bodies
- 📡 **Satellite-derived insights** — Sentinel-1 SAR, Sentinel-2 MSI, Sentinel-3 SLSTR
- ⚠️ **Real-time alarm system** — Triggered by threshold breaches in water quality or flood events
- 🔬 **Environmental analysis** — Automated problem detection, cause analysis, prevention measures, and ecosystem impact assessment
- 📊 **Snow cover monitoring** — Track melt rates and their downstream flood risk

## 🖥️ Live Demo

| | Link |
|---|---|
| **Web App** | `https://aqua-sentinel.vercel.app` *(deploy after setup)* |
| **API Docs** | `https://aquasentinel-api.onrender.com/docs` *(deploy after setup)* |
| **API Health** | `https://aquasentinel-api.onrender.com/health` |

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|------------|
| **Frontend** | Flutter Web, Flutter Map, 3D Globe, Riverpod |
| **Backend** | Python, FastAPI, Pydantic |
| **Data** | Copernicus Data Space, Sentinel Hub, Mock Satellite Scenarios |
| **Deploy** | Render (Docker), Vercel (Static), GitHub Actions CI/CD |

---

## 📸 Features

### 🌍 3D Globe & Map
Pan and zoom across Europe to explore water bodies. Click any location to get AI-generated environmental risk analysis.

### 📡 Monitoring Dashboard
- Water quality readings (pH, turbidity, nitrates, phosphates, dissolved oxygen)
- Sentinel-derived flood extent mapping
- Snow cover melt tracking with downstream risk

### 🔔 Alarm Center
- Active, acknowledged, and resolved alarms
- Threshold-based triggers for water quality and flood events
- Acknowledge and resolve actions with timestamps

### 🧪 Simulator
Run "what-if" scenarios to see how pollution or flood events propagate through catchments.

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

Built with 💙 for the **11th CASSINI Hackathon** — EU Space for Water.
