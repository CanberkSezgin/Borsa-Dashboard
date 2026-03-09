"""
==============================================================================
  FastAPI REST API — Algorithmic Trading Data & Sentiment Pipeline
==============================================================================
  • Serves enriched stock data + FinBERT sentiment scores over HTTP
  • Designed for consumption by mobile / web frontends
  • Run:  python api_server.py   (starts on http://localhost:8000)
==============================================================================
"""

import math
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

# ── Import our existing pipeline modules ──
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
#  GLOBAL: Heavy model loaded ONCE at startup
# ─────────────────────────────────────────────
finbert_classifier = None


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Load the FinBERT model into memory when the server starts,
    so it is ready before the first request arrives.
    """
    global finbert_classifier
    print("\n🚀 [STARTUP] Loading FinBERT model — please wait …")
    finbert_classifier = load_finbert_pipeline()
    print("🚀 [STARTUP] Model ready. Server is accepting requests.\n")
    yield
    # Cleanup on shutdown (nothing to do for now)
    print("\n🛑 [SHUTDOWN] Server is shutting down.")


# ─────────────────────────────────────────────
#  1. APP INITIALISATION
# ─────────────────────────────────────────────
app = FastAPI(
    title="Algorithmic Trading API",
    description=(
        "REST API that delivers enriched stock data with technical indicators "
        "(RSI, MACD, EMA) and FinBERT-powered sentiment scores."
    ),
    version="1.0.0",
    lifespan=lifespan,
)


# ─────────────────────────────────────────────
#  2. CORS MIDDLEWARE
# ─────────────────────────────────────────────
#  Allow ALL origins so that mobile emulators, local web apps,
#  and any future frontend can reach the API without CORS errors.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],           # Accept requests from any origin
    allow_credentials=True,
    allow_methods=["*"],           # GET, POST, OPTIONS, etc.
    allow_headers=["*"],
)


# ─────────────────────────────────────────────
#  HELPER — Sanitise DataFrame for JSON
# ─────────────────────────────────────────────
def dataframe_to_json_records(df, n_rows: int = 10) -> list[dict]:
    """
    Convert the last `n_rows` of a DataFrame into a list of
    JSON-safe dictionaries.

    • Datetime index → ISO-8601 string
    • NaN / Inf      → None (null in JSON)
    """
    subset = df.tail(n_rows).copy()

    # Convert datetime index to a regular column
    subset.reset_index(inplace=True)
    datetime_col = subset.columns[0]  # "Datetime" or "Date"
    subset.rename(columns={datetime_col: "datetime"}, inplace=True)
    subset["datetime"] = subset["datetime"].astype(str)

    # Replace NaN / Inf with None for valid JSON
    records = subset.to_dict(orient="records")
    for row in records:
        for key, value in row.items():
            if isinstance(value, float) and (math.isnan(value) or math.isinf(value)):
                row[key] = None

    return records


# ─────────────────────────────────────────────
#  3. ENDPOINTS
# ─────────────────────────────────────────────

@app.get("/")
async def root():
    """Health-check / welcome endpoint."""
    return {
        "service": "Algorithmic Trading API",
        "version": "1.0.0",
        "usage": "GET /api/analyze/{ticker}  (e.g. /api/analyze/AAPL)",
        "docs": "Visit /docs for interactive Swagger UI",
    }


@app.get("/api/analyze/{ticker}")
async def analyze_ticker(ticker: str, rows: int = 30, range: str = "1M"):
    """
    Run the full pipeline for the given ticker and return
    the last N rows of enriched data as JSON.

    Path Parameters
    ----------------
    ticker : str – Yahoo Finance symbol (e.g. AAPL, THYAO.IS, MSFT)

    Query Parameters
    ----------------
    rows   : int – Number of trailing rows to return (default 30, max 100)
    range  : str – Time range for the chart (1D, 1W, 1M, 1Y)
    """
    global finbert_classifier

    # Clamp requested rows
    rows = max(1, min(rows, 100))
    ticker = ticker.upper()

    # Map range to yfinance period and interval
    # We fetch extra data (fetch_period) so MACD/RSI dropna() doesn't eat our required timeframe.
    range_map = {
        "1D": {"fetch_period": "5d", "interval": "5m", "bars": 78},
        "1W": {"fetch_period": "1mo", "interval": "1h", "bars": 35},
        "1M": {"fetch_period": "3mo", "interval": "1d", "bars": 22},
        "1Y": {"fetch_period": "2y", "interval": "1d", "bars": 252}
    }
    
    range_key = range.upper()
    if range_key not in range_map:
        range_key = "1M"
        
    yf_params = range_map[range_key]
    target_rows = yf_params["bars"]

    try:
        # ── Step 1: Fetch OHLCV data ──
        print(f"\n📡 [API] Request received for ticker: {ticker} (Range: {range_key})")
        raw_data = fetch_stock_data(ticker, period=yf_params["fetch_period"], interval=yf_params["interval"])

        # ── Step 2: Technical indicators ──
        enriched = add_technical_indicators(raw_data)

        # ── Step 3: Sentiment analysis ──
        headlines = get_real_headlines(ticker)
        scored = classify_headlines(finbert_classifier, headlines)
        daily_sentiment = aggregate_daily_sentiment(scored)

        # ── Step 4: Merge everything ──
        final_df = merge_sentiment_into_ohlcv(enriched, daily_sentiment)

        # ── Step 5: LSTM Forecasting ──
        # Predict the next hour's probability of moving UP based on the latest context
        forecast_result = generate_forecast(final_df, force_mock=True)

        # ── Step 6: Build JSON response ──
        records = dataframe_to_json_records(final_df, n_rows=target_rows)
        
        # ── Step 7: Recent News Extraction ──
        # Extract the highest 5 items from the headlines
        recent_news_list = [
            {
                "title": h.get("headline", ""),
                "publisher": h.get("publisher", ""),
                "link": h.get("link", "")
            }
            for h in headlines[:5]
        ]

        return {
            "status": "success",
            "ticker": ticker,
            "total_bars": len(final_df),
            "returned_rows": len(records),
            "columns": list(final_df.columns),
            "forecast": forecast_result,
            "recent_news": recent_news_list,
            "data": records,
        }

    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Pipeline error: {str(e)}")

@app.get("/api/market_summary")
async def get_market_summary():
    """
    Fetch the latest price and daily percentage change for key market indicators.
    Returns a compact JSON list for a frontend Marquee/Ticker.
    """
    targets = [
        {"symbol": "USD/TRY", "ticker": "TRY=X"},
        {"symbol": "EUR/TRY", "ticker": "EURTRY=X"},
        {"symbol": "GOLD (Ons)", "ticker": "GC=F"},
        {"symbol": "BIST 100", "ticker": "XU100.IS"}
    ]
    
    results = []
    
    try:
        for t in targets:
            # We use yfinance Ticker to fetch the daily change efficiently
            import yfinance as yf
            stock = yf.Ticker(t["ticker"])
            
            # Use 'fast_info' for quick access to the latest price and previous close
            try:
                info = stock.fast_info
                current_price = info.last_price
                previous_close = info.previous_close
                if current_price and previous_close:
                    change_pct = ((current_price - previous_close) / previous_close) * 100
                else: # Fallback to history if fast_info fails
                   hist = stock.history(period="2d")
                   if len(hist) >= 2:
                       current_price = hist['Close'].iloc[-1]
                       previous_close = hist['Close'].iloc[-2]
                       change_pct = ((current_price - previous_close) / previous_close) * 100
                   else:
                       continue
            except Exception as e:
                print(f"[API] Error fetching summary for {t['symbol']}: {e}")
                continue
                
            results.append({
                "symbol": t["symbol"],
                "price": round(current_price, 2) if current_price else 0.0,
                "change_pct": round(change_pct, 2) if change_pct is not None else 0.0
            })
            
        return {"status": "success", "data": results}
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Market summary error: {str(e)}")


# ─────────────────────────────────────────────
#  4. RUN SERVER
# ─────────────────────────────────────────────
if __name__ == "__main__":
    uvicorn.run(
        "api_server:app",
        host="0.0.0.0",
        port=8000,
        reload=False,        # set True during development
        log_level="info",
    )
