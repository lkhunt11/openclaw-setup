# 🦞 OpenClaw Windows/WSL2 자동 설치 & CI/CD

OpenClaw를 Windows WSL2 환경에 자동으로 설치하고 GitHub Actions로 관리하는 프로젝트입니다.

## 🚀 빠른 시작

### 1. WSL2 Ubuntu 설치 (Windows PowerShell)
```powershell
wsl --install -d Ubuntu
```

### 2. Ubuntu 터미널에서 자동 설치
```bash
chmod +x scripts/install-openclaw-wsl.sh
./scripts/install-openclaw-wsl.sh
```

### 3. API Key 설정 후 시작
```bash
export ANTHROPIC_API_KEY="sk-ant-..."
source ~/.bashrc
# → http://localhost:18789/ui 접속
```

## 📁 구조

```
.github/workflows/
├── openclaw-preflight.yml   # 환경 사전 검증
├── openclaw-install.yml     # 설치 자동화 (수동 실행)
├── openclaw-gateway.yml     # 30분마다 헬스체크
└── openclaw-release.yml     # 릴리스 배포
scripts/
├── install-openclaw-wsl.sh  # WSL2 전체 설치
└── health-check.sh          # 게이트웨이 상태 확인
```

## ⚙️ GitHub Secrets 설정

| Secret | 설명 |
|--------|------|
| `ANTHROPIC_API_KEY` | Anthropic API 키 |
| `SLACK_WEBHOOK_URL` | Slack 알림 (선택) |
| `VLLM_API_KEY` | vLLM 사용 시 |

## 🔗 참고
- [OpenClaw 공식 문서](https://docs.openclaw.ai)
- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
