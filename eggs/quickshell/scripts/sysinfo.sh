#!/bin/bash
CPU_FREQ=$(grep "cpu MHz" /proc/cpuinfo | awk '{sum += $4; count++} END {printf "%.0f", sum/count}')
GPU_FREQ=$(nvidia-smi --query-gpu=clocks.gr --format=csv,noheader,nounits)
RAM_USED=$(free -g | awk '/Mem:/ {print $3}')

echo "{\"cpu_freq\": \"${CPU_FREQ}MHz\", \"gpu_freq\": \"${GPU_FREQ}MHz\", \"ram_used\": \"${RAM_USED}\"}"