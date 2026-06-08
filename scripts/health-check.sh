#!/bin/bash
# scripts/health-check.sh
# OpenClaw 게이트웨이 상태 확인

GATEWAY_URL="${1:-http://localhost:18789}"
echo "🔍 OpenClaw 게이트웨이 헬스체크: $GATEWAY_URL"

HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" \
    --connect-timeout 5 --max-time 10 "$GATEWAY_URL/health" || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ 정상 (HTTP $HTTP_CODE)"
    exit 0
else
    echo "❌ 응답 없음 (HTTP $HTTP_CODE)"
    echo "   openclaw gateway start 를 실행해 주세요."
    exit 1
fi
