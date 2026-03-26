"""
==============================================================================
  Backtest Engine — Historical Performance Evaluation
==============================================================================
  • Downloads extended historical data for a given ticker
  • Walks forward through time, training the LSTM on past data and
    predicting the next bar's direction
  • Tracks simulated trades to produce real performance metrics:
      Win Rate, Total Return, Max Drawdown, Sharpe Ratio
  • Run:  python backtest_engine.py
==============================================================================
"""

import numpy as np
import pandas as pd
from datetime import datetime

# ── Import project modules ──
from trading_dashboard import fetch_stock_data, add_technical_indicators
from sentiment_analysis import (
    load_finbert_pipeline,
    get_real_headlines,
    classify_headlines,
    aggregate_daily_sentiment,
    merge_sentiment_into_ohlcv,
)
from lstm_forecast import generate_forecast


# ─────────────────────────────────────────────
#  CONFIGURATION
# ─────────────────────────────────────────────
TICKER = "AAPL"
INITIAL_CAPITAL = 10_000.0        # Starting portfolio value ($)
FETCH_PERIOD = "2y"               # Historical data window
FETCH_INTERVAL = "1d"             # Daily bars for backtesting
WARMUP_BARS = 80                  # Bars reserved for indicator warm-up + LSTM training
POSITION_SIZE_PCT = 0.95          # Use 95% of capital per trade


def run_backtest(
    ticker: str = TICKER,
    initial_capital: float = INITIAL_CAPITAL,
    period: str = FETCH_PERIOD,
    interval: str = FETCH_INTERVAL,
    warmup: int = WARMUP_BARS,
):
    """
    Execute a walk-forward backtest.

    Strategy:
        1. At each bar after the warm-up window, train/fine-tune
           the LSTM on all available past data.
        2. Predict the NEXT bar's direction (Up or Down).
        3. If prediction is "Upward Trend" → BUY (go long).
           If prediction is "Downward Trend" → SELL / stay flat.
        4. Track equity, wins, losses, and drawdowns.

    Returns
    -------
    dict : Performance metrics summary.
    """

    print("=" * 70)
    print(f"  BACKTEST ENGINE — {ticker}")
    print(f"  Capital: ${initial_capital:,.2f}  |  Period: {period}  |  Interval: {interval}")
    print("=" * 70)

    # ── Step 1: Fetch historical data ──
    print("\n[BT] Step 1/4: Fetching historical data ...")
    raw_data = fetch_stock_data(ticker, period=period, interval=interval)

    # ── Step 2: Add technical indicators ──
    print("[BT] Step 2/4: Computing technical indicators ...")
    enriched = add_technical_indicators(raw_data)

    # ── Step 3: Add sentiment (use current headlines as a proxy) ──
    print("[BT] Step 3/4: Running sentiment analysis ...")
    classifier = load_finbert_pipeline()
    headlines = get_real_headlines(ticker)
    scored = classify_headlines(classifier, headlines)
    daily_sentiment = aggregate_daily_sentiment(scored)
    final_df = merge_sentiment_into_ohlcv(enriched, daily_sentiment)

    total_bars = len(final_df)
    if total_bars < warmup + 10:
        print(f"[BT] ⚠️ Not enough data for backtesting. Got {total_bars} bars, need at least {warmup + 10}.")
        return None

    # ── Step 4: Walk-forward simulation ──
    print(f"\n[BT] Step 4/4: Walking forward from bar {warmup} to bar {total_bars - 1} ...")
    print(f"[BT]           ({total_bars - warmup - 1} prediction steps)\n")

    cash = initial_capital
    shares = 0.0
    equity_curve = []
    trades = []
    predictions = []
    actuals = []

    peak_equity = initial_capital
    max_drawdown = 0.0

    for i in range(warmup, total_bars - 1):
        # Current context: all data up to bar i
        context_df = final_df.iloc[:i + 1].copy()
        current_close = float(context_df.iloc[-1]["Close"])
        next_close = float(final_df.iloc[i + 1]["Close"])

        # Get LSTM prediction
        forecast = generate_forecast(context_df, force_mock=False, ticker=ticker)
        pred_label = forecast.get("forecast_label", "Unknown")
        pred_score = forecast.get("prediction_score", 0.5)

        # Determine actual direction
        actual_up = next_close > current_close
        predicted_up = "upward" in pred_label.lower() or "up" in pred_label.lower()

        predictions.append(predicted_up)
        actuals.append(actual_up)

        # ── Trading Logic ──
        if predicted_up and shares == 0:
            # BUY
            invest_amount = cash * POSITION_SIZE_PCT
            shares = invest_amount / current_close
            cash -= invest_amount
            trades.append({
                "bar": i,
                "action": "BUY",
                "price": current_close,
                "shares": shares,
                "confidence": pred_score,
            })
        elif not predicted_up and shares > 0:
            # SELL
            revenue = shares * current_close
            cash += revenue
            trades.append({
                "bar": i,
                "action": "SELL",
                "price": current_close,
                "shares": shares,
                "confidence": pred_score,
            })
            shares = 0.0

        # Calculate current portfolio equity
        equity = cash + (shares * current_close)
        equity_curve.append(equity)

        # Track drawdown
        if equity > peak_equity:
            peak_equity = equity
        drawdown = (peak_equity - equity) / peak_equity
        if drawdown > max_drawdown:
            max_drawdown = drawdown

        # Progress indicator
        step = i - warmup + 1
        total_steps = total_bars - warmup - 1
        if step % 20 == 0 or step == total_steps:
            pct = (step / total_steps) * 100
            print(f"  [BT] Progress: {step}/{total_steps} ({pct:.0f}%) — Equity: ${equity:,.2f}")

    # ── Liquidate remaining position ──
    if shares > 0:
        final_price = float(final_df.iloc[-1]["Close"])
        cash += shares * final_price
        shares = 0.0

    final_equity = cash

    # ── Calculate Metrics ──
    correct = sum(1 for p, a in zip(predictions, actuals) if p == a)
    total_predictions = len(predictions)
    win_rate = (correct / total_predictions * 100) if total_predictions > 0 else 0.0

    total_return = ((final_equity - initial_capital) / initial_capital) * 100
    profit_loss = final_equity - initial_capital

    # Sharpe Ratio (annualized, assuming daily returns)
    if len(equity_curve) > 1:
        returns = pd.Series(equity_curve).pct_change().dropna()
        sharpe = (returns.mean() / returns.std()) * np.sqrt(252) if returns.std() > 0 else 0.0
    else:
        sharpe = 0.0

    buy_trades = [t for t in trades if t["action"] == "BUY"]
    sell_trades = [t for t in trades if t["action"] == "SELL"]

    # ── Print Report ──
    print("\n" + "=" * 70)
    print("  BACKTEST RESULTS")
    print("=" * 70)
    print(f"  Ticker:              {ticker}")
    print(f"  Period:              {period} ({interval} bars)")
    print(f"  Total Bars:          {total_bars}")
    print(f"  Prediction Steps:    {total_predictions}")
    print(f"  ─────────────────────────────────────")
    print(f"  Starting Capital:    ${initial_capital:,.2f}")
    print(f"  Final Equity:        ${final_equity:,.2f}")
    print(f"  Profit / Loss:       ${profit_loss:+,.2f}")
    print(f"  Total Return:        {total_return:+.2f}%")
    print(f"  ─────────────────────────────────────")
    print(f"  Win Rate (Accuracy): {win_rate:.1f}%  ({correct}/{total_predictions})")
    print(f"  Max Drawdown:        {max_drawdown * 100:.2f}%")
    print(f"  Sharpe Ratio:        {sharpe:.2f}")
    print(f"  Total BUY trades:    {len(buy_trades)}")
    print(f"  Total SELL trades:   {len(sell_trades)}")
    print("=" * 70)

    result = {
        "ticker": ticker,
        "period": period,
        "interval": interval,
        "total_bars": total_bars,
        "prediction_steps": total_predictions,
        "initial_capital": initial_capital,
        "final_equity": round(final_equity, 2),
        "profit_loss": round(profit_loss, 2),
        "total_return_pct": round(total_return, 2),
        "win_rate_pct": round(win_rate, 1),
        "max_drawdown_pct": round(max_drawdown * 100, 2),
        "sharpe_ratio": round(sharpe, 2),
        "total_buy_trades": len(buy_trades),
        "total_sell_trades": len(sell_trades),
        "equity_curve": equity_curve,
        "trades": trades,
    }

    return result


# ─────────────────────────────────────────────
#  STANDALONE EXECUTION
# ─────────────────────────────────────────────
if __name__ == "__main__":
    result = run_backtest()

    if result:
        print(f"\n✅ Backtest complete for {result['ticker']}.")
        print(f"   AI Model Win Rate: {result['win_rate_pct']}%")
        print(f"   Total Return: {result['total_return_pct']:+.2f}%")
        print(f"   Sharpe Ratio: {result['sharpe_ratio']:.2f}")
    else:
        print("\n❌ Backtest could not be completed.")
