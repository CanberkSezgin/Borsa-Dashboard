"""
==============================================================================
  Algorithmic Trading — Data Preprocessing & Visualization Pipeline
==============================================================================
  • Fetches hourly OHLCV data via yfinance
  • Engineers technical indicators with pandas-ta (RSI, MACD, EMA)
  • Renders an interactive Plotly dashboard with three synced subplots
==============================================================================
"""

import yfinance as yf
import pandas as pd
import pandas_ta as ta
import plotly.graph_objects as go
from plotly.subplots import make_subplots
import numpy as np


# ─────────────────────────────────────────────
#  1. DATA FETCHING
# ─────────────────────────────────────────────
def fetch_stock_data(ticker: str, period: str = "60d", interval: str = "1h") -> pd.DataFrame:
    """
    Download hourly OHLCV data from Yahoo Finance.

    Parameters
    ----------
    ticker   : str   – Yahoo Finance ticker symbol (e.g. 'AAPL', 'THYAO.IS')
    period   : str   – Look-back window ('60d' = last 60 days)
    interval : str   – Bar size ('1h' = 1 hour)

    Returns
    -------
    pd.DataFrame with columns: Open, High, Low, Close, Volume
    """
    print(f"[INFO] Fetching {interval} data for '{ticker}' over the last {period} …")
    data = yf.download(ticker, period=period, interval=interval, progress=False)

    # Flatten multi-level column index that yfinance sometimes returns
    if isinstance(data.columns, pd.MultiIndex):
        data.columns = data.columns.get_level_values(0)

    # Basic validation
    if data.empty:
        raise ValueError(f"No data returned for ticker '{ticker}'. Check the symbol and try again.")

    print(f"[INFO] Fetched {len(data)} bars  |  Range: {data.index[0]}  →  {data.index[-1]}")
    return data


# ─────────────────────────────────────────────
#  2. FEATURE ENGINEERING (Technical Indicators)
# ─────────────────────────────────────────────
def add_technical_indicators(df: pd.DataFrame) -> pd.DataFrame:
    """
    Compute RSI(14), MACD(12,26,9) and EMA(20) and append them
    as new columns. NaN rows generated during warm-up are dropped.

    Returns
    -------
    pd.DataFrame – original data + indicator columns, NaN-free.
    """
    print("[INFO] Computing technical indicators …")

    # ── RSI (14) ──
    df["RSI_14"] = ta.rsi(df["Close"], length=14)

    # ── MACD (12 / 26 / 9) ──
    macd = ta.macd(df["Close"], fast=12, slow=26, signal=9)
    df = pd.concat([df, macd], axis=1)

    # Rename MACD columns for clarity
    macd_cols = {
        "MACD_12_26_9": "MACD",
        "MACDh_12_26_9": "MACD_Hist",
        "MACDs_12_26_9": "MACD_Signal",
    }
    df.rename(columns=macd_cols, inplace=True)

    # ── EMA (20) ──
    df["EMA_20"] = ta.ema(df["Close"], length=20)

    # ── Drop warm-up NaN rows ──
    rows_before = len(df)
    df.dropna(inplace=True)
    rows_after = len(df)
    print(f"[INFO] Dropped {rows_before - rows_after} warm-up NaN rows  →  {rows_after} bars remaining")

    return df


# ─────────────────────────────────────────────
#  3. VISUALIZATION — Interactive Plotly Dashboard
# ─────────────────────────────────────────────
def _half_moon_shapes():
    """
    Return a list of Plotly layout shapes that draw a subtle,
    decorative half-moon arc in the background.
    """
    # Large translucent circle positioned so only its right-half is visible.
    return [
        # Outer soft glow
        dict(
            type="circle",
            xref="paper", yref="paper",
            x0=-0.55, y0=-0.15,
            x1=0.45, y1=1.15,
            fillcolor="rgba(180, 200, 230, 0.12)",
            line=dict(color="rgba(160, 185, 220, 0.18)", width=1.5),
            layer="below",
        ),
        # Inner brighter crescent
        dict(
            type="circle",
            xref="paper", yref="paper",
            x0=-0.50, y0=-0.10,
            x1=0.40, y1=1.10,
            fillcolor="rgba(200, 218, 245, 0.10)",
            line=dict(color="rgba(180, 200, 235, 0.15)", width=1),
            layer="below",
        ),
        # Small accent circle (top-right area)
        dict(
            type="circle",
            xref="paper", yref="paper",
            x0=0.82, y0=0.80,
            x1=1.08, y1=1.12,
            fillcolor="rgba(190, 210, 240, 0.09)",
            line=dict(color="rgba(175, 195, 225, 0.12)", width=1),
            layer="below",
        ),
    ]


def build_dashboard(df: pd.DataFrame, ticker: str) -> go.Figure:
    """
    Create an interactive 3-subplot dashboard:
        • Top    – Candlestick + EMA(20)
        • Middle – RSI(14) with oversold/overbought bands
        • Bottom – MACD line, Signal line, Histogram bars

    Parameters
    ----------
    df     : pd.DataFrame – processed data with indicator columns
    ticker : str          – symbol name, used in the title

    Returns
    -------
    go.Figure – fully configured Plotly figure
    """
    print("[INFO] Building interactive dashboard …")

    fig = make_subplots(
        rows=3, cols=1,
        shared_xaxes=True,
        vertical_spacing=0.04,
        row_heights=[0.50, 0.20, 0.30],
        subplot_titles=(
            f"📈  {ticker} — Price & EMA(20)",
            "📊  RSI (14)",
            "📉  MACD (12, 26, 9)",
        ),
    )

    # ────────── TOP: Candlestick + EMA ──────────
    fig.add_trace(
        go.Candlestick(
            x=df.index,
            open=df["Open"],
            high=df["High"],
            low=df["Low"],
            close=df["Close"],
            name="Price",
            increasing_line_color="#26a69a",
            decreasing_line_color="#ef5350",
            increasing_fillcolor="#26a69a",
            decreasing_fillcolor="#ef5350",
        ),
        row=1, col=1,
    )

    fig.add_trace(
        go.Scatter(
            x=df.index,
            y=df["EMA_20"],
            mode="lines",
            name="EMA (20)",
            line=dict(color="#ff9800", width=2, dash="dot"),
        ),
        row=1, col=1,
    )

    # ────────── MIDDLE: RSI ──────────
    fig.add_trace(
        go.Scatter(
            x=df.index,
            y=df["RSI_14"],
            mode="lines",
            name="RSI (14)",
            line=dict(color="#7c4dff", width=1.8),
        ),
        row=2, col=1,
    )

    # Overbought / Oversold reference lines
    fig.add_hline(y=70, line_dash="dash", line_color="#e53935", line_width=1,
                  annotation_text="Overbought (70)", annotation_position="top left",
                  annotation_font_color="#e53935", row=2, col=1)
    fig.add_hline(y=30, line_dash="dash", line_color="#43a047", line_width=1,
                  annotation_text="Oversold (30)", annotation_position="bottom left",
                  annotation_font_color="#43a047", row=2, col=1)

    # Shade the overbought / oversold regions
    fig.add_hrect(y0=70, y1=100, fillcolor="rgba(229,57,53,0.06)", line_width=0, row=2, col=1)
    fig.add_hrect(y0=0, y1=30, fillcolor="rgba(67,160,71,0.06)", line_width=0, row=2, col=1)

    # ────────── BOTTOM: MACD ──────────
    # Histogram bars (green if positive, red if negative)
    hist_colors = np.where(df["MACD_Hist"] >= 0, "rgba(38,166,154,0.65)", "rgba(239,83,80,0.65)")

    fig.add_trace(
        go.Bar(
            x=df.index,
            y=df["MACD_Hist"],
            name="MACD Histogram",
            marker_color=hist_colors,
            opacity=0.7,
        ),
        row=3, col=1,
    )

    fig.add_trace(
        go.Scatter(
            x=df.index,
            y=df["MACD"],
            mode="lines",
            name="MACD Line",
            line=dict(color="#1e88e5", width=1.8),
        ),
        row=3, col=1,
    )

    fig.add_trace(
        go.Scatter(
            x=df.index,
            y=df["MACD_Signal"],
            mode="lines",
            name="Signal Line",
            line=dict(color="#ff7043", width=1.8, dash="dot"),
        ),
        row=3, col=1,
    )

    # Zero line for MACD panel
    fig.add_hline(y=0, line_dash="solid", line_color="rgba(0,0,0,0.25)", line_width=0.8,
                  row=3, col=1)

    # ────────── LAYOUT — Light theme + half-moon ──────────
    fig.update_layout(
        title=dict(
            text=f"<b>{ticker}</b>  •  Algorithmic Trading Dashboard",
            font=dict(size=22, color="#37474f", family="Segoe UI, Arial, sans-serif"),
            x=0.5,
            xanchor="center",
        ),
        template="plotly_white",
        paper_bgcolor="#f5f7fb",
        plot_bgcolor="#ffffff",
        font=dict(family="Segoe UI, Arial, sans-serif", size=12, color="#455a64"),
        legend=dict(
            orientation="h",
            yanchor="bottom",
            y=1.02,
            xanchor="center",
            x=0.5,
            bgcolor="rgba(255,255,255,0.85)",
            bordercolor="rgba(0,0,0,0.08)",
            borderwidth=1,
            font=dict(size=11),
        ),
        height=950,
        margin=dict(l=60, r=40, t=100, b=40),
        shapes=_half_moon_shapes(),
        xaxis_rangeslider_visible=False,
        hovermode="x unified",
    )

    # Style each y-axis
    fig.update_yaxes(title_text="Price", row=1, col=1, gridcolor="rgba(0,0,0,0.04)")
    fig.update_yaxes(title_text="RSI", row=2, col=1, range=[0, 100], gridcolor="rgba(0,0,0,0.04)")
    fig.update_yaxes(title_text="MACD", row=3, col=1, gridcolor="rgba(0,0,0,0.04)")

    # Style x-axes
    fig.update_xaxes(gridcolor="rgba(0,0,0,0.04)")
    fig.update_xaxes(title_text="Date / Time", row=3, col=1)

    # Style subplot titles
    for annotation in fig["layout"]["annotations"]:
        annotation["font"] = dict(size=14, color="#546e7a", family="Segoe UI, Arial, sans-serif")

    return fig


# ─────────────────────────────────────────────
#  MAIN — Orchestrator
# ─────────────────────────────────────────────
def main(ticker: str = "AAPL"):
    """Run the full pipeline: fetch → engineer → visualize."""

    # Step 1 – Fetch raw data
    raw_data = fetch_stock_data(ticker)

    # Step 2 – Add technical indicators
    enriched_data = add_technical_indicators(raw_data)

    # Quick sanity check
    print("\n[INFO] DataFrame preview (last 5 rows):")
    print(enriched_data[["Close", "EMA_20", "RSI_14", "MACD", "MACD_Signal", "MACD_Hist"]].tail())

    # Step 3 – Build & display the dashboard
    fig = build_dashboard(enriched_data, ticker)
    fig.show()

    print(f"\n[INFO] ✅ Dashboard for '{ticker}' is ready — opened in your default browser.")


# ─────────────────────────────────────────────
if __name__ == "__main__":
    # ─────── CHANGE THE TICKER HERE ───────
    TICKER = "AAPL"  # Try: "THYAO.IS", "MSFT", "TSLA", "BTC-USD"
    main(TICKER)
