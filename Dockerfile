# استفاده از نسخه مشخص اوبونتو برای جلوگیری از بروز خطاهای ناگهانی در آینده
FROM ubuntu:22.04

# تنظیمات اولیه برای جلوگیری از پرسیدن سوالات تعاملی در هنگام نصب پکیج‌ها
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tehran

# متغیر محیطی برای پسورد VNC 
# (توجه: داکر به این کار به عنوان یک هشدار امنیتی نگاه می‌کند، اما بیلد را متوقف نمی‌کند)
ENV VNC_PASSWORD=your_secure_password_here

# نصب پیش‌نیازها و بسته‌های مورد نیاز
# نکته کلیدی: بسته tigervnc-tools دستور vncpasswd را فراهم می‌کند
RUN apt-get update && apt-get install -y \
    tigervnc-tools \
    tigervnc-standalone-server \
    tigervnc-common \
    xfce4 \
    xfce4-goodies \
    git \
    wget \
    curl \
    python3 \
    python3-pip \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

# نصب noVNC
RUN git clone --depth 1 https://github.com/novnc/noVNC.git /opt/novnc

# نصب websockify (برای ارتباط noVNC با VNC)
RUN pip3 install websockify

# ایجاد پوشه VNC و تنظیم پسورد
RUN mkdir -p /root/.vnc && \
    echo "$VNC_PASSWORD" | vncpasswd -f > /root/.vnc/passwd && \
    chmod 600 /root/.vnc/passwd

# ایجاد فایل xstartup برای اجرای محیط گرافیکی XFCE
RUN echo '#!/bin/sh\n\
xrdb $HOME/.Xresources\n\
startxfce4 &\n\
' > /root/.vnc/xstartup && chmod +x /root/.vnc/xstartup

# باز کردن پورت‌های VNC (5901) و noVNC (6080)
EXPOSE 5901 6080

# دستور اجرا (شروع VNC و سپس noVNC)
CMD ["/bin/bash", "-c", "vncserver :1 -geometry 1280x720 -depth 24 && /opt/novnc/utils/novnc_proxy --vnc localhost:5901 --listen 6080"]
