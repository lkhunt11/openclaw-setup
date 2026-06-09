# OpenClaw 채널 알림 설정 가이드

CI/CD 결과를 Telegram/Slack/Discord 등으로 받으려면 아래 설정이 필요합니다.

## 필요한 GitHub 설정

### Secrets (민감 정보)
| 이름 | 설명 | 예시 |
|------|------|------|
| `OPENCLAW_GATEWAY_TOKEN` | OpenClaw 게이트웨이 auth 토큰 | `openclaw-local-token` |
| `SLACK_WEBHOOK_URL` | Slack Incoming Webhook (선택) | `https://hooks.slack.com/...` |

### Variables (공개 설정값)
| 이름 | 설명 | 예시 |
|------|------|------|
| `OPENCLAW_GATEWAY_URL` | 게이트웨이 외부 접근 URL | `http://YOUR_IP:18789` |
| `OPENCLAW_CHANNEL_TARGET` | 기본 알림 대상 채널 ID | `telegram:123456789` |

## GitHub 설정 방법

```
레포 → Settings → Secrets and variables → Actions
→ New repository secret  (민감 정보)
→ Variables 탭 → New repository variable  (공개 설정값)
```

---

## 채널별 연동 방법

### Telegram (추천)

**1. Bot 생성**
1. Telegram → `@BotFather` 검색
2. `/newbot` 입력 → 봇 이름/username 설정
3. 토큰 발급: `7123456789:AAE-xxxxxx`

**2. OpenClaw 연동**
```bash
# WSL Ubuntu에서
openclaw channels add telegram --token 7123456789:AAE-xxxxxx
```

**3. 채팅 ID 확인**
```bash
# 봇에게 /start 전송 후
openclaw channels resolve telegram --username @your_username
# 또는
curl https://api.telegram.org/bot<TOKEN>/getUpdates
```

**4. GitHub Variables 설정**
```
OPENCLAW_GATEWAY_URL = http://YOUR_WSL_IP:18789
OPENCLAW_CHANNEL_TARGET = telegram:123456789
```

---

### Slack

**1. Slack App 생성**
1. https://api.slack.com/apps → Create New App → From Scratch
2. OAuth & Permissions → Bot Token Scopes 추가:
   - `chat:write`, `im:history`, `im:read`, `im:write`
3. Install to Workspace → Bot User OAuth Token 복사 (`xoxb-...`)
4. Socket Mode 활성화 → App-Level Token 생성 (`xapp-...`)

**2. OpenClaw 연동**
```bash
openclaw channels add slack \
  --bot-token xoxb-... \
  --app-token xapp-...
```

**3. GitHub Variables 설정**
```
OPENCLAW_CHANNEL_TARGET = slack:@your_username
# 또는 채널명
OPENCLAW_CHANNEL_TARGET = slack:#ci-alerts
```

---

### Discord

**1. Bot 생성**
1. https://discord.com/developers/applications → New Application
2. Bot 탭 → Token 복사 → Reset Token
3. OAuth2 → URL Generator → Bot 선택
   - 권한: `Send Messages`, `Read Message History`
4. 생성된 URL로 서버에 Bot 초대

**2. OpenClaw 연동**
```bash
openclaw channels add discord --token MTxxxxxx...
```

**3. GitHub Variables 설정**
```
OPENCLAW_CHANNEL_TARGET = discord:CHANNEL_ID
```

---

## 외부 접근 URL 설정 (OPENCLAW_GATEWAY_URL)

GitHub Actions는 외부 네트워크이므로 WSL 로컬 주소(`127.0.0.1`)에 접근 불가.
아래 중 하나를 사용하세요:

### 옵션 1: ngrok (간단, 무료)
```bash
# WSL에서
npm install -g ngrok
ngrok http 18789
# → https://xxxx.ngrok-free.app 를 OPENCLAW_GATEWAY_URL로 설정
```

### 옵션 2: Tailscale (안정적, 무료)
```bash
# WSL에서
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
# → Tailscale IP를 OPENCLAW_GATEWAY_URL로 설정
```

### 옵션 3: 공유기 포트포워딩
```
공유기 관리 → NAT/포트포워딩 → 18789 포트 → WSL IP로 포워딩
→ 공인 IP:18789 를 OPENCLAW_GATEWAY_URL로 설정
```
