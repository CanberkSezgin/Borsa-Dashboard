"""
==============================================================================
  Email Service — Gmail SMTP for Verification Codes
==============================================================================
  • Sends beautiful HTML verification emails
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


def send_verification_email(to_email: str, username: str, code: str) -> bool:
    """
    Send a verification email with a beautiful HTML template.
    Returns True if sent successfully, False otherwise.
    """
    if not SMTP_PASSWORD:
        print(f"[EMAIL] ⚠️ SMTP_PASSWORD not set. Email not sent. Code: {code}")
        return False

    subject = "Borsa Dashboard — E-posta Doğrulama"

    html_body = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="UTF-8">
        <style>
            body {{ font-family: 'Segoe UI', Arial, sans-serif; margin: 0; padding: 0; background: #F1F5F9; }}
            .container {{ max-width: 520px; margin: 40px auto; background: #FFFFFF; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 24px rgba(0,0,0,0.08); }}
            .header {{ background: linear-gradient(135deg, #6366F1, #8B5CF6); padding: 32px; text-align: center; }}
            .header h1 {{ color: white; margin: 0; font-size: 20px; letter-spacing: 2px; }}
            .header .icon {{ font-size: 40px; margin-bottom: 12px; }}
            .body {{ padding: 32px; }}
            .welcome {{ font-size: 18px; color: #0F172A; font-weight: 700; margin-bottom: 8px; }}
            .text {{ color: #475569; font-size: 14px; line-height: 1.6; margin-bottom: 24px; }}
            .code-box {{ background: linear-gradient(135deg, #EEF2FF, #E0E7FF); border: 2px solid #6366F1; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0; }}
            .code {{ font-size: 36px; font-weight: 900; color: #6366F1; letter-spacing: 8px; }}
            .code-label {{ font-size: 12px; color: #64748B; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 8px; }}
            .footer {{ padding: 20px 32px; background: #F8FAFC; text-align: center; font-size: 11px; color: #94A3B8; }}
            .expire {{ color: #EF4444; font-weight: 600; font-size: 12px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="icon">📈</div>
                <h1>BORSA DASHBOARD</h1>
            </div>
            <div class="body">
                <p class="welcome">Ailemize Hoş Geldiniz, Sayın {username}! 🎉</p>
                <p class="text">
                    Borsa Dashboard hesabınız başarıyla oluşturuldu. 
                    Hesabınızı aktifleştirmek için aşağıdaki doğrulama kodunu kullanın:
                </p>
                <div class="code-box">
                    <div class="code-label">Aktivasyon Kodu</div>
                    <div class="code">{code}</div>
                </div>
                <p class="expire">⏰ Bu kod 10 dakika içinde geçerliliğini yitirecektir.</p>
                <p class="text">
                    Bu e-postayı siz talep etmediyseniz, lütfen dikkate almayın.
                </p>
            </div>
            <div class="footer">
                Borsa Dashboard © 2026 — Yatırım Analiz Platformu
            </div>
        </div>
    </body>
    </html>
    """

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = f"Borsa Dashboard <{SMTP_EMAIL}>"
    msg["To"] = to_email

    # Plain text fallback
    plain_text = f"""
Ailemize Hoş Geldiniz, Sayın {username}!

Borsa Dashboard hesabınız oluşturuldu.
Aktivasyon kodunuz: {code}

Bu kod 10 dakika içinde geçerliliğini yitirecektir.
    """

    msg.attach(MIMEText(plain_text, "plain"))
    msg.attach(MIMEText(html_body, "html"))

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as server:
            server.starttls()
            server.login(SMTP_EMAIL, SMTP_PASSWORD)
            server.send_message(msg)
        print(f"[EMAIL] ✅ Verification email sent to {to_email}")
        return True
    except Exception as e:
        print(f"[EMAIL] ❌ Failed to send email: {e}")
        return False
