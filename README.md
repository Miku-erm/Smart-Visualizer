# 📊 Weekly Data Visualization Project

**Course**: Data Science & Full Stack Development  
**Module**: Weekly Challenge (React + Python/R Hybrid)

## 🚀 Project Overview

This architecture combines the best of all worlds:
1.  **React (Frontend)**: A modern, high-performance UI.
2.  **Python (Orchestrator)**: Manages requests, connects to Gemini, and controls the R process.
3.  **R (Analysis Engine)**: Performs the heavy-duty statistical visualization using `ggplot2`.

### ✨ Key Features

-   **Frontend**: React + Vite (running on port 5173).
-   **Backend**: Python Flask (running on port 5000), which automatically launches the R Plumber API (port 8000).
-   **AI Integration**: Python handles the Google Gemini API calls for insights.
-   **Data Viz**: R generates 10 beautiful charts (Base64 encoded) per dataset.
-   **Subprocess Management**: Python manages the lifecycle of the R server.

## 🛠 Installation & Setup

### 1. Prerequisites
-   **Node.js** (for React)
-   **Python 3.10+**
-   **R** (with packages: `plumber`, `ggplot2`, `dplyr`, `readr`, `readxl`, etc.)

### 2. Python Setup
```bash
pip install flask flask-cors requests google-generativeai antigravity
```

### 3. Frontend Setup
Open a terminal in the `frontend` folder:
```bash
cd frontend
npm install
```

## 🏃‍♂️ How to Run

1.  **Start the Backend**:
    Open a terminal in the root folder (`weekly`) and run:
    ```bash
    py app.py
    ```
    *This will start Python on port 5000 AND automatically launch the R server on port 8000.*

2.  **Start the Frontend**:
    Open a **new** terminal in the `frontend` folder and run:
    ```bash
    npm run dev
    ```

3.  **Open Browser**:
    Go to `http://localhost:5173`.

4.  **Analyze**:
    Upload a CSV/Excel file. Python will route it to R, get charts, adding AI insights, and show them to you.

## 🥚 Easter Eggs
-   **Antigravity**: Python backend imports `antigravity`.
-   **R Fortunes**: R backend uses `fortunes`.

---
*"Python orchestrates, R calculates, React fascinates."*
