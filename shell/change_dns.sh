#!/bin/bash

# 检查是否有 root 权限
if [ "$(id -u)" != "0" ]; then
   echo "此脚本需要 root 权限" 1>&2
   exit 1
fi

cp /etc/resolv.conf /etc/resolv.conf.backup
echo "nameserver 1.1.1.1" > /etc/resolv.conf
echo "nameserver 1.0.0.1" >> /etc/resolv.conf
echo "nameserver 2606:4700:4700::1111" >> /etc/resolv.conf
echo "nameserver 2606:4700:4700::1001" >> /etc/resolv.conf

echo "DNS 已更改为 1.1.1.1"
echo "原始配置已备份到 /etc/resolv.conf.backup"