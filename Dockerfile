# --- STAGE 1: Builder (Dependency Installation) ---
# Use a full Python image to quickly install all dependencies
FROM python:3.11-slim AS builder


# Set working directory
WORKDIR /app

# Copy dependency file and install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# --- STAGE 2: Runtime (Minimal Environment Setup) ---
# Use a minimal Debian base for a much smaller final image
FROM debian:bullseye-slim

# 1. Set TZ=UTC environment variable (critical for TOTP time synchronization)
ENV TZ=UTC

# 2. Install system dependencies (cron daemon, timezone data, and runtime libs)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cron \
        tzdata \
        # Dependencies for cryptography/SSL and build tools needed for runtime
        libssl-dev \
        libffi-dev \
        build-essential && \
    # Clean up caches to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 3. Configure timezone
RUN ln -fs /usr/share/zoneinfo/UTC /etc/localtime && dpkg-reconfigure --frontend noninteractive tzdata

# Set working directory
WORKDIR /app

# 4. Copy installed Python environment from builder stage
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# 5. Copy application code, private key, and cron configuration
COPY api.py .
COPY student_private.pem .
COPY scripts /app/scripts
COPY crontab.txt /etc/cron.d/crontab-2fa

# 6. Setup cron job (set permissions and install the crontab file)
RUN chmod 0644 /etc/cron.d/crontab-2fa && \
    crontab /etc/cron.d/crontab-2fa

# 7. Create volume mount points
RUN mkdir -p /data /cron && \
    chmod 755 /data /cron

# 8. EXPOSE 8080 (for the FastAPI server)
EXPOSE 8080

# 9. Start cron and application
# Starts 'cron' in the foreground (-f) and then starts 'uvicorn' as the main foreground process.
CMD ["sh", "-c", "cron -f && uvicorn api:app --host 0.0.0.0 --port 8080"]