FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    tightvncserver \
    novnc \
    websockify \
    openssl \
    bash \
    procps \
    && rm -rf /var/lib/apt/lists/*

# مهم: پورت 8080 رو expose کن تا blitz اون رو به عنوان پورت اصلی وب بشناسه
EXPOSE 8080

# اسکریپت راه‌اندازی با بررسی دقیق مراحل
CMD bash -c "\
    echo '--- starting vncserver on :1 ---' && \
    mkdir -p /root/.vnc && \
    vncserver :1 -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE && \
    echo '--- vncserver started, checking port 5901 ---' && \
    sleep 2 && \
    (netstat -tlnp | grep 5901 || echo 'WARNING: port 5901 not listening') && \
    echo '--- generating SSL cert ---' && \
    openssl req -new -subj '/C=US' -x509 -days 365 -nodes -out /root/self.pem -keyout /root/self.pem 2>/dev/null && \
    echo '--- starting websockify on 8080 ---' && \
    websockify -D --web=/usr/share/novnc/ --cert=/root/self.pem 8080 localhost:5901 && \
    echo '--- websockify started, checking port 8080 ---' && \
    sleep 2 && \
    (netstat -tlnp | grep 8080 || echo 'WARNING: port 8080 not listening') && \
    echo '--- ALL SERVICES RUNNING ---' && \
    tail -f /dev/null \
"
