import os
import google.generativeai as genai
from dotenv import load_dotenv

# Load API key from .env file
load_dotenv()
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# Configure library if key is available
if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)

def generate_portfolio_summary(username: str, portfolio_items: list, total_value: float, recent_news: list = None) -> str:
    """
    Generates a professional, markdown-formatted executive summary
    based on the user's current portfolio holdings using Google Gemini.
    """
    if not GEMINI_API_KEY:
        return "⚠️ **Gemini API Anahtarı Bulunamadı.** Lütfen `.env` dosyasını kontrol edin."

    # Prevent calls if portfolio is empty
    if not portfolio_items or total_value <= 0:
        return "Portföyünüzde henüz hisse bulunmuyor. Yatırıma başlayarak yapay zeka analizinden faydalanabilirsiniz."

    # Prepare holding strings
    holdings_text = "\n".join([f"- **{item['ticker']}**: {item['shares']} adet (Ort. Maliyet: ${item['avg_price']:.2f}, Kar/Zarar: ${item['unrealized_pl']:.2f})" for item in portfolio_items])
    
    # Prepare news context if available
    news_text = "Piyasadan güncel haberler dikkate alınmadı."
    if recent_news:
        news_text = "\n".join([f"📰 {n.get('publisher', 'Haber')}: {n.get('headline', '')}" for n in recent_news[:3]])

    prompt = f"""
    Sen profesyonel bir Wall Street portföy yöneticisi ve finansal yapay zeka asistanısın. 
    Aşağıda '{username}' adlı kullanıcının sahip olduğu hisse senedi portföyünün anlık durumu ve güncel piyasa haberleri verilmiştir.

    **Kullanıcı Portföyü (Toplam Değer: ${total_value:,.2f}):**
    {holdings_text}

    **İlgili Hisselerle Alakalı Son Haberler:**
    {news_text}

    **GÖREVİN:** 
    Gelişmiş finans terminolojisi ve profesyonel bir üslup kullanarak, Türkçe dilinde bir 'Yönetici Özeti (Executive Summary)' hazırla.
    Portföydeki riskleri, fırsatları, çeşitlendirmeyi ve (varsa) haberlerin potansiyel etkilerini kısaca değerlendir. Aşırı kesin yatırım tavsiyesi vermekten kaçın, objektif bir analiz yap.

    **FORMAT (Kesinlikle Markdown kullan):**
    - Başlık kullanma (örneğin # Yönetici Özeti yazma, ben zaten ekliyorum).
    - Vurgulanması gereken yerleri **kalın** veya *italik* yap.
    - Kısa, vurucu ve okunması kolay 2-3 paragraf olsun.
    - Gerekirse madde işaretleri kullan.
    """

    try:
        model = genai.GenerativeModel("gemini-2.5-flash")
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        print(f"[AI SERVICE ERROR] {e}")
        return f"Yapay zeka analizi sırasında bir hata oluştu: {str(e)}"
