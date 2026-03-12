"""
==============================================================================
  LSTM Forecasting Module
==============================================================================
  • Prepares OHLCV + Sentiment data for sequence modeling
  • Builds a small LSTM to forecast the next time step's price movement
  • Caches trained models per ticker to avoid retraining from scratch
==============================================================================
"""

import numpy as np
import pandas as pd
from sklearn.preprocessing import MinMaxScaler
try:
    import tensorflow as tf
    from tensorflow.keras.models import Sequential
    from tensorflow.keras.layers import LSTM, Dense, Dropout
    TF_AVAILABLE = True
except ImportError:
    TF_AVAILABLE = False

# ─────────────────────────────────────────────
#  MODEL CACHE — Stores trained models per ticker
# ─────────────────────────────────────────────
_model_cache = {}  # { "AAPL": {"model": ..., "scaler": ..., "features": [...]} }


def prepare_lstm_data(df: pd.DataFrame, seq_length: int = 60):
    """
    Normalizes features and creates sequences for LSTM training.
    """
    print(f"\n[LSTM] Preparing data (Sequence Length = {seq_length}) ...")
    
    features = ["Close", "RSI_14", "MACD", "Sentiment_Score"]
    data = df[features].ffill().bfill()
    
    scaler = MinMaxScaler(feature_range=(0, 1))
    scaled_data = scaler.fit_transform(data)
    
    X, y = [], []
    close_idx = features.index("Close")
    
    for i in range(seq_length, len(scaled_data) - 1):
        X.append(scaled_data[i-seq_length:i])
        current_close = scaled_data[i, close_idx]
        next_close = scaled_data[i+1, close_idx]
        y.append(1 if next_close > current_close else 0)
        
    X, y = np.array(X), np.array(y)
    
    print(f"[LSTM] ✅ Generated {len(X)} sequences of shape {X.shape}.")
    return X, y, scaler, features


def build_lstm_model(input_shape):
    """
    Defines a simple LSTM architecture for sequence classification.
    """
    if not TF_AVAILABLE:
        print("[LSTM] ⚠️ TensorFlow not installed. Cannot build real LSTM architecture.")
        return None
        
    print("[LSTM] Building LSTM Architecture ...")
    model = Sequential([
        LSTM(50, return_sequences=True, input_shape=input_shape),
        Dropout(0.2),
        LSTM(50, return_sequences=False),
        Dropout(0.2),
        Dense(25, activation='relu'),
        Dense(1, activation='sigmoid')
    ])
    
    model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
    return model


def generate_forecast(df: pd.DataFrame, force_mock: bool = False, ticker: str = "UNKNOWN") -> dict:
    """
    Main entry point for the API.
    Takes the recent DataFrame, optionally trains/evaluates the LSTM, 
    and returns a prediction score for the *next* unobserved hour.
    
    Parameters
    ----------
    df : pd.DataFrame - The latest OHLCV + Sentiment data
    force_mock : bool - If True, bypasses slow training and uses a heuristic.
    ticker : str - Ticker symbol for model caching.
                        
    Returns
    -------
    dict: containing 'prediction_score', 'forecast_label', 'target_price'.
    """
    
    if not TF_AVAILABLE or force_mock or len(df) < 20:
        # ── Fast-Path / Heuristic Prediction ──
        print("[LSTM] ⚡ Using fast-path heuristic prediction ...")
        
        latest = df.iloc[-1]
        prob = 0.5
        
        sent = latest.get("Sentiment_Score", 0)
        prob += (sent * 0.2)
        
        rsi = latest.get("RSI_14", 50)
        if rsi > 70:
            prob -= 0.15
        elif rsi < 30:
            prob += 0.15
            
        macd = latest.get("MACD", 0)
        if macd > 0:
            prob += 0.1
        else:
            prob -= 0.1
            
        prob = max(0.05, min(0.95, prob))
        prob += (np.random.uniform(-0.02, 0.02))
        prob = max(0.01, min(0.99, prob))
        
        label = "Upward Trend" if prob >= 0.5 else "Downward Trend"
        print(f"[LSTM] ✅ Heuristic complete. Probability of Up: {prob:.2f}")
        
        current_price = latest.get("Close", 0)
        move_pct = (prob - 0.5) * 0.03
        target_price = current_price * (1 + move_pct)
        
        return {
            "prediction_score": round(prob, 4),
            "forecast_label": label,
            "target_price": round(target_price, 2)
        }
    
    # ── Actual Training Path ──
    global _model_cache
    
    dynamic_seq = min(60, max(5, int(len(df) * 0.25)))
    X, y, scaler, features = prepare_lstm_data(df, seq_length=dynamic_seq)
    
    if len(X) < 10:
        return {"prediction_score": 0.5, "forecast_label": "Insufficient Data", "target_price": 0.0}
        
    # Log class balance
    up_count = np.sum(y == 1)
    up_pct = (up_count / len(y)) * 100
    print(f"[LSTM] Training Set Balance: {up_pct:.1f}% Up, {100-up_pct:.1f}% Down")

    # Check if we have a cached model for this ticker
    cache_key = ticker.upper()
    if cache_key in _model_cache:
        print(f"[LSTM] ♻️ Reusing cached model for {cache_key} — fine-tuning with 3 epochs ...")
        model = _model_cache[cache_key]["model"]
        model.fit(X, y, epochs=3, batch_size=16, verbose=0)
    else:
        print(f"[LSTM] 🆕 No cached model for {cache_key} — training from scratch (12 epochs) ...")
        model = build_lstm_model((X.shape[1], X.shape[2]))
        model.fit(X, y, epochs=12, batch_size=16, verbose=0)
    
    # Cache the model
    _model_cache[cache_key] = {
        "model": model,
        "scaler": scaler,
        "features": features,
    }
    
    # Predict the NEXT step
    last_sequence = df[features].tail(dynamic_seq).ffill().bfill()
    last_scaled = scaler.transform(last_sequence)
    X_pred = last_scaled.reshape(1, dynamic_seq, len(features))
    
    pred_prob = model.predict(X_pred, verbose=0)[0][0]
    
    label = "Upward Trend" if pred_prob >= 0.5 else "Downward Trend"
    print(f"[LSTM] ✅ Deep Forecast complete. Probability of Up: {pred_prob:.2f}")
    
    current_price = df.iloc[-1].get("Close", 0)
    move_pct = (pred_prob - 0.5) * 0.03
    target_price = current_price * (1 + move_pct)
    
    return {
        "prediction_score": round(float(pred_prob), 4),
        "forecast_label": label,
        "target_price": round(float(target_price), 2)
    }
