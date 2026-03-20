#!/bin/bash
# 47 Industries - About This Mac style system info

OS_NAME="47 OS"
OS_VERSION="1.0"
KERNEL=$(uname -r)
CPU=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^ //')
RAM=$(free -h | awk '/Mem:/ {print $2}')
GPU=$(lspci 2>/dev/null | grep -i vga | cut -d: -f3 | sed 's/^ //' | head -1)
DISK=$(df -h / | awk 'NR==2 {print $2 " (" $5 " used)"}')
UPTIME=$(uptime -p | sed 's/^up //')
HOSTNAME=$(hostname)

zenity --info --title="About $OS_NAME" --width=400 --no-wrap --text="<span size='xx-large' weight='bold'>$OS_NAME</span>
<span size='large'>Version $OS_VERSION</span>

<b>$HOSTNAME</b>

<b>Processor:</b>  $CPU
<b>Memory:</b>  $RAM
<b>Graphics:</b>  $GPU
<b>Storage:</b>  $DISK
<b>Kernel:</b>  $KERNEL
<b>Uptime:</b>  $UPTIME

<span size='small' color='gray'>Built by 47 Industries</span>" 2>/dev/null
