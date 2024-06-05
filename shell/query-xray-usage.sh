#!/bin/bash

# 检查是否提供了参数
if [ -z "$1" ]; then
  echo "请提供查询参数"
  exit 1
fi

name=$1

# 函数：查询流量并转换为 MB
query_traffic() {
  local temp_name=$1
  local direction=$2
  local result=$(xray api stats --server=127.0.0.1:31399 -name "inbound>>>$temp_name>>>traffic>>>$direction")
  local value=$(echo $result | jq -r '.stat.value')
  local value_in_mb=$(echo "scale=2; $value / (1024 * 1024)" | bc)
  echo $value_in_mb
}

# 查询下载量和上传量
down_value_in_mb=$(query_traffic $name "downlink")
up_value_in_mb=$(query_traffic $name "uplink")

# 输出结果
echo "$name:"
echo "下载量：$down_value_in_mb MB"
echo "上传量：$up_value_in_mb MB"
