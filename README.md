# 🦞 OpenClaw Windows/WSL2 — CI/CD 자동화 파이프라인

OpenClaw AI 게이트웨이를 Windows WSL2에 자동 설치하고,
GitHub Actions 6개 워크플로우로 운영·모니터링·알림을 완전 자동화하는 프로젝트입니다.

---

## ✅ 현재 상태

| 구성 요소 | 상태 |
|---|---|
| 🔍 환경 검증 (preflight) | ✅ push/PR 자동 실행 |
| 📦 설치 자동화 (install) | ✅ 수동/주간 |
| 💓 게이트웨이 헬스체크 | ✅ 30분 주기 |
| 🚀 릴리스 배포 | ✅ staging → production |
| 📣 CI 결과 알림 (notify) | ✅ 채널 연동 시 활성 |
| 🧪 E2E 채널 테스트 | ✅ 매일 09:00 KST |
| 🧬 단위 테스트 (bats) | ✅ 28개 자동화 |

---

## 🏗️ 아키텍처

```
WSL2 Ubuntu
└── openclaw-gateway (systemd, 자동시작)
    ├── 로컬:  http://127.0.0.1:18789
    └── 외부:  http://<TAILSCALE_IP>:18789  (Tailscale VPN)

GitHub Actions
├── openclaw-preflight   push/PR 시 자동 — shellcheck + bats 28개 테스트
├── openclaw-install     수동/주간 — Node.js 22 + OpenClaw 설치
├── openclaw-gateway     30분 주기 — smoke-test 헬스체크
├── openclaw-release     태그 푸시 — staging → production 배포
├── openclaw-notify      CI 완료 시 — 채널 알림 전송
└── openclaw-e2e         매일 09:00 KST + 수동 — 4단계 E2E 검증

Composite Actions
├── .github/actions/setup-openclaw/       Node 22 + OpenClaw 설치
└── .github/actions/gateway-healthcheck/  retry 기반 헬스체크
```

---

## 🚀 빠른 시작

### 1. WSL2 Ubuntu 설치

```powershell
# Windows PowerShell (관리자)
wsl --install -d Ubuntu
```

### 2. OpenClaw 자동 설치

```bash
# WSL2 Ubuntu 터미널
chmod +x scripts/install-openclaw-wsl.sh
./scripts/install-openclaw-wsl.sh
```

### 3. API Key 설정

```bash
echo 'export ANTHROPIC_API_KEY="sk-ant-..."' >> ~/.bashrc
source ~/.bashrc
```

### 4. 게이트웨이 시작

```bash
# systemd 서비스 등록 (재부팅 후 자동시작)
systemctl --user enable openclaw-gateway
systemctl --user start openclaw-gateway

# 상태 확인
systemctl --user status openclaw-gateway
```

### 5. Web UI 접속

```
http://127.0.0.1:18789/?token=openclaw-local-token
```

---

## ⚙️ GitHub 설정

### Variables (Settings → Variables → Actions)

| 변수 | 값 | 설명 |
|------|-----|------|
| `OPENCLAW_GATEWAY_URL` | `http://<IP>:18789` | 외부 게이트웨이 URL |
| `OPENCLAW_CHANNEL_TARGET` | `default` | 알림 대상 채널 |

### Secrets (Settings → Secrets → Actions)

| Secret | 설명 |
|--------|------|
| `OPENCLAW_GATEWAY_TOKEN` | 게이트웨이 인증 토큰 |

### Environments

`staging`, `production` 환경을 **Settings → Environments** 에서 생성 필요.

---

## 📣 채널 연동

```bash
# Telegram (권장 — @BotFather → /newbot 으로 즉시 발급)
npx openclaw channels add --channel telegram --token <BOT_TOKEN>

# Slack
npx openclaw channels add --channel slack --bot-token xoxb-... --app-token xapp-...

# Discord
npx openclaw channels add --channel discord --token <BOT_TOKEN>

# 연동 확인
npx openclaw channels list
```

---

## 🧪 테스트

```bash
# 전체 bats 테스트 실행 (로컬)
bats tests/

# 개별 파일 실행
bats tests/health-check.bats
bats tests/install-idempotent.bats
bats tests/workflow-inputs.bats
```

| 파일 | 테스트 수 | 커버 영역 |
|------|----------|---------|
| `tests/health-check.bats` | 8개 | HTTP 응답 분기 (200/4xx/5xx/000) |
| `tests/install-idempotent.bats` | 8개 | 설치 스크립트 멱등성 |
| `tests/workflow-inputs.bats` | 12개 | URL/JSON/HTTP 코드 유효성 |

> CI에서 `openclaw-preflight` 실행 시 자동으로 bats 테스트가 포함됩니다.

---

## 📁 디렉토리 구조

```
.
├── .github/
│   ├── actions/
│   │   ├── setup-openclaw/        # Node 22 + OpenClaw 설치 액션
│   │   └── gateway-healthcheck/   # retry 기반 헬스체크 액션
│   └── workflows/
│       ├── openclaw-preflight.yml # 환경 검증 + bats 테스트
│       ├── openclaw-install.yml   # 설치 자동화
│       ├── openclaw-gateway.yml   # 30분 헬스체크
│       ├── openclaw-release.yml   # 릴리스 배포
│       ├── openclaw-notify.yml    # CI 채널 알림
│       └── openclaw-e2e.yml       # E2E 4단계 테스트
├── scripts/
│   ├── install-openclaw-wsl.sh    # WSL2 전체 자동 설치
│   └── health-check.sh            # 게이트웨이 상태 확인
├── tests/
│   ├── health-check.bats          # 단위 테스트 8개
│   ├── install-idempotent.bats    # 단위 테스트 8개
│   └── workflow-inputs.bats       # 단위 테스트 12개
└── docs/
    └── session-*.md               # 세션 작업 기록
```

---

## 🔧 트러블슈팅

| 문제 | 해결 |
|------|------|
| 게이트웨이 미응답 | `systemctl --user restart openclaw-gateway` |
| Tailscale 연결 끊김 | `sudo tailscale up` (WSL2 root) |
| CI `cache:npm` 오류 | `setup-node`에서 `cache: 'npm'` 제거 필수 |
| 워크플로우 파싱 실패 | `if:` 조건에 `secrets.*` 직접 참조 금지 |
| GitHub runner → Tailscale IP 불가 | 설계상 정상 — VPN 경고 처리로 우회됨 |
| bats 설치 | `sudo apt-get install -y bats` |

---

## 🔗 참고

- [OpenClaw 공식 문서](https://docs.openclaw.ai)
- [Tailscale WSL2 가이드](https://tailscale.com/kb/1296/wsl2)
- [bats-core 테스트 프레임워크](https://github.com/bats-core/bats-core)
- [GitHub Actions 환경 문서](https://docs.github.com/en/actions/using-github-hosted-runners)
