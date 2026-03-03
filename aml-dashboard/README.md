# SENTINEL – AML Monitoring Dashboard (Frontend)

A modern, real-time Anti-Money Laundering (AML) monitoring dashboard built with React.
SENTINEL simulates a bank-grade transaction monitoring interface with live alerts, risk scoring, KPIs, and entity tracking.

<img width="1587" height="994" alt="Image" src="https://github.com/user-attachments/assets/4c479e47-5486-4fe7-a02f-8eb2dfea51c7" />

<img width="1546" height="970" alt="Image" src="https://github.com/user-attachments/assets/f4b2fa97-6a61-457f-ac0c-dc4aa67249d7" />

<img width="690" height="993" alt="Image" src="https://github.com/user-attachments/assets/eaabc007-fbdd-48c5-98b7-166add1c21c9" />

<img width="838" height="972" alt="Image" src="https://github.com/user-attachments/assets/5694fc87-5461-4556-9146-2b6e43ca084a" />

## Overview

SENTINEL is a frontend simulation of a hybrid AML transaction monitoring system.
It provides:

- Real-time KPI metrics
- Live alert notifications
- Transaction risk scoring
- High-risk jurisdiction monitoring
- Rule-trigger analytics
- Entity-level risk tracking
- Toast notifications & live feed ticker
- CSV export functionality

This project is designed for:

- Final Year Projects
- AML / FinTech system prototypes
- Data engineering & ML integration demos
- Portfolio showcase

## Key Features
### Dashboard Overview

- Live KPI cards (Risk Score, Alerts, etc.)
- Animated sparklines
- Real-time simulation updates

### Alerts Panel

- Slide-in live alerts panel
- Risk-level badges (Critical, High, Medium, Cleared)
- Mobile responsive

### Transactions Table

- Risk filtering (All, Critical, High, Medium, Cleared)
- Search (Transaction ID, Entity, Rule)
- Column sorting
- CSV export
- Real-time updates
- Modal review system

### Risk Intelligence Panels

- High-Risk Jurisdictions
- Rule Trigger Distribution
- Top Risk Entities

 ### Fully Responsive

- Mobile sidebar
- Adaptive grid layout
- Sticky header & table headers

## Tech Stack

- React (Functional Components + Hooks)
- Vite
- Pure inline styling (No external UI library)
- Custom animation keyframes
- Canvas-based Sparkline charts

## Project Structure
``` bash
aml-dashboard/
│
├── node_modules/
├── public/
│   └── vite.svg
│
├── src/
│   ├── assets/
│   │   └── react.svg
│   │
│   ├── components/
│   │   ├── AlertsPanel.jsx
│   │   ├── Badge.jsx
│   │   ├── BarChart.jsx
│   │   ├── BottomPanel.jsx
│   │   ├── GlobalStyles.jsx
│   │   ├── KpiCard.jsx
│   │   ├── LiveTicker.jsx
│   │   ├── Modal.jsx
│   │   ├── RiskEntitiesPanel.jsx
│   │   ├── Sidebar.jsx
│   │   ├── Sparkline.jsx
│   │   ├── Toast.jsx
│   │   ├── Topbar.jsx
│   │   └── TransactionsTable.jsx
│   │
│   ├── constants/
│   │   ├── data.js
│   │   └── theme.js
│   │
│   ├── hooks/
│   │   ├── useClock.js
│   │   ├── useLiveSimulation.js
│   │   ├── useToast.js
│   │   └── useWindowWidth.js
│   │
│   ├── App.css
│   ├── App.tsx
│   ├── index.css
│   └── main.tsx
│
├── .gitignore
├── eslint.config.js
├── index.html
├── package-lock.json
├── package.json
├── README.md
├── tsconfig.app.json
├── tsconfig.json
├── tsconfig.node.json
└── vite.config.ts
```

## Installation
### Clone the repository
``` bash
git clone https://github.com/yourusername/sentinel-aml-frontend.git
cd sentinel-aml-frontend
```
### Install dependencies
``` bash
npm install
```
### Run development server
``` bash
npm run dev
```
App will run at:
``` bash
http://localhost:5173
```
## Export Functionality

Transactions can be exported as CSV:
``` bash
Transaction ID,Entity,Amount,Type,Rule,Risk,Time
```
File name:
``` bash
sentinel_transactions.csv
```
## Risk Levels
``` bash
| Level    | Meaning                     |
| -------- | --------------------------- |
| Critical | Immediate SAR required      |
| High     | High probability suspicious |
| Medium   | Needs review                |
| Cleared  | Reviewed and approved       |
```

## Design Philosophy

- Dark cyber-fintech aesthetic
- Neon accent highlights
- High contrast risk visualization
- Minimal external dependencies
- Bank-grade UI simulation feel

## Future Improvements

- Backend API integration (FastAPI / Node)
- ML risk scoring model integration
- WebSocket real-time streaming
- Database persistence
- Role-based access control
- Advanced analytics charts (Recharts / D3)

# Author

Moavia Mahmood
Software Engineering Student
Transitioning into Machine Learning & Data Engineering

# License

This project is for academic and demonstration purposes.