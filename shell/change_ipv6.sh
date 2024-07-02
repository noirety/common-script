#!/bin/bash

# 子网前缀
SUBNET="0:0:0:0"
# 网络接口名称
INTERFACE="ens33"

# 随机生成接口标识符（64 位）
generate_interface_id() {
    printf "%x:%x:%x:%x" \
        $((RANDOM % 0xffff)) \
        $((RANDOM % 0xffff)) \
        $((RANDOM % 0xffff)) \
        $((RANDOM % 0xffff))
}

## 生成新的 IPv6 地址
NEW_IPV6="$SUBNET:$(generate_interface_id)"

# 删除旧的 IPv6 地址
# 获取ipv6地址：ip -6 addr show dev $INTERFACE | grep 'global' | awk '{print $2}' | cut -d/ -f1
ipv6_addrs=$(ip -6 addr show dev $INTERFACE | grep 'global' | awk '{print $2}')

# 遍历并删除每个IPv6地址
for addr in $ipv6_addrs; do
    sudo ip -6 addr del $addr dev $INTERFACE
done

# 分配新的 IPv6 地址
sudo ip -6 addr add $NEW_IPV6/64 dev $INTERFACE

# 显示新的 IPv6 地址
ip -6 addr show dev $INTERFACE

echo "New IPv6 address assigned: $NEW_IPV6"