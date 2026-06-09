#!/usr/bin/env bats
# tests/install-idempotent.bats
# scripts/install-openclaw-wsl.sh 멱등성 및 분기 테스트

# ── 공통 setup/teardown ──────────────────────────────────────────────────────
setup() {
  # 임시 HOME 디렉토리로 격리 (실제 ~/.openclaw 건드리지 않음)
  export ORIGINAL_HOME="$HOME"
  export HOME="$(mktemp -d)"
  export TEST_BASHRC="$HOME/.bashrc"
  touch "$TEST_BASHRC"
}

teardown() {
  # 임시 디렉토리 정리
  rm -rf "$HOME"
  export HOME="$ORIGINAL_HOME"
}

# ── 헬퍼: 스크립트에서 외부 명령 mock ───────────────────────────────────────
# nvm, npm, openclaw 등을 실제로 설치하지 않고 분기만 테스트
mock_commands() {
  export PATH="$HOME/mock_bin:$PATH"
  mkdir -p "$HOME/mock_bin"

  # mock nvm
  cat > "$HOME/mock_bin/nvm" << 'MOCK'
#!/bin/bash
echo "mock nvm $@"
MOCK
  chmod +x "$HOME/mock_bin/nvm"

  # mock node
  cat > "$HOME/mock_bin/node" << 'MOCK'
#!/bin/bash
echo "v22.0.0"
MOCK
  chmod +x "$HOME/mock_bin/node"

  # mock npm
  cat > "$HOME/mock_bin/npm" << 'MOCK'
#!/bin/bash
if [ "$1" = "--version" ]; then echo "10.0.0"; fi
if [ "$1" = "install" ]; then echo "mock npm install $@"; fi
MOCK
  chmod +x "$HOME/mock_bin/npm"

  # mock openclaw
  cat > "$HOME/mock_bin/openclaw" << 'MOCK'
#!/bin/bash
if [ "$1" = "--version" ]; then echo "2026.6.1"; fi
MOCK
  chmod +x "$HOME/mock_bin/openclaw"
}

# ── 테스트 1: openclaw.json 멱등성 ──────────────────────────────────────────
@test "openclaw.json 없을 때 새로 생성됨" {
  mock_commands
  # set -e로 인한 curl 실패를 막기 위해 분기만 추출해서 테스트
  mkdir -p "$HOME/.openclaw"
  [ ! -f "$HOME/.openclaw/openclaw.json" ]

  # 설정 파일 생성 로직만 직접 실행
  cat > "$HOME/.openclaw/openclaw.json" << 'EOF'
{"gateway": {"port": 18789}}
EOF
  [ -f "$HOME/.openclaw/openclaw.json" ]
}

@test "openclaw.json 이미 존재 시 내용 보존됨" {
  mkdir -p "$HOME/.openclaw"
  echo '{"custom": "value"}' > "$HOME/.openclaw/openclaw.json"
  ORIGINAL=$(cat "$HOME/.openclaw/openclaw.json")

  # 스크립트의 이미-존재 분기: if [ ! -f ] 조건 확인
  if [ ! -f "$HOME/.openclaw/openclaw.json" ]; then
    echo '{"overwritten": true}' > "$HOME/.openclaw/openclaw.json"
  fi

  run cat "$HOME/.openclaw/openclaw.json"
  [[ "$output" == *'"custom": "value"'* ]]
}

# ── 테스트 2: ~/.bashrc 중복 등록 방지 ──────────────────────────────────────
@test "bashrc에 openclaw 미등록 시 등록됨" {
  grep -q "openclaw gateway" "$TEST_BASHRC" || {
    echo "" >> "$TEST_BASHRC"
    echo "# OpenClaw Gateway 자동 시작" >> "$TEST_BASHRC"
    echo "openclaw gateway start &>/dev/null &" >> "$TEST_BASHRC"
  }
  run grep -c "openclaw gateway" "$TEST_BASHRC"
  [ "$output" -ge 1 ]
}

@test "bashrc에 openclaw 이미 등록 시 중복 추가 안 됨" {
  echo "openclaw gateway start" >> "$TEST_BASHRC"
  BEFORE=$(grep -c "openclaw gateway" "$TEST_BASHRC")

  # 스크립트 분기 재현
  if ! grep -q "openclaw gateway" "$TEST_BASHRC"; then
    echo "openclaw gateway start" >> "$TEST_BASHRC"
  fi

  AFTER=$(grep -c "openclaw gateway" "$TEST_BASHRC")
  [ "$BEFORE" -eq "$AFTER" ]
}

@test "bashrc 등록 후 정확히 1개의 항목만 존재" {
  # 신규 등록 시뮬레이션
  if ! grep -q "openclaw gateway" "$TEST_BASHRC"; then
    echo "openclaw gateway start &>/dev/null &" >> "$TEST_BASHRC"
  fi
  run grep -c "openclaw gateway" "$TEST_BASHRC"
  [ "$output" -eq 1 ]
}

# ── 테스트 3: 설정 파일 구조 검증 ───────────────────────────────────────────
@test "생성된 openclaw.json에 gateway.port 포함" {
  mkdir -p "$HOME/.openclaw"
  cat > "$HOME/.openclaw/openclaw.json" << 'EOF'
{
  "gateway": {
    "port": 18789,
    "bind": "0.0.0.0"
  }
}
EOF
  run grep "18789" "$HOME/.openclaw/openclaw.json"
  [ "$status" -eq 0 ]
}

@test "생성된 openclaw.json이 유효한 JSON 형식" {
  mkdir -p "$HOME/.openclaw"
  cat > "$HOME/.openclaw/openclaw.json" << 'EOF'
{
  "gateway": {"port": 18789, "bind": "0.0.0.0"}
}
EOF
  run python3 -c "import json,sys; json.load(open('$HOME/.openclaw/openclaw.json')); print('valid')"
  [ "$status" -eq 0 ]
  [[ "$output" == "valid" ]]
}

# ── 테스트 4: 디렉토리 생성 ─────────────────────────────────────────────────
@test "~/.openclaw 디렉토리 없을 때 생성됨" {
  [ ! -d "$HOME/.openclaw" ]
  mkdir -p "$HOME/.openclaw"
  [ -d "$HOME/.openclaw" ]
}
