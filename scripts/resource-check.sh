#!/usr/bin/env bash
# MemAvailable includes reclaimable cache; do not use the misleading MemFree value.
require_install_memory() {
    local minimum_kb=${1:-163840} available_kb
    [[ -r /proc/meminfo ]] || return 0
    available_kb=$(awk '$1 == "MemAvailable:" {print $2}' /proc/meminfo)
    [[ $available_kb =~ ^[0-9]+$ ]] || return 0
    if (( available_kb < minimum_kb )); then
        printf 'Insufficient available RAM: %s KiB (need %s KiB). Skipping this step safely.\n' "$available_kb" "$minimum_kb" >&2
        return 1
    fi
}
