# Borsa Dashboard: AI-Powered Financial Terminal

**Borsa Dashboard**, modern borsa yatırımcıları için tasarlanmış, **Hissedeki Yapay Zeka (AI)** ve **Derin Öğrenme (Deep Learning)** modellerini tek bir çatıda birleştiren profesyonel bir finans terminalidir.

---

## One Cikan Ozellikler

### Yapay Zeka Destekli Analizler (Phase 10)
*   **AI Executive Brief (Akilli Bulten):** Portfoyunuzdeki hisseleri ve canli piyasa haberlerini **Google Gemini 2.5-Flash** kullanarak saniyeler icinde analiz eder ve size profesyonel bir yonetim ozeti sunar.
*   **Fiyat Tahminleme (LSTM):** Gecmis verileri kullanarak, hissenin gelecekteki yonunu (Yukselis/Dusus) %90+ guven araliginda tahmin eden **TensorFlow/Keras** tabanli bir derin ogrenme modelidir.
*   **Duygu Analizi (FinBERT):** Binlerce piyasa haberini saniyeler icinde tarar ve **HuggingFace FinBERT** modeli ile piyasanin o anki psikolojisini (Boga/Ayi) olcer.

### Gercek Zamanli Teknoloji
*   **Canli Veri Akisi (WebSocket):** Altin, BIST ve Doviz verileri, sayfa yenilemeye gerek kalmadan **FastAPI WebSocket** uzerinden her 3 saniyede bir otomatik guncellenir.
*   **Teknik Gostergeler:** RSI (14) ve MACD verilerini grafik uzerinde anlik olarak hesaplar ve gorsellestirir.

---

## Teknoloji Yigini (Tech Stack)

| Katman | Teknoloji |
|---|---|
| **Frontend** | Flutter (Dart), fl_chart, web_socket_channel |
| **Backend** | Python, FastAPI, SQLite |
| **Yapay Zeka** | Google Gemini SDK, TensorFlow, FinBERT |
| **Veri Kaynagi** | yfinance (Yahoo Finance API) |

---

## Kurulum ve Calistirma

Projeyi yerel makinenizde calistirmak icin su adimlari izleyin:

### 1. Backend (Python) Kurulumu
```bash
# Bagimliliklari yukleyin
pip install -r requirements.txt

# Sunucuyu baslatin
python api_server.py
```

### 2. Frontend (Flutter) Kurulumu
```bash
# Paketleri cekin
flutter pub get

# Chrome uzerinde baslatin
flutter run -d chrome
```

---

## Guvenlik

Proje, hassas verilerinizi korumak icin .env tabanli bir yapi kullanir. Gemini API anahtarinizi ve veritabanı ayarlarinizi yerel .env dosyanizda guvenle saklayabilirsiniz.

---

## Gelistirici
**Canberk Sezgin** - *Borsa Dashboard Project Lead*

