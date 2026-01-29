#!/bin/bash

# PID to kill when memory threshold is reached
PID=44040

# Memory threshold: 1.3 TiB (GiB)
MAX_GB=1331

# Check interval (seconds)
INTERVAL=30

while kill -0 "$PID" 2>/dev/null; do
  MEM_TOTAL_KB=$(awk '/MemTotal:/ {print $2}' /proc/meminfo)
  MEM_AVAIL_KB=$(awk '/MemAvailable:/ {print $2}' /proc/meminfo)

  # /proc
  if [[ -z "$MEM_TOTAL_KB" || -z "$MEM_AVAIL_KB" ]]; then
    echo "[$(date '+%F %T')] MEM info unavailable"
    sleep "$INTERVAL"
    continue
  fi

  MEM_USED_KB=$((MEM_TOTAL_KB - MEM_AVAIL_KB))
  MEM_USED_GB=$((MEM_USED_KB / 1024 / 1024))

  # HeartBeat output
  echo "[$(date '+%F %T')] MEM_USED=${MEM_USED_GB}GB (limit ${MAX_GB}GB), watching PID=$PID"

  if (( MEM_USED_GB > MAX_GB )); then
    echo "[$(date '+%F %T')] MEM_USED=${MEM_USED_GB}GB > ${MAX_GB}GB, killing PID=$PID"
    kill "$PID"

    sleep 5

    if kill -0 "$PID" 2>/dev/null; then
      echo "[$(date '+%F %T')] PID=$PID still alive, SIGKILL"
      kill -9 "$PID"
    fi

    exit 0
  fi

  sleep "$INTERVAL"
done

echo "[$(date '+%F %T')] PID=$PID already exited"

