# 🚀 Smart Visualizer

**Powered by Google AI Studio**

This project is a sophisticated data analysis tool that merges statistical power with Artificial Intelligence. By leveraging **Google AI Studio's Gemini models**, Smart Visualizer provides intelligence alongside raw data processing.

## 🌟 Project Overview

This architecture combines the best of all worlds:
1.  **React (Frontend)**: A modern, high-performance UI for seamless user interaction.
2.  **Python (Orchestrator)**: Manages requests and integrates with **Google AI Studio** (Gemini API) for generating automatic insights.
3.  **R (Analysis Engine)**: Performs heavy-duty statistical visualization using `ggplot2` and `plumber`.

## ✨ Key Features

-   **Deep AI Integration**: Utilizes **Google AI Studio** to interpret complex datasets and provide natural language summaries.
-   **Advanced Visualization**: Generates 10 distinct types of high-quality plots (Bar, Scatter, Heatmap, etc.) using R's robust libraries.
-   **Smart Architecture**: Python Flask manages the lifecycle of the R backend, ensuring a unified experience.
-   **Modern UI**: Built with Vite + React, featuring a dynamic chart selector and dark mode aesthetics.

## 🛠 Installation & Setup

### 1. Prerequisites
-   **Node.js** (for React)
-   **Python 3.10+**
-   **R** (installed locally)
-   **Google AI Studio API Key**

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
    Open a terminal in the root folder and run:
    ```bash
    python app.py
    ```
    *This starts the Python orchestrator (Port 5000) and automatically launches the R Analysis Engine (Port 8000).*

2.  **Start the Frontend**:
    Open a **new** terminal in the `frontend` folder and run:
    ```bash
    npm run dev
    ```

3.  **Explore**:
    Go to `http://localhost:5173`, upload your dataset, and watch Smart Visualizer work its magic.

## 🤖 AI Capabilities
This project uses **Google AI Studio** to:
-   Analyze data patterns.
-   Generate summaries suitable for reports.
-   Provide context-aware insights on the generated charts.

---
*"Python orchestrates, R calculates, React fascinates."*
