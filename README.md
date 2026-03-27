# 🚀 Borsa Dashboard: AI-Powered Financial Terminal

**Borsa Dashboard**, modern borsa yatırımcıları için tasarlanmış, **Hissedeki Yapay Zeka (AI)** ve **Derin Öğrenme (Deep Learning)** modellerini tek bir çatıda birleştiren profesyonel bir finans terminalidir.

---

## ✨ Öne Çıkan Özellikler

### 🧠 Yapay Zeka Destekli Analizler (Phase 10)
*   **AI Executive Brief (Akıllı Bülten):** Portföyünüzdeki hisseleri ve canlı piyasa haberlerini **Google Gemini 2.5-Flash** kullanarak saniyeler içinde analiz eder ve size profesyonel bir yönetim özeti sunar.
*   **Fiyat Tahminleme (LSTM):** Geçmiş verileri kullanarak, hissenin gelecekteki yönünü (Yükseliş/Düşüş) %90+ güven aralığında tahmin eden **TensorFlow/Keras** tabanlı bir derin öğrenme modelidir.
*   **Duygu Analizi (FinBERT):** Binlerce piyasa haberini saniyeler içinde tarar ve **HuggingFace FinBERT** modeli ile piyasanın o anki psikolojisini (Boğa/Ayı) ölçer.

### ⚡ Gerçek Zamanlı Teknoloji
*   **Canlı Veri Akışı (WebSocket):** Altın, BIST ve Döviz verileri, sayfa yenilemeye gerek kalmadan **FastAPI WebSocket** üzerinden her 3 saniyede bir otomatik güncellenir.
*   **Teknik Göstergeler:** RSI (14) ve MACD verilerini grafik üzerinde anlık olarak hesaplar ve görselleştirir.

---

## 🛠️ Teknoloji Yığını (Tech Stack)

| Katman | Teknoloji |
|---|---|
| **Frontend** | Flutter (Dart), fl_chart, web_socket_channel |
| **Backend** | Python, FastAPI, SQLite |
| **Yapay Zeka** | Google Gemini SDK, TensorFlow, FinBERT |
| **Veri Kaynağı** | yfinance (Yahoo Finance API) |

---

## 🚀 Kurulum ve Çalıştırma

Projeyi yerel makinenizde çalıştırmak için şu adımları izleyin:

### 1. Backend (Python) Kurulumu
```bash
# Bağımlılıkları yükleyin
pip install -r requirements.txt

# Sunucuyu başlatın
python api_server.py
```

### 2. Frontend (Flutter) Kurulumu
```bash
# Paketleri çekin
flutter pub get

# Chrome üzerinde başlatin
flutter run -d chrome
```

---

## 🔒 Güvenlik

Proje, hassas verilerinizi korumak için `.env` tabanlı bir yapı kullanır. Gemini API anahtarınızı ve veritabanı ayarlarınızı yerel `.env` dosyanızda güvenle saklayabilirsiniz.

---

## 👨‍💻 Geliştirici
**Canberk Sezgin** - *Borsa Dashboard Project Lead*

---
*Bu proje eğitim ve portföy prototipi amacıyla geliştirilmiştir. Kesinlikle yatırım tavsiyesi içermez.*
