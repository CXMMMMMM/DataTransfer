#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <main_job_pid>"
    exit 1
fi

JOB_PID=$1

# 获取主进程 + 子进程 PID 列表
pids=$(pstree -p $JOB_PID | grep -o '[0-9]\+')

total_pss=0
for pid in $pids; do
    if [ -f /proc/$pid/smaps ]; then
        pss=$(awk '/Pss:/ {sum+=$2} END {print sum}' /proc/$pid/smaps)
        total_pss=$((total_pss + pss))
    fi
done

echo "Job PID $JOB_PID + child processes total PSS memory: $total_pss KB (~$((total_pss/1024)) MB)"

