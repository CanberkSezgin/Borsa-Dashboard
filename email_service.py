"""
==============================================================================
  Email Service — Gmail SMTP for Verification & Price Alert Emails
==============================================================================
  • Sends beautiful HTML verification emails
  • Sends price alert notification emails
  • Configured for Gmail SMTP (App Password required)
  • Falls back gracefully if SMTP is not configured
==============================================================================
"""

import smtplib
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# ── SMTP Configuration ──
# Set these environment variables OR edit directly for local use
SMTP_EMAIL = os.environ.get("SMTP_EMAIL", "borsadashboard0@gmail.com")
SMTP_PASSWORD = os.environ.get("SMTP_PASSWORD", "")  # Gmail App Password
SMTP_HOST = "smtp.gmail.com"
SMTP_PORT = 587


def _send_email(to_email: str, subject: str, html_body: str, plain_text: str) -> bool:
    """Internal helper to send an email via SMTP."""
    if not SMTP_PASSWORD:
        print(f"[EMAIL] ⚠️ SMTP_PASSWORD not set. Email not sent to {to_email}.")
        print(f"[EMAIL] 💡 Set SMTP_PASSWORD environment variable or edit email_service.py directly.")
        return False

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = f"Borsa Dashboard <{SMTP_EMAIL}>"
    msg["To"] = to_email

    msg.attach(MIMEText(plain_text, "plain"))
    msg.attach(MIMEText(html_body, "html"))

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_EMAIL, SMTP_PASSWORD)
            server.send_message(msg)
        print(f"[EMAIL] ✅ Email sent to {to_email}")
        return True
    except Exception as e:
        print(f"[EMAIL] ❌ Failed to send email: {e}")
        return False


def send_verification_email(to_email: str, username: str, code: str) -> bool:
    """
    Send a verification email with a beautiful HTML template.
    Returns True if sent successfully, False otherwise.
    """
    subject = "CS Ailesine Hoş Geldiniz — E-posta Doğrulama"

    html_body = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body {{ font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 0; background: #0B1120; }}
            .container {{ max-width: 520px; margin: 40px auto; background: #131B2E; border-radius: 16px; overflow: hidden; box-shadow: 0 8px 32px rgba(0,0,0,0.3); border: 1px solid rgba(99,102,241,0.2); }}
            .header {{ background: linear-gradient(135deg, #6366F1, #8B5CF6); padding: 32px; text-align: center; }}
            .header h1 {{ color: white; margin: 0; font-size: 20px; letter-spacing: 2px; }}
            .header .icon {{ font-size: 40px; margin-bottom: 12px; }}
            .body {{ padding: 32px; }}
            .welcome {{ font-size: 20px; color: #F1F5F9; font-weight: 800; margin-bottom: 8px; }}
            .text {{ color: #94A3B8; font-size: 14px; line-height: 1.7; margin-bottom: 24px; }}
            .code-box {{ background: linear-gradient(135deg, rgba(99,102,241,0.15), rgba(139,92,246,0.15)); border: 2px solid #6366F1; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0; }}
            .code {{ font-size: 36px; font-weight: 900; color: #A5B4FC; letter-spacing: 8px; }}
            .code-label {{ font-size: 12px; color: #64748B; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px; }}
            .footer {{ padding: 20px 32px; background: #0F172A; text-align: center; font-size: 11px; color: #475569; }}
            .expire {{ color: #F87171; font-weight: 600; font-size: 12px; margin-top: 16px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="icon">📈</div>
                <h1>BORSA DASHBOARD</h1>
            </div>
            <div class="body">
                <p class="welcome">CS Ailesine Hoş Geldin, {username}!</p>
                <p class="text">
                    Borsa Dashboard hesabın başarıyla oluşturuldu. 
                    Hesabını aktifleştirmek için aşağıdaki doğrulama kodunu kullan:
                </p>
                <div class="code-box">
                    <div class="code-label">Aktivasyon Kodu</div>
                    <div class="code">{code}</div>
                </div>
                <p class="expire">⏰ Bu kod 10 dakika içinde geçerliliğini yitirecektir.</p>
                <p class="text">
                    Bu e-postayı sen talep etmediysen, lütfen dikkate alma.
                </p>
            </div>
            <div class="footer">
                CS Borsa Dashboard © 2026 — Yatırım Analiz Platformu
            </div>
        </div>
    </body>
    </html>
    """

    plain_text = f"""
CS Ailesine Hoş Geldin, {username}!

Borsa Dashboard hesabın oluşturuldu.
Aktivasyon kodun: {code}

Bu kod 10 dakika içinde geçerliliğini yitirecektir.
    """

    return _send_email(to_email, subject, html_body, plain_text)


def send_alert_email(to_email: str, username: str, ticker: str, direction: str, target_price: float, live_price: float) -> bool:
    """
    Send a price alert notification email.
    Returns True if sent successfully, False otherwise.
    """
    direction_tr = "üstüne çıktı" if direction == "above" else "altına düştü"
    subject = f"🔔 Fiyat Alarmı — {ticker} hedef fiyata ulaştı!"

    html_body = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body {{ font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 0; background: #0B1120; }}
            .container {{ max-width: 520px; margin: 40px auto; background: #131B2E; border-radius: 16px; overflow: hidden; box-shadow: 0 8px 32px rgba(0,0,0,0.3); border: 1px solid rgba(245,158,11,0.3); }}
            .header {{ background: linear-gradient(135deg, #F59E0B, #EF4444); padding: 32px; text-align: center; }}
            .header h1 {{ color: white; margin: 0; font-size: 20px; letter-spacing: 2px; }}
            .header .icon {{ font-size: 40px; margin-bottom: 12px; }}
            .body {{ padding: 32px; }}
            .greeting {{ font-size: 18px; color: #F1F5F9; font-weight: 800; margin-bottom: 16px; }}
            .text {{ color: #94A3B8; font-size: 14px; line-height: 1.7; margin-bottom: 16px; }}
            .alert-box {{ background: rgba(245,158,11,0.1); border: 2px solid #F59E0B; border-radius: 12px; padding: 24px; text-align: center; margin: 20px 0; }}
            .ticker {{ font-size: 28px; font-weight: 900; color: #FBBF24; letter-spacing: 4px; }}
            .price-row {{ display: flex; justify-content: space-around; margin-top: 16px; }}
            .price-item {{ text-align: center; }}
            .price-label {{ font-size: 11px; color: #64748B; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 4px; }}
            .price-value {{ font-size: 22px; font-weight: 800; color: #10B981; }}
            .target-value {{ font-size: 22px; font-weight: 800; color: #F59E0B; }}
            .footer {{ padding: 20px 32px; background: #0F172A; text-align: center; font-size: 11px; color: #475569; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="icon">🔔</div>
                <h1>FIYAT ALARMI</h1>
            </div>
            <div class="body">
                <p class="greeting">Merhaba {username},</p>
                <p class="text">
                    <strong>{ticker}</strong> hissesi belirlediğin hedef fiyatın {direction_tr}!
                </p>
                <div class="alert-box">
                    <div class="ticker">{ticker}</div>
                    <table style="width:100%; margin-top:16px; border-collapse:collapse;">
                        <tr>
                            <td style="text-align:center; padding:8px;">
                                <div class="price-label">Hedef Fiyat</div>
                                <div class="target-value">${target_price:.2f}</div>
                            </td>
                            <td style="text-align:center; padding:8px;">
                                <div class="price-label">Güncel Fiyat</div>
                                <div class="price-value">${live_price:.2f}</div>
                            </td>
                        </tr>
                    </table>
                </div>
                <p class="text">
                    Şimdi harekete geçmek için Borsa Dashboard'a giriş yapabilirsin.
                    Bu alarm otomatik olarak kaldırıldı.
                </p>
            </div>
            <div class="footer">
                CS Borsa Dashboard © 2026 — Yatırım Analiz Platformu
            </div>
        </div>
    </body>
    </html>
    """

    plain_text = f"""
Merhaba {username},

{ticker} hissesi belirlediğin hedef fiyatın {direction_tr}!

Hedef Fiyat: ${target_price:.2f}
Güncel Fiyat: ${live_price:.2f}

Şimdi harekete geçmek için Borsa Dashboard'a giriş yapabilirsin.
Bu alarm otomatik olarak kaldırıldı.
    """

    return _send_email(to_email, subject, html_body, plain_text)
