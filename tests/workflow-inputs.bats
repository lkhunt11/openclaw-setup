#!/usr/bin/env bats
# tests/workflow-inputs.bats
# GitHub Actions 워크플로우 입력값 및 환경변수 유효성 검증 테스트

# ── 테스트 1: OPENCLAW_GATEWAY_URL 형식 검증 ────────────────────────────────
validate_gateway_url() {
  local url="$1"
  if [[ ! "$url" =~ ^https?:// ]]; then
    echo "❌ URL 형식 오류: $url"
    return 1
  fi
  echo "✅ URL 형식 정상: $url"
  return 0
}

@test "http:// URL 형식 유효" {
  run validate_gateway_url "http://100.74.201.51:18789"
  [ "$status" -eq 0 ]
  [[ "$output" == *"✅"* ]]
}

@test "https:// URL 형식 유효" {
  run validate_gateway_url "https://example.ngrok-free.dev"
  [ "$status" -eq 0 ]
  [[ "$output" == *"✅"* ]]
}

@test "포트 없는 http URL도 유효" {
  run validate_gateway_url "http://localhost"
  [ "$status" -eq 0 ]
}

@test "빈 URL 무효" {
  run validate_gateway_url ""
  [ "$status" -eq 1 ]
  [[ "$output" == *"❌"* ]]
}

@test "프로토콜 없는 URL 무효" {
  run validate_gateway_url "100.74.201.51:18789"
  [ "$status" -eq 1 ]
}

@test "ftp:// URL 무효 (http/https만 허용)" {
  run validate_gateway_url "ftp://example.com"
  [ "$status" -eq 1 ]
}

# ── 테스트 2: JSON 페이로드 생성 검증 ───────────────────────────────────────
# openclaw-notify.yml / openclaw-e2e.yml 의 python3 페이로드 생성 로직

build_payload() {
  local text="$1"
  local channel="$2"
  python3 -c "
import json, sys
data = {'text': '$text'}
if '$channel':
    data['channel'] = '$channel'
print(json.dumps(data))
"
}

@test "채널 지정 시 JSON에 channel 필드 포함" {
  run build_payload "테스트 메시지" "telegram"
  [ "$status" -eq 0 ]
  [[ "$output" == *'"channel"'* ]]
  [[ "$output" == *'"telegram"'* ]]
}

@test "채널 미지정 시 JSON에 channel 필드 없음" {
  run build_payload "테스트 메시지" ""
  [ "$status" -eq 0 ]
  [[ "$output" != *'"channel"'* ]]
}

@test "생성된 JSON이 유효한 형식" {
  run python3 -c "
import json
data = {'text': 'hello', 'channel': 'telegram'}
output = json.dumps(data)
json.loads(output)  # 파싱 검증
print('valid')
"
  [ "$status" -eq 0 ]
  [[ "$output" == "valid" ]]
}

@test "특수문자 포함 메시지도 JSON 안전하게 인코딩" {
  run python3 -c "
import json
msg = '테스트 \"따옴표\" \$특수문자 & <태그>'
data = {'text': msg}
output = json.dumps(data)
parsed = json.loads(output)
assert parsed['text'] == msg, 'roundtrip 실패'
print('safe')
"
  [ "$status" -eq 0 ]
  [[ "$output" == "safe" ]]
}

# ── 테스트 3: HTTP 응답 코드 분기 검증 ──────────────────────────────────────
check_http_response() {
  local code="$1"
  case "$code" in
    200|201) echo "success"; return 0 ;;
    401)     echo "unauthorized"; return 1 ;;
    000)     echo "no_connection"; return 1 ;;
    *)       echo "error_$code"; return 1 ;;
  esac
}

@test "HTTP 200 → success" {
  run check_http_response "200"
  [ "$status" -eq 0 ]
  [[ "$output" == "success" ]]
}

@test "HTTP 201 → success" {
  run check_http_response "201"
  [ "$status" -eq 0 ]
}

@test "HTTP 000 (연결 실패) → no_connection" {
  run check_http_response "000"
  [ "$status" -eq 1 ]
  [[ "$output" == "no_connection" ]]
}

@test "HTTP 401 → unauthorized" {
  run check_http_response "401"
  [ "$status" -eq 1 ]
  [[ "$output" == "unauthorized" ]]
}

@test "HTTP 500 → error" {
  run check_http_response "500"
  [ "$status" -eq 1 ]
  [[ "$output" == "error_500" ]]
}
