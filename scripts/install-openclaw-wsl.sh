#!/bin/bash
# scripts/install-openclaw-wsl.sh
# WSL2 Ubuntu에서 OpenClaw 전체 자동 설치

set -e
echo "🦞 OpenClaw WSL2 자동 설치 시작..."

# ── Node.js 22 (nvm) ──
if ! command -v nvm &>/dev/null; then
    echo "📥 nvm 설치 중..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

nvm install 22 --lts
nvm use 22
echo "✅ Node $(node --version) / npm $(npm --version)"

# ── OpenClaw 설치 ──
npm install -g openclaw
echo "✅ OpenClaw $(openclaw --version)"

# ── 설정 파일 생성 ──
mkdir -p ~/.openclaw
if [ ! -f ~/.openclaw/openclaw.json ]; then
    cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "models": {
    "providers": {
      "anthropic": {
        "baseUrl": "https://api.anthropic.com",
        "apiKey": "${ANTHROPIC_API_KEY}",
        "models": [
          { "id": "claude-sonnet-4-5", "name": "claude-sonnet-4-5", "contextWindow": 200000 },
          { "id": "claude-haiku-3-5",  "name": "claude-haiku-3-5",  "contextWindow": 200000 }
        ]
      }
    }
  },
  "gateway": {
    "port": 18789,
    "bind": "lan",
    "mode": "local"
  }
}
EOF
    echo "✅ ~/.openclaw/openclaw.json 생성 완료"
else
    echo "ℹ️  설정 파일 이미 존재 — 스킵"
fi

# ── 게이트웨이 auth 토큰 설정 ──
openclaw config set gateway.auth.token "openclaw-local-token" 2>/dev/null || true

# ── auth-profiles.json 생성 (ANTHROPIC_API_KEY 연동) ──
mkdir -p ~/.openclaw/agents/main/agent
if [ ! -f ~/.openclaw/agents/main/agent/auth-profiles.json ]; then
    cat > ~/.openclaw/agents/main/agent/auth-profiles.json << EOF
{
  "profiles": {
    "anthropic": {
      "provider": "anthropic",
      "apiKey": "${ANTHROPIC_API_KEY}"
    }
  },
  "default": "anthropic"
}
EOF
    echo "✅ auth-profiles.json 생성 완료"
fi

# ── ~/.bashrc 자동 시작 등록 ──
if ! grep -q "openclaw gateway" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# OpenClaw Gateway 자동 시작" >> ~/.bashrc
    echo "openclaw gateway run &>/dev/null &" >> ~/.bashrc
    echo "✅ ~/.bashrc 자동 시작 등록 완료"
fi

# ── 설정 검증 ──
openclaw config validate && echo "✅ 설정 파일 검증 통과"

echo ""
echo "🎉 OpenClaw 설치 완료!"
echo "   게이트웨이: http://127.0.0.1:18789"
echo "   Web UI:    http://127.0.0.1:18789/?token=openclaw-local-token"
echo ""
echo "📌 다음 단계:"
echo "   export ANTHROPIC_API_KEY='sk-ant-...'"
echo "   source ~/.bashrc"
echo "   → 브라우저에서 http://127.0.0.1:18789/?token=openclaw-local-token 접속"
