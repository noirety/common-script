#!/bin/bash

# 检查是否提供了参数
if [ -z "$1" ]; then
  echo "请提供查询用户"
  exit 1
fi

# 函数：检查并安装缺失的软件
check_and_install() {
  local package=$1
  if ! command -v $package &> /dev/null; then
    echo "$package 未安装，正在安装..."
    if [[ -n "$(command -v apt-get)" ]]; then
      sudo apt-get update
      sudo apt-get install -y $package
    elif [[ -n "$(command -v yum)" ]]; then
      sudo yum install -y $package
    elif [[ -n "$(command -v dnf)" ]]; then
      sudo dnf install -y $package
    else
      echo "无法自动安装 $package，请手动安装。"
      exit 1
    fi
  fi
}

# 检查并安装必要的软件
check_and_install bc
check_and_install jq

# 函数：查询流量并转换为适当的单位
query_traffic() {
  local name=$1
  local direction=$2
  local result=$(xray api stats --server=127.0.0.1:31399 -name "inbound>>>$name>>>traffic>>>$direction")
  local value=$(echo $result | jq -r '.stat.value')
  local value_in_mb=$(echo "scale=2; $value / (1024 * 1024)" | bc)

  if (( $(echo "$value_in_mb >= 1024" | bc -l) )); then
    local value_in_gb=$(echo "scale=2; $value_in_mb / 1024" | bc)
    echo "$value_in_gb GB"
  else
    echo "$value_in_mb MB"
  fi
}

echo "---------------------"
# 遍历所有传入的参数（用户名）
for name in "$@"; do
  # 查询下载量和上传量
  down_value=$(query_traffic "$name" "downlink")
  up_value=$(query_traffic "$name" "uplink")

  # 输出结果
  echo "用户: $name"
  echo "下载量: $down_value"
  echo "上传量: $up_value"
  echo "---------------------"
done