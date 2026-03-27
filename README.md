# Borsa Dashboard: AI-Powered Financial Terminal

**Borsa Dashboard** is a professional financial terminal designed for modern stock market investors, combining **Artificial Intelligence (AI)** and **Deep Learning** models in a single platform.

---

## Key Features

### AI-Powered Analytics (Phase 10)
*   **AI Executive Brief:** Analyzes your portfolio holdings and real-time market news using **Google Gemini 2.5-Flash** to provide a professional management summary in seconds.
*   **Price Forecasting (LSTM):** A deep learning model built with **TensorFlow/Keras** that predicts future price direction (Uptrend/Downtrend) with a high confidence interval based on historical data.
*   **Sentiment Analysis (FinBERT):** Scans thousands of market news headlines within seconds and measures current market psychology (Bullish/Bearish) using the **HuggingFace FinBERT** model.

### Real-Time Technology
*   **Live Data Streaming (WebSocket):** Gold, BIST, and Currency data are automatically updated every 3 seconds via **FastAPI WebSocket** without requiring page refreshes.
*   **Technical Indicators:** Calculates and visualizes RSI (14) and MACD data on the chart in real-time.

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Frontend** | Flutter (Dart), fl_chart, web_socket_channel |
| **Backend** | Python, FastAPI, SQLite |
| **Artificial Intelligence** | Google Gemini SDK, TensorFlow, FinBERT |
| **Data Source** | yfinance (Yahoo Finance API) |

---

## Installation and Execution

Follow these steps to run the project on your local machine:

### 1. Backend (Python) Setup
```bash
# Install dependencies
pip install -r requirements.txt

# Start the server
python api_server.py
```

### 2. Frontend (Flutter) Setup
```bash
# Fetch packages
flutter pub get

# Run on Chrome
flutter run -d chrome
```

---

## Security

The project uses a .env-based structure to protect sensitive data. You can securely store your Gemini API key and database settings in your local .env file.

---

## Developer
**Canberk Sezgin** - *Borsa Dashboard Project Lead*

---
*This project was developed for educational and portfolio prototype purposes. It does not contain financial advice.*
