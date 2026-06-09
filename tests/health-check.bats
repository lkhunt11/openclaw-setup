#!/usr/bin/env bats
# tests/health-check.bats
# scripts/health-check.sh 단위 테스트

# ── 헬퍼: mock HTTP 서버 시작 ────────────────────────────────────────────────
start_mock_server() {
  local port="$1"
  local status_code="$2"

  # Python3로 단순 HTTP 서버 (nc보다 안정적)
  python3 -c "
import http.server, socketserver, sys

class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(${status_code})
        self.end_headers()
    def log_message(self, *args):
        pass  # 로그 억제

with socketserver.TCPServer(('', ${port}), Handler) as httpd:
    httpd.handle_request()
" &
  MOCK_PID=$!
  sleep 0.3  # 서버 준비 대기
}

# ── 테스트 1: HTTP 200 → exit 0 ─────────────────────────────────────────────
@test "HTTP 200 응답 시 exit 0 반환" {
  start_mock_server 18891 200
  run bash scripts/health-check.sh http://localhost:18891
  kill "$MOCK_PID" 2>/dev/null || true
  [ "$status" -eq 0 ]
}

@test "HTTP 200 응답 시 '✅ 정상' 출력" {
  start_mock_server 18892 200
  run bash scripts/health-check.sh http://localhost:18892
  kill "$MOCK_PID" 2>/dev/null || true
  [[ "$output" == *"✅ 정상"* ]]
}

# ── 테스트 2: 연결 실패 → exit 1 ────────────────────────────────────────────
@test "연결 불가 URL 시 exit 1 반환" {
  # 열려 있지 않은 포트 사용
  run bash scripts/health-check.sh http://localhost:19991
  [ "$status" -eq 1 ]
}

@test "연결 불가 시 '❌ 응답 없음' 출력" {
  run bash scripts/health-check.sh http://localhost:19992
  [[ "$output" == *"❌ 응답 없음"* ]]
}

@test "연결 불가 시 안내 메시지 포함" {
  run bash scripts/health-check.sh http://localhost:19993
  [[ "$output" == *"openclaw gateway start"* ]]
}

# ── 테스트 3: HTTP 4xx/5xx → exit 1 ─────────────────────────────────────────
@test "HTTP 503 응답 시 exit 1 반환" {
  start_mock_server 18893 503
  run bash scripts/health-check.sh http://localhost:18893
  kill "$MOCK_PID" 2>/dev/null || true
  [ "$status" -eq 1 ]
}

@test "HTTP 401 응답 시 exit 1 반환" {
  start_mock_server 18894 401
  run bash scripts/health-check.sh http://localhost:18894
  kill "$MOCK_PID" 2>/dev/null || true
  [ "$status" -eq 1 ]
}

# ── 테스트 4: URL 인자 처리 ─────────────────────────────────────────────────
@test "커스텀 URL 인자가 출력에 표시됨" {
  run bash scripts/health-check.sh http://localhost:19994
  [[ "$output" == *"http://localhost:19994"* ]]
}

@test "인자 없을 때 기본 URL localhost:18789 사용" {
  run bash scripts/health-check.sh
  [[ "$output" == *"localhost:18789"* ]]
}
