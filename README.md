# Secure PKI-Based 2FA Microservice (Docker + RSA + TOTP)-23A91A61D8
This project implements a secure, containerized authentication microservice using:
- RSA 4096-bit encryption (OAEP + SHA-256)
- RSA-PSS digital signatures
- TOTP 2FA (SHA-1, 30s window, 6-digit codes)
- Docker multi-stage builds
- Cron job for periodic 2FA code logging
- Persistent storage volumes

1. PROJECT OVERVIEW:
This microservice provides:
1. /decrypt-seed      – Decrypt base64 encrypted seed using RSA private key
2. /generate-2fa      – Generate current TOTP code
3. /verify-2fa        – Verify a provided TOTP code with ±1 time-window tolerance

Seed, once decrypted, is stored persistently in /data/seed.txt so it survives
container restarts. Every minute, a cron job logs latest TOTP code into
/cron/last_code.txt in UTC time.

2. TECHNOLOGIES USED:
- Python / FastAPI (or equivalent framework)
- RSA Cryptography (4096-bit, OAEP-SHA256, PSS-SHA256)
- pyotp for TOTP generation
- Docker multi-stage builds
- Cron daemon
- Linux file system permissions
- Persisted volumes (/data, /cron)

3. DIRECTORY STRUCTURE:
project/
├── app/
│   ├── main.py                     # API server
│   ├── crypto_utils.py             # RSA decrypt + verify
│   ├── totp_utils.py               # TOTP generation + verify
│
├── scripts/
│   ├── generate_keys.py            # RSA 4096-bit key generation
│   ├── request_seed.py             # API request for encrypted seed
│   ├── log_2fa_cron.py             # Cron job script
│
├── cron/
│   └── 2fa-cron                    # Cron config (LF only)
│
├── student_private.pem             # MUST be committed
├── student_public.pem              # MUST be committed
├── instructor_public.pem           # MUST be committed
├── requirements.txt
├── Dockerfile
├── docker-compose.yml
├── .gitattributes
├── .gitignore
└── README.txt

4. API ENDPOINTS:
  1. POST /decrypt-seed
   Body: { "encrypted_seed": "BASE64..." }
   Action: Decrypts seed using RSA-OAEP-SHA256 & stores /data/seed.txt

  2. GET /generate-2fa
   Action: Generates 6-digit TOTP + returns seconds remaining (0–29)

  3. POST /verify-2fa
   Body: { "code": "123456" }
   Action: Verifies TOTP code with ±30s window tolerance

5. DOCKER FEATURES:
- Multi-stage Dockerfile reduces image size
- Cron installed + works with LF line endings
- UTC timezone configured
- Volumes:
    /data → persistent decrypted seed
    /cron → cron logs last 2FA code
- Application + cron daemon start together

6. CRON JOB:
Runs every minute and:
1. Reads /data/seed.txt
2. Generates current TOTP
3. Logs: "YYYY-MM-DD HH:MM:SS - 2FA Code: XXXXXX"
4. Uses UTC time

Ensure .gitattributes contains:
cron/2fa-cron text eol=lf


7. HOW TO RUN LOCALLY:
# Build
docker-compose build

# Start
docker-compose up -d

# Test:
curl -X POST http://localhost:8080/decrypt-seed …

8. IMPORTANT NOTES:
- student_private.pem MUST be committed (task requirement).
- encrypted_seed.txt MUST NOT be committed.
- All cryptographic parameters MUST strictly match specifications.
- Repository URL must be identical for seed request & submission.

9. OUTPUT FILES SAVED IN VOLUMES:
/data/seed.txt         – decrypted 64-char hex seed  
/cron/last_code.txt    – cron logs of 2FA codes  

END OF README
