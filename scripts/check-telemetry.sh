#!/usr/bin/env bash
# Checks that a service's traces, logs and metrics reached Grafana LGTM.
# Usage: scripts/check-telemetry.sh meal-recipes [grafana_url]
set -euo pipefail

service="${1:?usage: $0 <service-name> [grafana_url]}"
grafana="${2:-http://localhost:3000}"
proxy="$grafana/api/datasources/proxy/uid"
since=$(( $(date +%s) - 3600 ))
failed=0

check() {
  local signal="$1" count="$2"
  if [[ "$count" -gt 0 ]]; then
    echo "ok    $signal: $count"
  else
    echo "FAIL  $signal: nothing for service.name=$service in the last hour"
    failed=1
  fi
}

traces=$(curl -sfG "$proxy/tempo/api/search" \
  --data-urlencode "q={resource.service.name=\"$service\"}" \
  --data-urlencode "start=$since" --data-urlencode "end=$(date +%s)" --data-urlencode "limit=20" \
  | python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("traces") or []))')
check traces "$traces"

logs=$(curl -sfG "$proxy/loki/loki/api/v1/query_range" \
  --data-urlencode "query={service_name=\"$service\"}" \
  --data-urlencode "start=${since}000000000" --data-urlencode "limit=100" \
  | python3 -c 'import json,sys; print(sum(len(s["values"]) for s in json.load(sys.stdin)["data"]["result"]))')
check logs "$logs"

metrics=$(curl -sfG "$proxy/prometheus/api/v1/query" \
  --data-urlencode "query=count({job=\"$service\"})" \
  | python3 -c 'import json,sys; r=json.load(sys.stdin)["data"]["result"]; print(int(r[0]["value"][1]) if r else 0)')
check "metric series" "$metrics"

exit "$failed"
