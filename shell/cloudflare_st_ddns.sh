#!/bin/bash

domain_name=''

token=''

ddns_domain_name=''

program_path='/opt/CloudflareST'

# 日志文件
logfile="${program_path}/cloudflare_st_ddns.log"

# 定义颜色
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
NC='\033[0m'

# 定义日志函数
log() {
  local level="$1"
  local message="$2"
  # 获取当前时间
  timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  # 判断日志级别并设置颜色
  local color
  case "$level" in
    INFO)
      color="$GREEN"
      ;;
    WARN)
      color="$YELLOW"
      ;;
    ERROR)
      color="$RED"
      ;;
    *)
      color="$NC"
      ;;
  esac
  # 格式化日志消息
  local log_message="[$timestamp] [$level] $message"
  # 输出日志到控制台
  echo -e "${color}${log_message}${NC}"

  # 记录日志到文件
  echo "$log_message" >> "$logfile"
}

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

get_cloudflare_zone_id(){
  local domain_name="$1"
  local token="$2"

  json_data=$(curl -s -X GET --location "https://api.cloudflare.com/client/v4/zones?name=$domain_name" \
   -H "Authorization: Bearer $token" \
   -H "Content-Type: application/json")

  zone_id=$(echo "$json_data" | jq -r '.result[0].id')

  echo "$zone_id"
}

get_cloudflare_dns_list(){
  local zone_id="$1"
  local token="$2"
  json_data=$(curl -s -X GET --location "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
   -H "Authorization: Bearer $token" \
   -H "Content-Type: application/json")

  ids_and_names=$(echo "$json_data" | jq -r '.result[] | "\(.id) \(.name)"')
  echo $ids_and_names
}

modify_cloudflare_dns_records(){
  local zone_id="$1"
  local dns_id="$2"
  local token="$3"
  local ddns_domain_name="$4"
  local ipv4="$5"

  json_data=$(curl -s -X PATCH --location "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$dns_id" \
   -H "Authorization: Bearer $token" \
   -H "Content-Type: application/json" \
   -d '{ "type": "A", "name": "'$ddns_domain_name'", "content": "'$ipv4'", "proxied": false, "id": "1" }')

  echo $json_data
}

add_cloudflare_dns_records(){
  local zone_id="$1"
  local token="$2"
  local ddns_domain_name="$3"
  local ipv4="$4"

  json_data=$(curl -s -X POST --location "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
   -H "Authorization: Bearer $token" \
   -H "Content-Type: application/json" \
   -d '{ "type": "A", "name": "'$ddns_domain_name'", "content": "'$ipv4'", "proxied": false, "id": "1" }')

  echo $json_data
}

get_cloudflare_st_data(){
  local filename=$1
  first_data=$(sed -n '2p' "$filename" | cut -d, -f1)
  echo $first_data
}

main(){
  # 检查并安装必要的软件
  check_and_install bc
  check_and_install jq

  echo -n > ${program_path}/result.csv

  # 判断当前解析的ip是否合格
  current_ip=$(dig +short ${ddns_domain_name})

  # 检查输入是否为空
  if [ -n "$current_ip" ]
  then
    log "INFO" "当前域名:${ddns_domain_name},已存在DNS解析:${current_ip}"
    ${program_path}/CloudflareST -n 10 -t 40 -tp 443 -ip 104.16.165.228 -tlr 0.01 -sl 15 -tl 120 -o ${program_path}/result.csv
    check_ip=$(get_cloudflare_st_data "${program_path}/result.csv")
    if [ "$check_ip" = "$current_ip" ]; then
      log "INFO" "当前域名:${ddns_domain_name},DNS解析:${current_ip},测试合格,程序结束"
      return 1
    else
      log "INFO" "当前域名:${ddns_domain_name},DNS解析:${current_ip},测试不合格,继续进行Cloudflare优选"
    fi
  fi

  log "INFO" "Cloudflare优选程序开始执行"

  ${program_path}/CloudflareST -n 10 -t 10 -f ${program_path}/ip.txt -o ${program_path}/result.csv

  log "INFO" "Cloudflare优选程序执行完成"

  cloudflare_ip=$(get_cloudflare_st_data "${program_path}/result.csv")

   # 检查输入是否为空
  if [ -z "$cloudflare_ip" ]
  then
      log "ERROR" "获取cloudflare优选IP失败，结束进程"
      return 1
  fi

  log "INFO" "获取cloudflare优选IP: $cloudflare_ip"

  # 获取cloudflare的zone_id
  zone_id=$(get_cloudflare_zone_id $domain_name $token)

  if [ -z "$zone_id" ]
  then
      log "ERROR" "获取cloudflare zone_id失败，结束进程"
      return 1
  fi

  log "INFO" "获取cloudflare zone_id: $zone_id"

  # 根据zone_id获取DNS列表
  ids_and_names=$(get_cloudflare_dns_list $zone_id $token)

  log "INFO" "获取cloudflare dns解析列表: $ids_and_names"

  # 查找name为best.sparkless.de的项，并获取id
  dns_id=$(echo "$ids_and_names" | awk -v name="$ddns_domain_name" '$2 == name {print $1}')

  local alterRes
  # 判断是否找到
  if [ -n "$dns_id" ]; then
    log "INFO" "$ddns_domain_name 已存在DNS解析，执行修改操作，ID:$dns_id"
    alterRes=$(modify_cloudflare_dns_records $zone_id $dns_id $token $ddns_domain_name $cloudflare_ip)
  else
    log "INFO" "$ddns_domain_name 不存在解析dns列表，执行新增操作"
    alterRes=$(add_cloudflare_dns_records $zone_id $token $ddns_domain_name $cloudflare_ip)
  fi

  success=$(echo "$alterRes" | jq -r '.success')

  log "INFO" "执行结果: $success"
}

main