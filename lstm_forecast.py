"""
==============================================================================
  LSTM Forecasting Module
==============================================================================
  • Prepares OHLCV + Sentiment data for sequence modeling
  • Builds a small LSTM to forecast the next time step's price movement
  • Provides a mock fast-path for immediate API response
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

def prepare_lstm_data(df: pd.DataFrame, seq_length: int = 60):
    """
    Normalizes features and creates sequences for LSTM training.
    
    Parameters
    ----------
    df : pd.DataFrame - Merged OHLCV + Sentiment DataFrame
    seq_length : int - Lookback window size (e.g. 60 hours)
    
    Returns
    -------
    X : np.ndarray - Sequences of shape (samples, seq_length, features)
    y : np.ndarray - Targets (1 if next close > current close, else 0)
    scaler : MinMaxScaler - Fitted scaler for inverse transforms if needed
    features : list - Names of the features used
    """
    print(f"\n[LSTM] Preparing data (Sequence Length = {seq_length}) ...")
    
    # Select features for the model
    # We use price, technical indicators, and our new sentiment scores
    features = ["Close", "RSI_14", "MACD", "Sentiment_Score"]
    
    # Ensure no NaNs in the selected features
    data = df[features].ffill().bfill()
    
    scaler = MinMaxScaler(feature_range=(0, 1))
    scaled_data = scaler.fit_transform(data)
    
    X, y = [], []
    # We want to predict if the NEXT bar closes higher than the CURRENT bar's close.
    # We'll treat this as a binary classification problem for simplicity (Up/Down).
    close_idx = features.index("Close")
    
    for i in range(seq_length, len(scaled_data) - 1):
        X.append(scaled_data[i-seq_length:i])
        
        # Target: Is tomorrow's close > today's close?
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
        Dense(1, activation='sigmoid') # Probability of UP movement
    ])
    
    model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
    return model


def generate_forecast(df: pd.DataFrame, force_mock: bool = True) -> dict:
    """
    Main entry point for the API.
    Takes the recent DataFrame, optionally trains/evaluates the LSTM, 
    and returns a prediction score for the *next* unobserved hour.
    
    Parameters
    ----------
    df : pd.DataFrame - The latest OHLCV + Sentiment data
    force_mock : bool - If True, bypasses slow training and uses a heuristic 
                        based on the latest indicators + sentiment.
                        
    Returns
    -------
    dict: containing 'prediction_score' (0.0 to 1.0 probability of Up movement)
          and 'forecast_label' ("Upward" / "Downward").
    """
    
    if not TF_AVAILABLE or force_mock or len(df) < 20:
        # ── Fast-Path / Mock Prediction ──
        # In production this would load a pre-trained .h5 model.
        # For immediate API feedback, we synthesize a realistic score 
        # using the most recent Momentum combined with Sentiment.
        print("[LSTM] ⚡ Using fast-path mock prediction heuristics ...")
        
        latest = df.iloc[-1]
        
        # 1. Base probability is 0.5
        prob = 0.5
        
        # 2. Add sentiment weight (-0.2 to +0.2)
        sent = latest.get("Sentiment_Score", 0)
        prob += (sent * 0.2)
        
        # 3. Add RSI weight (RSI > 70 is overbought/bearish, < 30 is oversold/bullish)
        rsi = latest.get("RSI_14", 50)
        if rsi > 70:
            prob -= 0.15 # Bearish divergence
        elif rsi < 30:
            prob += 0.15 # Bullish bounce
            
        # 4. MACD weight (MACD > 0 is bullish)
        macd = latest.get("MACD", 0)
        if macd > 0:
            prob += 0.1
        else:
            prob -= 0.1
            
        # Clamp between 0.05 and 0.95 realistically
        prob = max(0.05, min(0.95, prob))
        
        # Add tiny random jitter (+/- 0.02) to prevent exact 0.5 stagnation
        prob += (np.random.uniform(-0.02, 0.02))
        prob = max(0.01, min(0.99, prob))
        
        label = "Upward Trend" if prob >= 0.5 else "Downward Trend"
        print(f"[LSTM] ✅ Forecast complete. Probability of Up: {prob:.2f}")
        
        # 5. Calculate Target Price (for visualization)
        # Apply a modest percentage move (e.g. +/- 1.5% max based on probability)
        current_price = latest.get("Close", 0)
        move_pct = (prob - 0.5) * 0.03 # Max 1.5% move up or down
        target_price = current_price * (1 + move_pct)
        
        return {
            "prediction_score": round(prob, 4),
            "forecast_label": label,
            "target_price": round(target_price, 2)
        }
    
    # ── Actual Training Path (Slow) ──
    # If forced_mock is False, we actually prep and train.
    dynamic_seq = min(60, max(5, int(len(df) * 0.25)))
    X, y, scaler, features = prepare_lstm_data(df, seq_length=dynamic_seq)
    
    if len(X) < 10:
        return {"prediction_score": 0.5, "forecast_label": "Insufficient Data"}
        
    # Log class balance to debug bias
    up_count = np.sum(y == 1)
    down_count = np.sum(y == 0)
    up_pct = (up_count / len(y)) * 100
    print(f"[LSTM] Training Set Balance: {up_pct:.1f}% Up, {100-up_pct:.1f}% Down")

    model = build_lstm_model((X.shape[1], X.shape[2]))
    
    print(f"[LSTM] Training model for 12 epochs (Deep Learning) ...")
    model.fit(X, y, epochs=12, batch_size=16, verbose=0)
    
    # Predict the NEXT step
    # We take the very last dynamic_seq rows from our dataset to form a sequence
    last_sequence = df[features].tail(dynamic_seq).ffill().bfill()
    last_scaled = scaler.transform(last_sequence)
    
    # Reshape for LSTM (1, seq_length, features)
    X_pred = last_scaled.reshape(1, dynamic_seq, len(features))
    
    pred_prob = model.predict(X_pred, verbose=0)[0][0]
    
    label = "Upward Trend" if pred_prob >= 0.5 else "Downward Trend"
    print(f"[LSTM] ✅ Deep Forecast complete. Probability of Up: {pred_prob:.2f}")
    
    # 5. Calculate Target Price
    current_price = df.iloc[-1].get("Close", 0)
    move_pct = (pred_prob - 0.5) * 0.03
    target_price = current_price * (1 + move_pct)
    
    return {
        "prediction_score": round(float(pred_prob), 4),
        "forecast_label": label,
        "target_price": round(float(target_price), 2)
    }
