# frontend — SENTINEL Dashboard

The user-facing console for the AML pipeline. A React + TypeScript single-page application styled as a "command center" for compliance analysts.

## Tech

- React 19
- TypeScript
- Vite (dev server + build)
- No chart library — visualizations are hand-rendered SVG and HTML/CSS for full theme control
- IBM Plex Mono, Syne, Orbitron fonts (loaded from Google Fonts)

## Run it

```bash
cd aml-system/frontend
npm install
npm run dev
```

Opens at `http://localhost:5173`. Requires the backend to be running at `http://localhost:8000` — see [`../backend/README.md`](../../backend/README.md).

## Project structure

```
frontend/
├── src/
│   ├── App.tsx                   Root component, routing, layout
│   ├── main.tsx                  Vite entry point
│   ├── components/               Visual building blocks (one file each)
│   │   ├── Topbar.jsx
│   │   ├── Sidebar.jsx
│   │   ├── LiveTicker.jsx        Scrolling alert+tx ticker
│   │   ├── KpiCard.jsx           KPI tile with sparkline
│   │   ├── BarChart.jsx          Custom SVG bar chart for AML pattern breakdown
│   │   ├── RiskEntitiesPanel.jsx Top suspicious entities list
│   │   ├── TransactionsTable.jsx Sortable, filterable transaction table
│   │   ├── AlertsPanel.jsx       Slide-in alerts drawer
│   │   ├── BottomPanels.jsx      Geo + Rules side-by-side
│   │   ├── Modal.jsx             Detail modal (entity / transaction / KPI)
│   │   ├── Toast.jsx             Bottom-right notifications
│   │   ├── Sparkline.jsx
│   │   ├── Badge.jsx
│   │   └── GlobalStyles.jsx      Font loader + global CSS
│   ├── hooks/
│   │   ├── useLiveData.js        Polls backend every 30s, exposes all data
│   │   ├── useClock.js           UTC clock for the topbar
│   │   ├── useToasts.js          Toast notification state
│   │   └── useWindowWidth.js     Mobile/desktop detection
│   ├── constants/
│   │   ├── theme.js              Color palette + spacing tokens
│   │   └── data.js               Static seed data (legacy mock — kept for ticker labels, nav structure)
│   └── assets/                   Static images
├── public/                       Public static files
├── index.html                    HTML shell
├── vite.config.ts                Vite configuration
├── tsconfig.json                 TypeScript configuration
└── package.json                  Dependencies + scripts
```

## Theme

The cyan/black/pink Sentinel palette lives in `src/constants/theme.js`:

```javascript
export const C = {
  bg: "#080c14",
  surface: "#0d1117",
  surface2: "#131924",
  border: "rgba(255,255,255,.07)",
  text: "#e8eaf0",
  muted: "#5a6378",
  accent: "#00e5ff",     // primary cyan
  accent2: "#ff3b6b",    // alert pink/red
  accent3: "#f5c518",    // warning amber
  green: "#00d68f",
  ...
};
```

To rebrand, change colors here once — they propagate everywhere.

## Data flow

```
Backend (FastAPI)               useLiveData hook                Components
─────────────────               ────────────────                ──────────
GET /api/kpis                   Polls all 6 endpoints           KpiCard × 4
GET /api/transactions/flagged   in parallel every 30s           TransactionsTable
GET /api/alerts/live            via Promise.all                 AlertsPanel, LiveTicker
GET /api/entities/top-risk      Reshapes data to UI shapes      RiskEntitiesPanel
GET /api/alerts/breakdown       Triggers toasts on new          BarChart, RulesPanel
GET /api/geo/high-risk          critical alerts                 GeoPanel
```

All components are pure — they receive props from `App.tsx` and never call the backend themselves. To add new data:

1. Add a new endpoint in `backend/main.py`
2. Add a `fetch()` call in `useLiveData.js`
3. Pass the result through `App.tsx` to the consuming component

## Routing

The dashboard uses simple state-based navigation (no React Router) because there are no URL-driven concerns. `activeNav` in `App.tsx` controls which view renders:

- `Overview` — full dashboard (default)
- `Alerts` — list view of recent alerts
- `Transactions` — full transactions table
- `Entities` — risk entities list
- Anything else (`Network Graph`, `Case Manager`, ...) — "Future work" placeholder

Adding a new view is one conditional block in `App.tsx`.

## Build for production

```bash
npm run build
```

Outputs to `dist/`. Static files; deploy to S3+CloudFront, Vercel, Netlify, or any static host. The backend URL is hardcoded in `useLiveData.js` (`http://localhost:8000`) — change to your production backend URL before building.

## Known limitations

- **Mobile sidebar navigation** — the sidebar opens but tap events don't propagate to the routing layer; under investigation. Desktop is the primary target environment.
- **KPI sparklines** — display flat lines until a time-series endpoint is added to the backend.
- **No URL routing** — refreshing the page returns to Overview. A real production app would use React Router and URL params.
- **No auth** — for the FYP scope, the dashboard runs locally and trusts AWS IAM at the backend layer.

## Component patterns

If you want to add or modify a component, the convention is:

```jsx
import { C } from "../constants/theme";

export function NewComponent({ data = [], onSomething }) {
    if (data.length === 0) {
        return <div style={{ padding: 16, color: C.muted }}>Loading...</div>;
    }
    return (
        <div style={{ background: C.surface, border: `1px solid ${C.border}`, borderRadius: 6 }}>
            {/* ... */}
        </div>
    );
}
```

- Always use the theme tokens, never hex literals
- Always handle the empty/loading state
- Always destructure with a default for array props
- Style props inline (no CSS modules) — keeps theming centralized
