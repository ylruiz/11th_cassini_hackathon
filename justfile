# AquaSentinel — 11th CASSINI Hackathon: EU Space for Water
# Usage: just <recipe>

# ── Flutter app ──────────────────────────────────────────────────────────────

app-get:
    cd apps/aqua_sentinel && flutter pub get

app-gen:
    cd apps/aqua_sentinel && dart run build_runner build --delete-conflicting-outputs

app-gen-watch:
    cd apps/aqua_sentinel && dart run build_runner watch --delete-conflicting-outputs

app-run target="web":
    cd apps/aqua_sentinel && flutter run -d {{target}}

app-run-web:
    cd apps/aqua_sentinel && flutter run -d web-server --web-port 3000

app-build-web:
    cd apps/aqua_sentinel && flutter build web --release

app-deploy-web:
    ./scripts/deploy-fe.sh

app-test:
    cd apps/aqua_sentinel && flutter test

app-lint:
    cd apps/aqua_sentinel && flutter analyze

# ── space_data package ───────────────────────────────────────────────────────

pkg-get:
    cd packages/space_data && flutter pub get

pkg-test:
    cd packages/space_data && flutter test

pkg-lint:
    cd packages/space_data && flutter analyze

# ── Python API ───────────────────────────────────────────────────────────────

api-install:
    cd services/api && python3 -m venv .venv && .venv/bin/pip install -r requirements.txt

api-dev:
    cd services/api && .venv/bin/uvicorn main:app --reload --host 0.0.0.0 --port 8000

api-start:
    cd services/api && .venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000

api-docs:
    open http://localhost:8000/docs

# ── Combined ─────────────────────────────────────────────────────────────────

pub-get-all:
    just app-get && just pkg-get

gen:
    just app-gen

gen-watch:
    just app-gen-watch

setup:
    just pub-get-all && just api-install && just gen

# Run API + Flutter web in parallel (requires tmux or background jobs)
dev:
    just api-dev &
    just app-run-web
