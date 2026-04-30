# backend

FastAPI service that bridges Athena and the React dashboard. Runs locally (or anywhere with AWS credentials) and exposes six REST endpoints that the SENTINEL UI consumes.

## Why this exists

A React app cannot safely query Athena directly — doing so would require shipping AWS credentials to the browser, which is a security violation. This thin Python service queries Athena server-side and returns clean JSON. It also reshapes the data to match the exact field names the UI components expect.

## Tech

- Python 3.11
- FastAPI — REST framework
- PyAthena — Athena client (uses boto3 under the hood)
- Uvicorn — ASGI server
- python-dotenv — env file loading

## Run it

```bash
cd backend
python -m venv venv
venv\Scripts\activate          # Windows PowerShell
# source venv/bin/activate     # macOS / Linux

pip install -r requirements.txt
cp .env.example .env           # if .env.example exists
# otherwise create .env manually (see below)

uvicorn main:app --reload --port 8000
```

When the server starts you'll see:

```
[CONFIG] region=eu-north-1 db=aml_db s3=s3://...
INFO:     Uvicorn running on http://127.0.0.1:8000
```

## Configuration

Create a `.env` file in `backend/`:

```env
AWS_REGION=eu-north-1
ATHENA_DATABASE=aml_db
ATHENA_S3_OUTPUT=s3://aml-fyp-stream-bucket-<account_id>-eu-north-1-an/athena-results/
```

AWS credentials come from the standard locations (`~/.aws/credentials`, env vars, or IAM role). Run `aws configure` once if you haven't.

## Endpoints

| Method | Path | Returns |
|---|---|---|
| `GET` | `/api/health` | Service heartbeat |
| `GET` | `/api/kpis` | Aggregate KPIs (total alerts, critical count, suspicious volume, etc.) |
| `GET` | `/api/transactions/flagged?limit=N` | Most recent suspicious transactions |
| `GET` | `/api/alerts/live?limit=N` | Newest alerts from the real-time pipeline |
| `GET` | `/api/entities/top-risk?limit=N` | Customers ranked by alert frequency, with theme-coloured tier metadata |
| `GET` | `/api/alerts/breakdown` | Alert counts grouped by AML pattern |
| `GET` | `/api/geo/high-risk?limit=N` | Top countries by suspicious transaction volume, with flag emojis |

Interactive auto-generated docs are at **`http://localhost:8000/docs`** (Swagger UI) — useful for testing each endpoint without writing curl commands.

## How a request is served

1. The endpoint is called (e.g. `GET /api/kpis`)
2. FastAPI invokes the handler function
3. A SQL string is composed using the cleaned Athena views (`alerts_clean`, `transactions_clean`, etc.)
4. PyAthena executes the query against `aml_db`, results spill to S3 staging
5. Pandas reads the result CSV, converts NaN→None for JSON safety
6. FastAPI serializes the dict and returns it

Athena results are not cached at the backend layer; the React frontend caches via its 30-second polling interval.

## File layout

```
backend/
├── main.py              All endpoints + Athena helpers (single file by design)
├── .env                 Configuration (gitignored)
├── .env.example         Template
├── .gitignore
├── requirements.txt
└── venv/                Local virtualenv (gitignored)
```

The whole service is intentionally one file (~150 lines). If it grew, the right next step would be splitting into `routers/`, `services/`, and `models/` packages. For an FYP, single-file is a feature: it's easier to read.

## Adding a new endpoint

1. Define a function in `main.py` decorated with `@app.get("/api/your-endpoint")`
2. Build the SQL inside the function, query `query(sql)`, transform if needed, return a dict or list
3. Save — uvicorn `--reload` picks up the change automatically
4. Visit `http://localhost:8000/docs` to test

If the endpoint feeds a UI component, also add the `fetch()` to `aml-system/frontend/src/hooks/useLiveData.js` and pass it to the component as a prop.

## Troubleshooting

| Problem | Likely cause | Fix |
|---|---|---|
| `s3_staging_dir not found` | `.env` not read | Confirm `.env` is in the same directory as `main.py`, restart |
| `AccessDenied` from Athena | AWS creds missing / wrong region | Run `aws configure list`, verify `eu-north-1` |
| Endpoint returns 500 | Athena query error (table missing, syntax) | Read the uvicorn traceback; test the SQL directly in Athena console |
| `Failed to fetch` in browser | Backend not running, or CORS misconfigured | Confirm uvicorn is up; CORS allows `localhost:5173` and `:3000` |
| Slow first request | Athena cold start | Normal — first query takes 2–4s, subsequent ones are <1s |
