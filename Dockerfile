# Use Ubuntu LTS as base image
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# Install core packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ubuntu-standard \
    software-properties-common \
    xrdp \
    xorgxrdp \
    xorg \
    xserver-xorg-core \
    xserver-xorg-input-all \
    xserver-xorg-video-all \
    xauth \
    x11-xserver-utils \
    x11-utils \
    x11-apps \
    xfce4 \
    xfce4-goodies \
    xfce4-terminal \
    dbus-x11 \
    policykit-1 \
    openssh-server \
    sudo \
    nano \
    wget \
    curl \
    git \
    locales \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Generate locales
RUN locale-gen en_US.UTF-8

# Create required directories
RUN mkdir -p /etc/polkit-1/localauthority/50-local.d \
    /var/run/xrdp \
    /var/run/xrdp/sockdir \
    /root/.config/autostart \
    /root/.cache \
    /root/.local/share/xorg

# Configure XRDP
RUN sed -i 's/port=3389/port=3390/g' /etc/xrdp/xrdp.ini && \
    sed -i 's/max_bpp=32/#max_bpp=32\nmax_bpp=128/g' /etc/xrdp/xrdp.ini && \
    sed -i 's/xserverbpp=24/#xserverbpp=24\nxserverbpp=128/g' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/g' /etc/xrdp/xrdp.ini && \
    sed -i 's/crypt_level=high/crypt_level=none/g' /etc/xrdp/xrdp.ini && \
    sed -i 's/bitmap_compression=true/bitmap_compression=false/g' /etc/xrdp/xrdp.ini && \
    echo "xfce4-session" > /root/.xsession && \
    echo "#!/bin/sh" > /etc/xrdp/startwm.sh && \
    echo "unset DBUS_SESSION_BUS_ADDRESS" >> /etc/xrdp/startwm.sh && \
    echo "exec /bin/sh /etc/X11/Xsession" >> /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh

# Configure polkit for XRDP
RUN echo "[Allow Colord all Users]" > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla && \
    echo "Identity=unix-user:*" >> /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla && \
    echo "Action=org.freedesktop.color-manager.*" >> /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla && \
    echo "ResultAny=yes" >> /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla && \
    echo "ResultInactive=yes" >> /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla && \
    echo "ResultActive=yes" >> /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla

# Configure SSH
RUN mkdir -p /var/run/sshd && \
    echo 'root:root' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Configure XFCE autostart
RUN echo "[Desktop Entry]" > /root/.config/autostart/xrdp-config.desktop && \
    echo "Type=Application" >> /root/.config/autostart/xrdp-config.desktop && \
    echo "Exec=/usr/bin/setxkbmap -layout us" >> /root/.config/autostart/xrdp-config.desktop && \
    echo "Name=Keyboard Layout" >> /root/.config/autostart/xrdp-config.desktop && \
    echo "X-GNOME-Autostart-enabled=true" >> /root/.config/autostart/xrdp-config.desktop

# Fix permissions
RUN chown -R root:root /root && \
    chmod 755 /root && \
    chmod 1777 /tmp && \
    chmod 1777 /var/run/xrdp && \
    chmod 1777 /var/run/xrdp/sockdir

# Set up environment
RUN echo "export XDG_RUNTIME_DIR=/tmp/runtime-root" >> /root/.bashrc && \
    echo "export DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/dbus-session" >> /root/.bashrc && \
    mkdir -p /tmp/runtime-root && \
    chmod 700 /tmp/runtime-root

# Expose ports
EXPOSE 22 3390

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD netstat -tuln | grep -q 3390 && netstat -tuln | grep -q 22

# Start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Start command
CMD ["/start.sh"]
