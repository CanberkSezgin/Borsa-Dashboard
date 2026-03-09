#  Autonomous AI Finance Terminal

A full-stack, real-time financial dashboard that leverages deep learning and natural language processing to analyze market trends. Built with a Flutter frontend and a Python/FastAPI backend.

##  Features

* **Live Auto-Pilot (Otonom Yenileme):** Automatically fetches and refreshes market data, news, and predictions every 3 minutes.
* **AI Price Forecasting (LSTM):** Utilizes a Long Short-Term Memory neural network (built with TensorFlow/Keras) to predict short-term price movements based on historical data.
* **Sentiment Analysis (FinBERT):** Scrapes real-time financial news and processes headlines through a specialized HuggingFace NLP model to gauge market sentiment (Bullish/Bearish).
* **Real-time Technical Indicators:** Calculates and visualizes RSI (14) and MACD instantly.
* **Premium UI/UX:** A minimalist, light-themed institutional-grade dashboard featuring state-of-the-art animations.

##  Tech Stack

* **Frontend:** Flutter (Dart)
* **Backend:** Python, FastAPI, Uvicorn
* **Machine Learning:** TensorFlow, Scikit-learn, HuggingFace Transformers (FinBERT)
* **Data Sources:** `yfinance` API
