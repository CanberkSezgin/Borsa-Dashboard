"""
==============================================================================
  A/B Testing Tracker — Model Performance Logger
==============================================================================
  • Logs every prediction from the LSTM vs Heuristic
  • Resolves predictions when the next bar arrives
  • Provides accuracy, precision, recall, F1 metrics
==============================================================================
"""

from user_db import log_prediction, resolve_prediction, get_prediction_stats, _get_conn


def log_ab_prediction(ticker: str, forecast_result: dict, current_price: float) -> int:
    """
    Log a prediction from the LSTM model.
    Returns the log ID for later resolution.
    """
    label = forecast_result.get("forecast_label", "Unknown")
    confidence = forecast_result.get("prediction_score", 0.5)
    direction = "up" if "upward" in label.lower() or "up" in label.lower() else "down"

    log_id = log_prediction(
        ticker=ticker,
        predicted_direction=direction,
        confidence=confidence,
        price_at_prediction=current_price,
    )
    print(f"[A/B] Logged prediction #{log_id} for {ticker}: {direction} ({confidence:.2%})")
    return log_id


def resolve_pending_predictions(ticker: str, current_price: float):
    """
    Resolve all pending (unresolved) predictions for a ticker
    by comparing their price_at_prediction with the current price.
    """
    conn = _get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id, price_at_prediction FROM prediction_logs WHERE ticker=? AND was_correct IS NULL",
        (ticker.upper(),)
    )
    pending = cursor.fetchall()
    conn.close()

    resolved_count = 0
    for row in pending:
        log_id = row['id']
        old_price = row['price_at_prediction']
        actual_direction = "up" if current_price > old_price else "down"
        resolve_prediction(log_id, actual_direction, current_price)
        resolved_count += 1

    if resolved_count > 0:
        print(f"[A/B] Resolved {resolved_count} pending predictions for {ticker}")


def get_model_performance(ticker: str) -> dict:
    """
    Get comprehensive model performance metrics.
    Returns accuracy, total predictions, wins, losses, and recent history.
    """
    stats = get_prediction_stats(ticker)

    # Get recent prediction history
    conn = _get_conn()
    cursor = conn.cursor()
    cursor.execute(
        "SELECT predicted_direction, actual_direction, was_correct, confidence, predicted_at FROM prediction_logs WHERE ticker=? AND was_correct IS NOT NULL ORDER BY predicted_at DESC LIMIT 20",
        (ticker.upper(),)
    )
    recent = [dict(r) for r in cursor.fetchall()]
    conn.close()

    stats["recent_predictions"] = recent
    return stats
