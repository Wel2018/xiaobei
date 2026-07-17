# xiaobei — AGENTS.md

xiaobei is a hospital ward inspection robot system. **6 sub-projects in one monorepo.**

## Monorepo layout

```
xiaobei/                        # root = orchestrator
├── AGENTS.md                   # ← this file
├── boot_items.yaml              # config-driven multi-service launcher
├── parse_config.py              # reads boot_items.yaml, emits launch list
├── run-all-terminals.sh / .bat  # one-click start all services
├── release.sh                   # tars xiaobei-backend + ext + frontend
├── updater.sh                   # extracts release tar, swaps sub-projects
├── xiaobei-backend/             # FastAPI, Python 3.11+, port 8000
├── xiaobei-frontend/            # Vue 3 + TS + Vite, port 5173
├── xiaobei-ext/                 # Camera/ext device service, port 8001
├── xiaobei-arm/                 # Robotic arm bridge (ROS 2 + Socket)
├── xiaobei-face/                # Facial expression video player (PySide6)
└── xiaobei-data/maps/           # Map files (.stcm, .bmp) by floor
```

## Boot system

- `run-all-terminals.sh` / `.bat` reads `boot_items.yaml`, uses `parse_config.py` to produce a launch list.
- Each line: `module|script|wait_time|status`.
- `status: skip` skips the module entirely. Per-script skip: `{script_name: skip}`.
- Each sub-project exposes `run.sh` (Linux) and `run.bat` (Windows).
- `boot_items.yaml` defines order: backend → frontend → ext (mediamtx → ext → fall_detector) → arm (skipped by default) → face (skipped by default).

## xiaobei-backend (FastAPI)

### Key files

| File | Purpose |
|------|---------|
| `main.py` | FastAPI app, CORS, route registration |
| `app/core/config.py` | `pydantic-settings` — env-driven |
| `app/core/database.py` | `DatabaseHelper` — wrapper around SQLModel/SQLAlchemy |
| `app/core/async_utils.py` | `run_with_timeout()` + `run_parallel()` |
| `app/hardware/agv/` | Strategy pattern: `slamtech.py`, `yunji.py`, `fake.py` |
| `app/hardware/arm/` | Strategy pattern: `realman.py`, `ruigan.py`, `fake.py` |
| `dist/slamtech_client/` | OpenAPI-generated client for SlamTech AGV |

### Routes (all under `/api/v1`)

| Prefix | Source | Tags |
|--------|--------|------|
| `/api/v1/insp/...` | `app/api/inspection/` — nested router | 巡检相关/* |
| `/api/v1/devices/...` | `app/api/devices/` — nested router | 设备相关/* |
| `/api/v1/nav/...` | `app/api/navigation.py` | 导航任务 |
| `/api/v1/patients/...` | `app/api/patients.py` | 患者管理 |
| `/api/v1/map/...` | `app/api/map_info.py` | 地图 |

- `inspection/` and `devices/` use **nested APIRouter**: `__init__.py` creates a parent router and `include_router`s sub-routers with their own prefixes.
- `sensors.py` for vital signs (legacy, still registered? check main.py — it imports from `app.api` but does NOT include it; it _is_ imported but the router isn't mounted. Beware.)

### Run commands

```bash
cd xiaobei-backend
uv sync                        # first time only
uv run python main.py          # dev
uv run python test_api.py      # test (requires running server)
```

### Hardware config (`.env`)

```
AGV_TYPE=slamtech|yunji|fake    # default: slamtech
ARM_TYPE=realman|ruigan|fake    # default: fake
```

- Hardware controllers implement abstract base classes in `app/hardware/agv/base.py` and `app/hardware/arm/base.py`.
- AGV and arm drivers are selected at runtime via `config.AGV_TYPE` / `config.ARM_TYPE`.

### Database

- SQLite via SQLModel (SQLAlchemy + Pydantic).
- Singleton: `db_helper = DatabaseHelper()` in `app/core/database.py`.
- Model tables: alarm records, inspection tasks, patients, etc. — defined in `app/models/inspection/sqlmodels/`.

### Tests

```bash
cd xiaobei-backend
# Need backend running first. Tests use raw `requests`, not TestClient.
# pytest tests/   (if dev deps installed: `uv sync --group dev`)
```

11 test files in `tests/`. Notable: `test_slamtech_client_api.py` has a hardcoded path to `dist/slamtech_client`.

### Build / generate

```bash
# Regenerate SlamTech API client from OpenAPI spec
bash scripts/gen_slamtech_client.sh
bash scripts/gen_backend_client.sh
```

### Ruff

`ruff.toml`: `select = ["ALL"]` with ~40 ignores. Key suppressed rules: `F401` (unused import), `F841` (unused var), `E501` (line length), `D100/103` (docstrings), `ANN*` (type annotations).

## xiaobei-frontend (Vue 3 + TypeScript + Vite)

### Tech stack

| Tool | Note |
|------|------|
| Vue 3.5 + vue-router 5 | Composition API, `<script setup>` throughout |
| Pinia 3 | State management |
| Vite 8 | Dev server on `:5173` |
| echarts 6 + vue-echarts 8 | Charts on monitor |
| oxlint + oxfmt | Lint & format (NOT ESLint-only) |
| vue-tsc 3 | Type checking |
| vitest 4 | Unit tests |
| playwright | E2E tests |
| sass-embedded 1 | SCSS support |
| orval | API client generation (not in current use?) |

### Run & build

```bash
cd xiaobei-frontend
npm install           # first time
npm run dev            # vite dev :5173
npm run build          # vue-tsc -b && vite build
npm run lint           # oxlint + eslint
npm run format         # oxfmt src/
npm run test:unit      # vitest
npm run test:e2e       # playwright
npm run type-check     # vue-tsc --build  (required before build)
```

- No Vite proxy — frontend calls backend/ext directly at `http://<ip>:8000` and `http://<ip>:8001`.
- IP is dynamic, stored in `localStorage`, managed by `useApiConfigStore` in `src/stores/apiConfig.ts`.
- Axios instances created per-component via `createAxiosInstance()` in `src/utils/axios.ts` — each instance has independent timeout + AbortController.

### Routes

| Path | View | Auth |
|------|------|------|
| `/login` | LoginView.vue | no |
| `/` | HomeView.vue | yes |
| `/about` | AboutView.vue | yes |
| `/monitor` | MonitorDashboard.vue | yes |
| `/webrtc` | WebRTCViewer.vue | yes |

- Auth: simple `localStorage.getItem('user')` check in router guard.

### Directory structure (src/)

```
src/
├── api/            # API call functions (auto-generated from orval?)
├── components/
│   └── monitor/    # Monitor dashboard components (layout/, map/, dialogs/)
├── composables/    # useLogger, useMapImage, useConfirm, etc.
├── model/          # Generated TS model types (backend/, ext/)
├── router/         # Vue Router config
├── stores/         # Pinia stores (apiConfig, mapFocus, robotMode, counter)
├── utils/          # axios, map helpers
└── views/          # Page-level views
```

## xiaobei-ext (Camera service)

- FastAPI on port `8001`.
- RealSense D455 + USB camera support, WebSocket video streaming, WebRTC.
- `app/services/camera_manager.py` — device scanning with 5-min cache (`.camera_cache.json`).
- `app/services/camera_webrtc_service.py` — WebRTC stream handling.
- Requires `pyrealsense2` (only available on x86 with RealSense hardware).
- `ultralytics` for YOLO fall detection, `aiortc` for WebRTC.

## xiaobei-arm (Robotic arm)

- ROS 2 + socket bridge + FastAPI wrapper.
- Three-step startup: `1_run_ros.sh` (ROS driver) → `2_run_srv.sh` (socket middleware) → `3_run_fastapi.sh` (HTTP API).
- `AGV_ERROR_HANDLER_DECORATOR.md` and `ROBOTIC_ARM_API.md` in backend docs for integration details.

## xiaobei-face (Facial expressions)

- PySide6 + python-vlc video player.
- Plays looping MP4 files from `videos/`.
- Python >= 3.13 required.
- Keyboard: `F` fullscreen, `Space` pause, arrow keys volume/speed.

## Important quirks

1. **Root `.gitignore` ignores all `xiaobei-*/**`** — each sub-project is a separate git repo. The root only tracks config files, scripts, and doc/.
2. **UV is mandatory** — all sub-projects with Python use `pyproject.toml` + `uv sync`. Never use `pip install` directly.
3. **Aliyun PyPI mirror** — configured in each `pyproject.toml` under `[[tool.uv.index]]`.
4. **AGV_TYPE defaults to `slamtech`** — if you need to test without hardware, set `AGV_TYPE=fake` in `.env`.
5. **Backend `webapp.py`** — launches a PyWebView window pointing at the frontend dev server. Not used in production.
6. **Map files** stored in `xiaobei-data/maps/` by floor (e.g. `hospital_one_12F/`).
7. **`ruff.toml` at root** applies to `xiaobei-backend/` only — each sub-project has its own lint config or none.
8. **Frontend uses `npm-run-all2`** — `npm run build` runs type-check and vite build in parallel.
9. **TypeScript 6.0** — very modern, ensure tools support it.
10. **No auth middleware** on backend — the frontend login check is client-only localStorage.
