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
          { "id": "claude-sonnet-4-5", "contextWindow": 200000 },
          { "id": "claude-haiku-3-5",  "contextWindow": 200000 }
        ]
      }
    },
    "primaryModel": "anthropic/claude-sonnet-4-5"
  },
  "gateway": {
    "port": 18789,
    "bind": "0.0.0.0"
  }
}
EOF
    echo "✅ ~/.openclaw/openclaw.json 생성 완료"
else
    echo "ℹ️  설정 파일 이미 존재 — 스킵"
fi

# ── ~/.bashrc 자동 시작 등록 ──
if ! grep -q "openclaw gateway" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# OpenClaw Gateway 자동 시작" >> ~/.bashrc
    echo "export GATEWAY_BIND=0.0.0.0" >> ~/.bashrc
    echo "openclaw gateway start &>/dev/null &" >> ~/.bashrc
    echo "✅ ~/.bashrc 자동 시작 등록 완료"
fi

echo ""
echo "🎉 OpenClaw 설치 완료!"
echo "   게이트웨이: http://localhost:18789"
echo "   Web UI:    http://localhost:18789/ui"
echo ""
echo "📌 다음 단계:"
echo "   export ANTHROPIC_API_KEY='sk-ant-...'"
echo "   source ~/.bashrc"
