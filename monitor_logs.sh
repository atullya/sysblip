#!/bin/bash

LOG_FILE="health_monitor.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

API_ENDPOINTS=(
  "https://httpbin.org/get"
  "https://jsonplaceholder.typicode.com/posts/1"
)

LOG_PATHS=(
  "/var/log/syslog"
  "/var/log/auth.log"
)

ERROR_KEYWORDS="error|fail|critical|denied|refused"

ALERT_CPU=80
ALERT_MEM=80
ALERT_DISK=90

log() {
  echo "[$TIMESTAMP] $1" | tee -a "$LOG_FILE"
}

separator() {
  echo "-------------------------------------------" | tee -a "$LOG_FILE"
}

check_cpu() {
  separator
  log "CPU USAGE"
  cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | tr -d '%')
  if [ -z "$cpu_idle" ]; then
    cpu_idle=$(top -bn1 | grep "Cpu(s)" | sed 's/.*,\s*\([0-9.]*\)\s*id.*/\1/')
  fi
  cpu_used=$(echo "100 - $cpu_idle" | bc 2>/dev/null || echo "N/A")
  log "CPU Used: ${cpu_used}%"
  if [ "$cpu_used" != "N/A" ] && (( $(echo "$cpu_used > $ALERT_CPU" | bc -l) )); then
    log "ALERT: CPU usage is above ${ALERT_CPU}%"
  fi
}

check_memory() {
  separator
  log "MEMORY USAGE"
  total=$(free -m | awk '/^Mem:/ {print $2}')
  used=$(free -m | awk '/^Mem:/ {print $3}')
  available=$(free -m | awk '/^Mem:/ {print $7}')
  percent=$(awk "BEGIN {printf \"%.1f\", ($used/$total)*100}")
  log "Total: ${total}MB  |  Used: ${used}MB  |  Available: ${available}MB"
  log "Memory Used: ${percent}%"
  if (( $(echo "$percent > $ALERT_MEM" | bc -l) )); then
    log "ALERT: Memory usage is above ${ALERT_MEM}%"
  fi
}

check_disk() {
  separator
  log "DISK USAGE"
  df -h | grep -vE "^Filesystem|tmpfs|udev|loop" | while read -r line; do
    mount=$(echo "$line" | awk '{print $6}')
    usage=$(echo "$line" | awk '{print $5}' | tr -d '%')
    size=$(echo "$line" | awk '{print $2}')
    used=$(echo "$line" | awk '{print $3}')
    avail=$(echo "$line" | awk '{print $4}')
    log "Mount: $mount  |  Size: $size  |  Used: $used  |  Avail: $avail  |  Usage: ${usage}%"
    if [ "$usage" -ge "$ALERT_DISK" ] 2>/dev/null; then
      log "ALERT: Disk usage on $mount is above ${ALERT_DISK}%"
    fi
  done
}

check_api() {
  separator
  log "API HEALTH CHECK"
  for url in "${API_ENDPOINTS[@]}"; do
    response=$(curl -o /dev/null -s -w "%{http_code} %{time_total}" --max-time 10 "$url")
    status_code=$(echo "$response" | awk '{print $1}')
    response_time=$(echo "$response" | awk '{print $2}')
    if [ "$status_code" -eq 200 ] 2>/dev/null; then
      log "UP   [$status_code] ${url}  (${response_time}s)"
    else
      log "DOWN [$status_code] ${url}  (${response_time}s)"
      log "ALERT: API endpoint not responding - $url"
    fi
  done
}

check_logs() {
  separator
  log "LOG ERROR SCAN"
  for logfile in "${LOG_PATHS[@]}"; do
    if [ -f "$logfile" ]; then
      count=$(grep -ciE "$ERROR_KEYWORDS" "$logfile" 2>/dev/null || echo 0)
      log "File: $logfile  |  Matches: $count"
      if [ "$count" -gt 0 ]; then
        log "Last 3 matching lines from $logfile:"
        grep -iE "$ERROR_KEYWORDS" "$logfile" 2>/dev/null | tail -3 | while read -r entry; do
          log "  >> $entry"
        done
      fi
    else
      log "File not found: $logfile"
    fi
  done
}

check_processes() {
  separator
  log "TOP 5 PROCESSES BY CPU"
  ps aux --sort=-%cpu 2>/dev/null | awk 'NR==1 || NR<=6' | tail -5 | while read -r line; do
    log "$line"
  done
}

check_network() {
  separator
  log "NETWORK CONNECTIVITY"
  for host in "8.8.8.8" "1.1.1.1"; do
    if ping -c 1 -W 2 "$host" > /dev/null 2>&1; then
      log "Reachable: $host"
    else
      log "Unreachable: $host"
      log "ALERT: Cannot reach $host"
    fi
  done
}

main() {
  echo "" | tee -a "$LOG_FILE"
  separator
  log "SYSTEM HEALTH REPORT - $TIMESTAMP"
  separator
  check_cpu
  check_memory
  check_disk
  check_network
  check_api
  check_logs
  check_processes
  separator
  log "REPORT COMPLETE - Saved to $LOG_FILE"
  separator
}

main
