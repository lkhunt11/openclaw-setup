#!/usr/bin/env bats
# tests/gateway-healthcheck.bats
# gateway-healthcheck Composite Action 로직 단위 테스트

# ── 헬퍼: healthcheck 로직 추출 (action.yml 로직과 동일) ────────────────────
run_healthcheck() {
  local port="$1"
  local timeout_sec="$2"
  local url="http://localhost:${port}/health"
  local elapsed=0
  local status="unhealthy"

  while [ "$elapsed" -lt "$timeout_sec" ]; do
    if curl -sf --connect-timeout 1 --max-time 2 "$url" > /dev/null 2>&1; then
      status="healthy"
      break
    fi
    sleep 1
    elapsed=$((elapsed + 1))
  done

  echo "$status"
  [ "$status" = "healthy" ]
}

# ── 헬퍼: mock HTTP 서버 ─────────────────────────────────────────────────────
start_health_server() {
  local port="$1"
  python3 -c "
import http.server, socketserver

class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b'ok')
    def log_message(self, *a): pass

with socketserver.TCPServer(('', $port), H) as s:
    s.handle_request()
" &
  MOCK_PID=$!
  sleep 0.4
}

# ── 테스트 1: 즉시 응답 시 healthy ──────────────────────────────────────────
@test "게이트웨이 즉시 응답 시 healthy 반환" {
  start_health_server 18881
  run run_healthcheck 18881 5
  kill "$MOCK_PID" 2>/dev/null || true
  [ "$status" -eq 0 ]
  [[ "$output" == "healthy" ]]
}

# ── 테스트 2: 응답 없을 때 unhealthy ────────────────────────────────────────
@test "timeout 내 응답 없으면 unhealthy 반환" {
  # 아무것도 없는 포트 사용
  run run_healthcheck 19881 2
  [ "$status" -ne 0 ]
  [[ "$output" == "unhealthy" ]]
}

# ── 테스트 3: 기본값 검증 ────────────────────────────────────────────────────
@test "action.yml 기본 포트가 18789" {
  run grep 'default:' .github/actions/gateway-healthcheck/action.yml
  [[ "$output" == *"18789"* ]]
}

@test "action.yml 기본 timeout이 30초" {
  run grep "default: '30'" .github/actions/gateway-healthcheck/action.yml
  [ "$status" -eq 0 ]
}

# ── 테스트 4: 출력 status 값 검증 ───────────────────────────────────────────
@test "healthy 시 출력이 정확히 'healthy'" {
  start_health_server 18882
  result=$(run_healthcheck 18882 5 || true)
  kill "$MOCK_PID" 2>/dev/null || true
  [[ "$result" == "healthy" ]]
}

@test "unhealthy 시 출력이 정확히 'unhealthy'" {
  result=$(run_healthcheck 19882 2 || true)
  [[ "$result" == "unhealthy" ]]
}

# ── 테스트 5: retry 로직 ────────────────────────────────────────────────────
@test "timeout 값이 0이면 즉시 unhealthy" {
  run run_healthcheck 19883 0
  [ "$status" -ne 0 ]
}
