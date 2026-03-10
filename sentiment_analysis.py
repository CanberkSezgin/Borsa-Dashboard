"""
==============================================================================
  Sentiment Analysis Module — FinBERT-powered Financial NLP
==============================================================================
  • Classifies financial headlines as Positive / Negative / Neutral
  • Aggregates daily sentiment scores for merging into OHLCV DataFrames
  • Designed for plug-and-play integration with trading_dashboard.py
==============================================================================
"""

import pandas as pd
import numpy as np
from datetime import datetime, timedelta
import yfinance as yf
try:
    from transformers import pipeline, AutoTokenizer, AutoModelForSequenceClassification
    TRANSFORMERS_AVAILABLE = True
except ImportError:
    TRANSFORMERS_AVAILABLE = False


# ─────────────────────────────────────────────
#  1. MODEL SETUP
# ─────────────────────────────────────────────
def load_finbert_pipeline():
    """
    Load the ProsusAI/FinBERT model and tokenizer, then wrap them
    in a Hugging Face sentiment-analysis pipeline.

    Returns
    -------
    transformers.Pipeline – ready-to-use classifier
    """
    if not TRANSFORMERS_AVAILABLE:
        print("[NLP] ⚠️ Transformers library not installed. Running in mock/lightweight mode.")
        return None

    print("[NLP] Loading ProsusAI/FinBERT model (first run will download ~440 MB) …")

    model_name = "ProsusAI/finbert"
    tokenizer = AutoTokenizer.from_pretrained(model_name)
    model = AutoModelForSequenceClassification.from_pretrained(model_name)

    classifier = pipeline(
        task="sentiment-analysis",
        model=model,
        tokenizer=tokenizer,
        top_k=None,           # Return ALL label scores (Positive, Negative, Neutral)
        truncation=True,
        max_length=512,
    )

    print("[NLP] ✅ FinBERT pipeline loaded successfully.")
    return classifier


# ─────────────────────────────────────────────
#  2. REAL HEADLINE DATA
# ─────────────────────────────────────────────
def get_real_headlines(ticker: str) -> list[dict]:
    """
    Fetch the latest financial news headlines for a given ticker using yfinance.

    Each item is a dict with:
        • date     : datetime.date
        • headline : str

    Parameters
    ----------
    ticker : str

    Returns
    -------
    list[dict]
    """
    print(f"[NLP] Fetching real news for '{ticker}' via yfinance …")
    stock = yf.Ticker(ticker)
    today = datetime.now().date()
    
    try:
        news_items = stock.news
    except Exception as e:
        print(f"[NLP] ⚠️ Error fetching news for '{ticker}': {e}")
        news_items = []
        
    print(f"DEBUG: Found {len(news_items)} headlines for {ticker}")
        
    headlines = []
    for item in news_items:
        if not isinstance(item, dict):
            continue
        content = item.get("content") or item
        if not isinstance(content, dict):
            continue
            
        title = content.get("title")
        pub_date_val = content.get("pubDate") or content.get("providerPublishTime")
        
        if title and pub_date_val:
            try:
                if isinstance(pub_date_val, str):
                    pub_date = pd.to_datetime(pub_date_val).date()
                else:
                    pub_date = datetime.fromtimestamp(pub_date_val).date()
            except Exception:
                continue

            # If the news is from the last 7 days, attribute its sentiment to 'today'
            # so that it correctly joins onto the latest OHLCV bar.
            if (today - pub_date).days <= 7:
                pub_date = today
                
            provider = content.get("provider") or {}
            click_url = content.get("clickThroughUrl") or {}
                
            headlines.append({
                "date": pub_date,
                "headline": title,
                "publisher": provider.get("displayName", "") if isinstance(provider, dict) else "",
                "link": click_url.get("url", "") if isinstance(click_url, dict) else ""
            })

    # Fallback to company summary if no recent headlines
    if not headlines:
        print(f"[NLP] ⚠️ No recent news found for '{ticker}'. Attempting fallback to company info...")
        try:
            info = stock.info
            summary = info.get("longBusinessSummary") or info.get("longName")
            if summary:
                headlines.append({
                    "date": today,
                    "headline": summary,
                    "publisher": "Yahoo Finance (Fallback)",
                    "link": f"https://finance.yahoo.com/quote/{ticker}"
                })
                print(f"[NLP] ✅ Fallback used: 1 abstract snippet extracted.")
        except Exception as e:
            print(f"[NLP] ⚠️ Fallback info failed for '{ticker}': {e}")
            
    print(f"[NLP] ✅ Fetched {len(headlines)} total text segments for '{ticker}'.")
    return headlines


# ─────────────────────────────────────────────
#  3. HEADLINE CLASSIFICATION
# ─────────────────────────────────────────────
def classify_headlines(classifier, headlines: list[dict]) -> pd.DataFrame:
    """
    Pass each headline through the FinBERT pipeline and extract
    per-label probability scores.

    Parameters
    ----------
    classifier : transformers.Pipeline – loaded FinBERT pipeline
    headlines  : list[dict]            – output of get_dummy_headlines()

    Returns
    -------
    pd.DataFrame with columns:
        Date, Headline, Positive, Negative, Neutral, Dominant_Sentiment
    """
    print("[NLP] Classifying headlines with FinBERT …")

    if not headlines:
        print("[NLP] ⚠️ No headlines to classify. Returning empty DataFrame.")
        return pd.DataFrame(columns=["Date", "Headline", "Positive", "Negative", "Neutral", "Dominant_Sentiment"])

    records = []
    if classifier is None:
        print("[NLP] ⚠️ Classifier is None. Returning MOCK sentiment data.")
        for item in headlines:
            records.append({
                "Date": pd.Timestamp(item["date"]),
                "Headline": item["headline"],
                "Positive": 0.33,
                "Negative": 0.33,
                "Neutral": 0.34,
                "Dominant_Sentiment": "neutral",
            })
    else:
        for item in headlines:
            result = classifier(item["headline"])
            scores = {entry["label"]: round(entry["score"], 4) for entry in result[0]}
            dominant = max(scores, key=scores.get)
            records.append({
                "Date": pd.Timestamp(item["date"]),
                "Headline": item["headline"],
                "Positive": scores.get("positive", 0.0),
                "Negative": scores.get("negative", 0.0),
                "Neutral": scores.get("neutral", 0.0),
                "Dominant_Sentiment": dominant,
            })

    df = pd.DataFrame(records)
    print(f"[NLP] ✅ Classified {len(df)} headlines.\n")

    # Pretty-print individual results
    for _, row in df.iterrows():
        emoji = {"positive": "🟢", "negative": "🔴", "neutral": "⚪"}.get(row["Dominant_Sentiment"], "")
        print(f"  {emoji}  [{row['Dominant_Sentiment'].upper():>8}]  "
              f"P={row['Positive']:.2f}  N={row['Negative']:.2f}  Nu={row['Neutral']:.2f}")
        print(f"      └─ \"{row['Headline'][:80]}…\"" if len(row["Headline"]) > 80
              else f"      └─ \"{row['Headline']}\"")

    return df


# ─────────────────────────────────────────────
#  4. DAILY AGGREGATION
# ─────────────────────────────────────────────
def aggregate_daily_sentiment(sentiment_df: pd.DataFrame) -> pd.DataFrame:
    """
    Aggregate headline-level sentiment scores to a daily level.

    For each date we compute:
        • Mean positive / negative / neutral scores
        • Number of headlines that day
        • A composite Sentiment_Score = (Positive − Negative) scaled to [-1, 1]

    Parameters
    ----------
    sentiment_df : pd.DataFrame – output of classify_headlines()

    Returns
    -------
    pd.DataFrame indexed by Date with aggregated columns:
        Sent_Positive, Sent_Negative, Sent_Neutral,
        Headline_Count, Sentiment_Score
    """
    print("\n[NLP] Aggregating sentiment scores by day …")

    daily = (
        sentiment_df
        .groupby("Date")
        .agg(
            Sent_Positive=("Positive", "mean"),
            Sent_Negative=("Negative", "mean"),
            Sent_Neutral=("Neutral", "mean"),
            Headline_Count=("Headline", "count"),
        )
    )

    # Composite score: ranges from -1 (all negative) to +1 (all positive)
    daily["Sentiment_Score"] = (daily["Sent_Positive"] - daily["Sent_Negative"]).round(4)

    # Ensure the index is a DatetimeIndex for merging
    daily.index = pd.to_datetime(daily.index)

    print(f"[NLP] ✅ Aggregated into {len(daily)} daily records.\n")
    print(daily.to_string())

    return daily


# ─────────────────────────────────────────────
#  5. MERGE INTO OHLCV DATAFRAME
# ─────────────────────────────────────────────
def merge_sentiment_into_ohlcv(ohlcv_df: pd.DataFrame,
                                daily_sentiment: pd.DataFrame) -> pd.DataFrame:
    """
    Merge daily sentiment scores into an hourly (or any freq) OHLCV DataFrame.

    Strategy:
        • Normalise both indices to date-only for a left-join.
        • Fill NaN days with neutral (0.0).
    """
    print("\n[NLP] Merging sentiment into OHLCV DataFrame …")

    merged = ohlcv_df.copy()
    
    # 1. Create a temporary 'MergeDate' column in the OHLCV data
    # (yfinance index is usually 'Datetime' with timezone)
    merged['MergeDate'] = pd.to_datetime(merged.index).date
    
    # 2. Ensure daily_sentiment index is also date-only
    daily_sentiment_copy = daily_sentiment.copy()
    daily_sentiment_copy['MergeDate'] = pd.to_datetime(daily_sentiment_copy.index).date
    
    # 3. Perform the join
    merged = merged.merge(
        daily_sentiment_copy, 
        on='MergeDate', 
        how='left'
    )
    
    # 4. Fill gaps with Neutral values (so we don't have NaNs in the LSTM)
    merged["Sent_Positive"] = merged["Sent_Positive"].fillna(0.0)
    merged["Sent_Negative"] = merged["Sent_Negative"].fillna(0.0)
    merged["Sent_Neutral"] = merged["Sent_Neutral"].fillna(1.0)
    merged["Headline_Count"] = merged["Headline_Count"].fillna(0).astype(int)
    merged["Sentiment_Score"] = merged["Sentiment_Score"].fillna(0.0)
    
    # Restore the original index
    merged.index = ohlcv_df.index
    merged.drop(columns=['MergeDate'], inplace=True)

    sent_cols = ["Sent_Positive", "Sent_Negative", "Sent_Neutral",
                 "Headline_Count", "Sentiment_Score"]
    print(f"[NLP] ✅ Time-aware Merge complete. New columns: {sent_cols}")
    print(f"[NLP]    Matches found: {merged['Headline_Count'].sum()} total headlines across timeline.")
    
    return merged


# ─────────────────────────────────────────────
#  STANDALONE TEST
# ─────────────────────────────────────────────
if __name__ == "__main__":
    """
    When run directly, demonstrates the full NLP pipeline end-to-end
    and shows how to merge into an OHLCV DataFrame from trading_dashboard.
    """
    from trading_dashboard import fetch_stock_data, add_technical_indicators

    TICKER = "AAPL"

    # ── Step 1: Reuse the existing data pipeline ──
    raw = fetch_stock_data(TICKER)
    enriched = add_technical_indicators(raw)

    # ── Step 2: Run the sentiment pipeline ──
    classifier = load_finbert_pipeline()
    headlines = get_real_headlines(TICKER)
    scored = classify_headlines(classifier, headlines)
    daily_sent = aggregate_daily_sentiment(scored)

    # ── Step 3: Merge sentiment into the OHLCV+indicators DataFrame ──
    final_df = merge_sentiment_into_ohlcv(enriched, daily_sent)

    # ── Preview the result ──
    preview_cols = ["Close", "RSI_14", "MACD", "Sent_Positive",
                    "Sent_Negative", "Sentiment_Score"]
    print("\n" + "=" * 70)
    print("  FINAL MERGED DATAFRAME  (last 10 rows)")
    print("=" * 70)
    print(final_df[preview_cols].tail(10).to_string())
    print(f"\n[INFO] ✅ Pipeline complete — {final_df.shape[1]} total columns, "
          f"{final_df.shape[0]} rows.")
