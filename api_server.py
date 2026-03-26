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
from user_db import (
    create_user, verify_code, authenticate,
    get_user_from_token, update_avatar,
    generate_verification_code,
    log_prediction, get_prediction_stats,
    cache_news, get_cached_news,
    add_trade, get_portfolio, get_trade_history,
)
from ab_tracker import log_ab_prediction, resolve_pending_predictions, get_model_performance


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
        forecast_result = generate_forecast(final_df, force_mock=False, ticker=ticker)

        # ── Step 5b: A/B Prediction Logging ──
        current_price = float(final_df.iloc[-1]["Close"])
        resolve_pending_predictions(ticker, current_price)
        log_ab_prediction(ticker, forecast_result, current_price)

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

        # ── Step 7b: Cache News ──
        cache_news(ticker, recent_news_list)

        # ── Step 8: Get Model Stats ──
        model_perf = get_prediction_stats(ticker)

        return {
            "status": "success",
            "ticker": ticker,
            "total_bars": len(final_df),
            "returned_rows": len(records),
            "columns": list(final_df.columns),
            "forecast": forecast_result,
            "recent_news": recent_news_list,
            "model_stats": model_perf,
            "data": records,
        }

    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Pipeline error: {str(e)}")


# ─────────────────────────────────────────────
#  AUTH ENDPOINTS
# ─────────────────────────────────────────────

@app.post("/api/auth/register")
async def register(body: dict = None):
    """Register a new user account."""
    from fastapi import Request
    if body is None:
        raise HTTPException(status_code=400, detail="Request body required")
    
    username = body.get("username", "").strip()
    email = body.get("email", "").strip()
    password = body.get("password", "")
    
    if not username or not email or not password:
        raise HTTPException(status_code=400, detail="Username, email, and password are required.")
    if len(password) < 6:
        raise HTTPException(status_code=400, detail="Password must be at least 6 characters.")
    if "@" not in email:
        raise HTTPException(status_code=400, detail="Invalid email address.")
    
    result = create_user(username, email, password)
    if "error" in result:
        raise HTTPException(status_code=409, detail=result["error"])
    
    # Include code in response for local development (no real email server)
    from user_db import _get_conn
    conn = _get_conn()
    row = conn.cursor().execute("SELECT code FROM verification_codes WHERE email = ?", (email.lower(),)).fetchone()
    conn.close()
    code = row['code'] if row else ''
    
    return {"status": "success", "message": "Verification code sent.", "data": result, "debug_code": code}


@app.post("/api/auth/verify")
async def verify_email(body: dict = None):
    """Verify email with 6-digit code."""
    if body is None:
        raise HTTPException(status_code=400, detail="Request body required")
    
    email = body.get("email", "").strip()
    code = body.get("code", "").strip()
    
    if not email or not code:
        raise HTTPException(status_code=400, detail="Email and code are required.")
    
    if verify_code(email, code):
        return {"status": "success", "message": "Email verified successfully."}
    else:
        raise HTTPException(status_code=400, detail="Invalid or expired verification code.")


@app.post("/api/auth/resend")
async def resend_code(body: dict = None):
    """Resend verification code."""
    if body is None:
        raise HTTPException(status_code=400, detail="Request body required")
    
    email = body.get("email", "").strip()
    if not email:
        raise HTTPException(status_code=400, detail="Email is required.")
    
    code = generate_verification_code(email)
    return {"status": "success", "message": "Verification code resent.", "debug_code": code}


@app.post("/api/auth/login")
async def login(body: dict = None):
    """Login with email and password. Returns JWT token."""
    if body is None:
        raise HTTPException(status_code=400, detail="Request body required")
    
    email = body.get("email", "").strip()
    password = body.get("password", "")
    
    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password are required.")
    
    result = authenticate(email, password)
    if "error" in result:
        raise HTTPException(status_code=401, detail=result["error"])
    
    return {"status": "success", "data": result}


@app.get("/api/auth/profile")
async def get_profile(token: str = ""):
    """Get user profile from JWT token."""
    if not token:
        raise HTTPException(status_code=401, detail="Token is required.")
    
    user = get_user_from_token(token)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid or expired token.")
    
    return {"status": "success", "data": user}


@app.put("/api/auth/avatar")
async def set_avatar(body: dict = None):
    """Update user avatar."""
    if body is None:
        raise HTTPException(status_code=400, detail="Request body required")
    
    token = body.get("token", "")
    avatar_id = body.get("avatar_id", "")
    
    user = get_user_from_token(token)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token.")
    
    if update_avatar(user["id"], avatar_id):
        return {"status": "success", "message": "Avatar updated."}
    else:
        raise HTTPException(status_code=400, detail="Invalid avatar ID.")

@app.get("/api/market_summary")
async def get_market_summary():
    """
    Fetch the latest price and daily percentage change for key market indicators.
    Returns a compact JSON list for a frontend Marquee/Ticker.
    """
    import asyncio
    import yfinance as yf

    targets = [
        {"symbol": "USD/TRY", "ticker": "TRY=X"},
        {"symbol": "EUR/TRY", "ticker": "EURTRY=X"},
        {"symbol": "GOLD (Ons)", "ticker": "GC=F"},
        {"symbol": "BIST 100", "ticker": "XU100.IS"}
    ]
    
    def fetch_single(t):
        try:
            print(f"[API] Fetching market summary for {t['symbol']} ({t['ticker']})...")
            stock = yf.Ticker(t["ticker"])
            # Try fast_info first
            try:
                info = stock.fast_info
                current_price = info.last_price
                previous_close = info.previous_close
            except:
                current_price = None
                previous_close = None
            
            if not current_price or not previous_close:
                hist = stock.history(period="2d")
                if len(hist) >= 2:
                    current_price = hist['Close'].iloc[-1]
                    previous_close = hist['Close'].iloc[-2]
                else:
                    return None
            
            change_pct = ((current_price - previous_close) / previous_close) * 100
            
            return {
                "symbol": t["symbol"],
                "price": round(float(current_price), 2),
                "change_pct": round(float(change_pct), 2)
            }
        except Exception as e:
            print(f"[API] ⚠️ Error fetching {t['symbol']}: {e}")
            return None

    try:
        # Run in parallel threads to avoid blocking the event loop
        tasks = [asyncio.to_thread(fetch_single, t) for t in targets]
        results_raw = await asyncio.gather(*tasks)
        
        results = [r for r in results_raw if r is not None]
        print(f"[API] Market summary complete. Returns {len(results)} items.")
        return {"status": "success", "data": results}
        
    except Exception as e:
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Market summary error: {str(e)}")


# ─────────────────────────────────────────────
#  MULTI-TIMEFRAME ANALYSIS
# ─────────────────────────────────────────────
@app.get("/api/multi-timeframe/{ticker}")
async def multi_timeframe(ticker: str):
    """Analyze a ticker across 1h, 4h, and 1d timeframes."""
    import asyncio
    ticker = ticker.upper()

    timeframes = [
        {"label": "1H", "period": "30d", "interval": "1h"},
        {"label": "4H", "period": "60d", "interval": "1d"},  # 4h not supported by yfinance, use 1d as proxy
        {"label": "1D", "period": "1y", "interval": "1d"},
    ]

    def analyze_tf(tf):
        try:
            data = fetch_stock_data(ticker, period=tf["period"], interval=tf["interval"])
            enriched = add_technical_indicators(data)
            last = enriched.iloc[-1]
            rsi = float(last.get("RSI_14", 50))
            macd = float(last.get("MACD", 0))
            close = float(last.get("Close", 0))

            # Determine signal
            bullish_signals = 0
            if rsi < 50: bullish_signals += 1
            if macd > 0: bullish_signals += 1
            signal = "bullish" if bullish_signals >= 2 else ("bearish" if bullish_signals == 0 else "neutral")

            return {
                "timeframe": tf["label"],
                "close": round(close, 2),
                "rsi": round(rsi, 1),
                "macd": round(macd, 4),
                "signal": signal,
            }
        except Exception as e:
            return {"timeframe": tf["label"], "error": str(e)}

    try:
        tasks = [asyncio.to_thread(analyze_tf, tf) for tf in timeframes]
        results = await asyncio.gather(*tasks)

        # Combined consensus
        signals = [r.get("signal") for r in results if "signal" in r]
        bullish_count = signals.count("bullish")
        bearish_count = signals.count("bearish")
        if bullish_count > bearish_count:
            consensus = "bullish"
        elif bearish_count > bullish_count:
            consensus = "bearish"
        else:
            consensus = "neutral"

        return {"status": "success", "ticker": ticker, "timeframes": results, "consensus": consensus}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


# ─────────────────────────────────────────────
#  PREDICTION STATS / A-B TESTING
# ─────────────────────────────────────────────
@app.get("/api/prediction-stats/{ticker}")
async def prediction_stats(ticker: str):
    """Get prediction accuracy stats for a ticker."""
    stats = get_prediction_stats(ticker.upper())
    return {"status": "success", "data": stats}


@app.get("/api/model-stats/{ticker}")
async def model_stats(ticker: str):
    """Get comprehensive A/B model performance metrics."""
    performance = get_model_performance(ticker.upper())
    return {"status": "success", "data": performance}


@app.get("/api/model-stats/{ticker}/history")
async def model_stats_history(ticker: str):
    """Get detailed prediction history for a ticker."""
    from user_db import get_prediction_history
    history = get_prediction_history(ticker.upper())
    return {"status": "success", "history": history}


# ─────────────────────────────────────────────
#  PORTFOLIO (PAPER TRADING)
# ─────────────────────────────────────────────
@app.post("/api/portfolio/trade")
async def execute_trade(body: dict = None):
    """Execute a paper trade (BUY/SELL)."""
    if body is None:
        raise HTTPException(status_code=400, detail="Request body required")

    token = body.get("token", "")
    user = get_user_from_token(token)
    if not user:
        raise HTTPException(status_code=401, detail="Invalid token.")

    ticker = body.get("ticker", "").upper()
    action = body.get("action", "").upper()
    price = body.get("price", 0)
    shares = body.get("shares", 0)

    if not ticker or action not in ("BUY", "SELL") or price <= 0 or shares <= 0:
        raise HTTPException(status_code=400, detail="Invalid trade parameters.")

    result = add_trade(user["id"], ticker, action, price, shares)
    if result.get("error"):
        raise HTTPException(status_code=400, detail=result["message"])
    return {"status": "success", "trade_id": result["trade_id"], "message": result["message"]}


@app.get("/api/portfolio/{user_id}")
async def portfolio(user_id: int):
    """Get current portfolio holdings with live prices."""
    holdings = get_portfolio(user_id)

    # Fetch live prices for each holding
    for h in holdings:
        try:
            import yfinance as yf
            t = yf.Ticker(h["ticker"])
            info = t.fast_info
            live_price = float(info.get("lastPrice", 0) or info.get("previousClose", 0))
            h["live_price"] = round(live_price, 2)
            h["current_value"] = round(live_price * h["net_shares"], 2)
            avg_cost = h["net_cost"] / h["net_shares"] if h["net_shares"] > 0 else 0
            h["avg_cost"] = round(avg_cost, 2)
            h["pnl"] = round(h["current_value"] - h["net_cost"], 2)
            h["pnl_pct"] = round((h["pnl"] / h["net_cost"] * 100), 1) if h["net_cost"] > 0 else 0.0
        except Exception:
            h["live_price"] = 0
            h["current_value"] = 0
            h["pnl"] = 0
            h["pnl_pct"] = 0

    return {"status": "success", "holdings": holdings}


@app.get("/api/portfolio/{user_id}/history")
async def portfolio_history(user_id: int):
    """Get trade history."""
    history = get_trade_history(user_id)
    return {"status": "success", "history": history}


# ─────────────────────────────────────────────
#  WEBSOCKET LIVE DATA
# ─────────────────────────────────────────────
from starlette.websockets import WebSocket, WebSocketDisconnect
import asyncio
import json as json_lib

@app.websocket("/ws/{ticker}")
async def websocket_endpoint(websocket: WebSocket, ticker: str):
    """
    WebSocket endpoint that pushes live analysis updates every 60 seconds.
    On connect, immediately sends the latest data.
    """
    await websocket.accept()
    ticker = ticker.upper()
    print(f"[WS] Client connected for {ticker}")

    try:
        while True:
            try:
                # Run the full pipeline
                raw_data = fetch_stock_data(ticker)
                enriched = add_technical_indicators(raw_data)
                headlines = get_real_headlines(ticker)
                scored = classify_headlines(finbert_classifier, headlines)
                daily_sentiment = aggregate_daily_sentiment(scored)
                final_df = merge_sentiment_into_ohlcv(enriched, daily_sentiment)
                forecast_result = generate_forecast(final_df, force_mock=False, ticker=ticker)
                records = dataframe_to_json_records(final_df, n_rows=10)

                # Resolve pending A/B predictions
                current_price = float(final_df.iloc[-1]["Close"])
                resolve_pending_predictions(ticker, current_price)
                log_ab_prediction(ticker, forecast_result, current_price)

                # Cache news
                recent_news_list = [
                    {"title": h.get("headline", ""), "publisher": h.get("publisher", ""), "link": h.get("link", "")}
                    for h in headlines[:5]
                ]
                cache_news(ticker, recent_news_list)

                payload = {
                    "ticker": ticker,
                    "forecast": forecast_result,
                    "recent_news": recent_news_list,
                    "data": records,
                    "model_stats": get_prediction_stats(ticker),
                }

                await websocket.send_text(json_lib.dumps(payload, default=str))
                print(f"[WS] Pushed update for {ticker}")

            except Exception as e:
                error_payload = {"error": str(e)}
                await websocket.send_text(json_lib.dumps(error_payload))

            # Wait 60 seconds before next push
            await asyncio.sleep(60)

    except WebSocketDisconnect:
        print(f"[WS] Client disconnected for {ticker}")


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
