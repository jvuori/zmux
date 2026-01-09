#!/bin/sh
# wsl-battery.sh - simple battery reporter for WSL and Linux
# Outputs a small bar and percentage (e.g. "████░░░░░░ 40%")

set -eu

pct=""

# 1) Try native Linux power supply info
if [ -d /sys/class/power_supply ]; then
  for d in /sys/class/power_supply/BAT* /sys/class/power_supply/battery 2>/dev/null; do
    [ -f "$d/capacity" ] && pct=$(cat "$d/capacity" 2>/dev/null) && break
    if [ -f "$d/charge_now" ] && [ -f "$d/charge_full" ]; then
      charge_now=$(cat "$d/charge_now" 2>/dev/null || echo)
      charge_full=$(cat "$d/charge_full" 2>/dev/null || echo)
      if [ -n "$charge_now" ] && [ -n "$charge_full" ] && [ "$charge_full" -gt 0 ] 2>/dev/null; then
        pct=$((100 * charge_now / charge_full))
        break
      fi
    fi
  done
fi

# 2) If not found, try Windows via PowerShell (WSL2)
if [ -z "$pct" ] && command -v powershell.exe >/dev/null 2>&1; then
  # Attempt to query Win32_Battery EstimatedChargeRemaining
  out=$(powershell.exe -NoProfile -Command "try { \$b=Get-CimInstance -ClassName Win32_Battery -ErrorAction Stop; if(\$b) { Write-Output \$b.EstimatedChargeRemaining } } catch { exit 2 }" 2>/dev/null || true)
  out=$(printf "%s" "$out" | tr -d '\r' | tr -d '[:space:]')
  if [ -n "$out" ]; then
    pct="$out"
  fi
fi

# 3) If still empty, print N/A
if [ -z "$pct" ]; then
  printf "🔌 N/A"
  exit 0
fi

# Clamp and ensure numeric
case "$pct" in
  ''|*[!0-9]*) pct=0 ;;
esac
if [ "$pct" -lt 0 ]; then pct=0; fi
if [ "$pct" -gt 100 ]; then pct=100; fi

# Build a 10-block bar
filled=$(( (pct + 5) / 10 ))
bar=""
i=0
while [ $i -lt $filled ]; do
  bar="$bar█"
  i=$((i+1))
done
while [ $i -lt 10 ]; do
  bar="$bar░"
  i=$((i+1))
done

printf "%s %s%%" "$bar" "$pct"
