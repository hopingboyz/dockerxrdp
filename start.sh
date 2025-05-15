#!/bin/bash

# Start DBus
mkdir -p /var/run/dbus
dbus-daemon --system --fork

# Start SSH
service ssh start

# Prepare X11 directory
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

# Start XRDP
/usr/sbin/xrdp --nodaemon
