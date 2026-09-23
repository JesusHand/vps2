FROM ubuntu:22.04

# جلوگیری از پرسش‌های تعاملی
ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:0 \
    VNC_PASSWORD=miget123 \
    RESOLUTION=1024x768

# نصب بسته‌های ضروری
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    git \
    ca-certificates \
    supervisor \
    xvfb \
    x11vnc \
    openbox \
    firefox \
    xterm \
    dbus \
    libdbus-1-3 \
    fonts-noto \
    fonts-noto-cjk \
    && rm -rf /var/lib/apt/lists/*

# نصب noVNC
RUN mkdir -p /opt/novnc && \
    cd /opt/novnc && \
    wget -q https://github.com/novnc/noVNC/archive/v1.4.0.tar.gz && \
    tar xzf v1.4.0.tar.gz && \
    mv noVNC-1.4.0/* . && \
    rm -rf noVNC-1.4.0 v1.4.0.tar.gz && \
    chmod +x utils/launch.sh

# نصب websockify (برای noVNC)
RUN cd /opt/novnc && \
    git clone https://github.com/novnc/websockify.git --depth 1 && \
    cd websockify && \
    python3 -m pip install --no-cache-dir . && \
    cd .. && \
    rm -rf websockify

# تنظیم VNC
RUN mkdir -p /root/.vnc && \
    echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# ایجاد supervisor configuration
RUN mkdir -p /etc/supervisor/conf.d

RUN cat > /etc/supervisor/conf.d/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
logfile=/var/log/supervisor/supervisord.log
pidfile=/var/run/supervisord.pid

[unix_http_server]
file=/var/run/supervisor.sock

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[program:xvfb]
command=/usr/bin/Xvfb :0 -screen 0 1024x768x24 -ac
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/xvfb.err.log
stdout_logfile=/var/log/supervisor/xvfb.out.log

[program:openbox]
command=/usr/bin/openbox
autostart=true
autorestart=true
environment=DISPLAY=:0
stderr_logfile=/var/log/supervisor/openbox.err.log
stdout_logfile=/var/log/supervisor/openbox.out.log

[program:x11vnc]
command=/usr/bin/x11vnc -display :0 -forever -usepw -rfbport 5900
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/x11vnc.err.log
stdout_logfile=/var/log/supervisor/x11vnc.out.log

[program:novnc]
command=/usr/bin/python3 /opt/novnc/websockify/run 0.0.0.0:6080 localhost:5900 --web /opt/novnc
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/novnc.err.log
stdout_logfile=/var/log/supervisor/novnc.out.log

[program:dbus]
command=/usr/bin/dbus-daemon --system --nofork
autostart=true
autorestart=true
stderr_logfile=/var/log/supervisor/dbus.err.log
stdout_logfile=/var/log/supervisor/dbus.out.log
EOF

# ایجاد دایرکتوری log
RUN mkdir -p /var/log/supervisor

# Expose پورت‌ها
EXPOSE 5900 6080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD x11vnc -ping localhost:5900 || exit 1

# شروع supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
