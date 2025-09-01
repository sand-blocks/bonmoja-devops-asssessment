#!/usr/bin/env bash
set -euo pipefail
URL="${1:-}"
if [[ -z "${URL}" ]]; then
  echo "Usage: $0 <service-url>"
  exit 1
fi
echo "[health_check] Checking ${URL} ..."
response=$(curl -s -m 10 -w "\n%{http_code}" "${URL}" || true)
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | sed '$d')
echo "[health_check] HTTP ${http_code}"
echo "[health_check] Body: ${body}"
if [[ "${http_code}" -ge 200 && "${http_code}" -lt 400 ]]; then
  echo "[health_check] OK"
  exit 0
else
  echo "[health_check] WARNING: unhealthy (code=${http_code})"
  exit 2
fi

