# openclaw-chat

OpenClaw(구 ClawdBot) Gateway와 WebSocket으로 연동하는 **Flutter** 클라이언트입니다. 맥미니 등에서 돌아가는 OpenClaw 서버에 붙어 **실시간 채팅**과 **뉴스/소식 UI**를 제공합니다.

---

## 목차

- [사전 요구사항](#사전-요구사항)
- [빠른 시작](#빠른-시작)
- [사용 방법](#사용-방법)
- [튜토리얼: 처음부터 연결까지](#튜토리얼-처음부터-연결까지)
- [연결 상태 안내](#연결-상태-안내)
- [트러블슈팅](#트러블슈팅)
- [프로젝트 구조](#프로젝트-구조)
- [참고](#참고)

---

## 사전 요구사항

| 항목 | 설명 |
|------|------|
| **Flutter SDK** | `^3.8.1` (Dart 3.8+) |
| **OpenClaw Gateway** | 네트워크에서 접근 가능한 호스트에서 실행 중이어야 함 |
| **기본 WebSocket 포트** | `18789` (OpenClaw 기본값, 설정에서 변경 가능) |

모바일/데스크톱 중 원하는 플랫폼용 Flutter 개발 환경이 준비되어 있어야 합니다. ([Flutter 설치 가이드](https://docs.flutter.dev/get-started/install))

---

## 빠른 시작

```bash
cd openclaw-chat
flutter pub get
```

### 실행 예시

```bash
# macOS
flutter run -d macos

# iOS 시뮬레이터 / 기기
flutter run -d ios

# Android 에뮬레이터 / 기기
flutter run -d android

# 사용 가능한 기기 목록
flutter devices
```

앱이 켜지면 **설정** 탭에서 맥미니(또는 Gateway)의 **IP와 포트**를 저장한 뒤 연결합니다. 기본 저장값은 코드상 `192.168.0.x` 플레이스홀더이므로, **반드시 실제 IP로 바꿔야** 연결됩니다.

---

## 사용 방법

### 상단 연결 배너

앱 상단(앱바 아래)에 현재 WebSocket 상태가 표시됩니다.

- **연결 끊김 / 연결 오류**일 때 **재연결**을 눌러 수동으로 다시 시도할 수 있습니다.

### 탭 구성

| 탭 | 설명 |
|----|------|
| **뉴스** | 서버에서 `news` 이벤트로 내려주는 소식을 카드 형태로 표시합니다. 카테고리 필터 UI가 있습니다. *(서버가 해당 이벤트를 보내야 목록이 채워집니다.)* |
| **채팅** | OpenClaw와 `chat.send` 등으로 메시지를 주고받는 화면입니다. **연결됨** 상태에서만 전송이 의미 있습니다. |
| **설정** | 테마(다크 모드), **서버 IP / 포트 / Gateway Token**, 연결·끊기 버튼을 제공합니다. |

### 설정 화면 항목

1. **맥미니 IP 주소**  
   Gateway가 떠 있는 머신의 LAN IP (예: `192.168.0.10`).

2. **포트**  
   OpenClaw WebSocket 포트 (기본 `18789`).

3. **Gateway Token** *(선택)*  
   OpenClaw 설정의 `gateway.auth.token` 값이 있다면 입력합니다. 비어 있으면 토큰 없이 시도합니다.

4. **저장 및 재연결**  
   값을 `SharedPreferences`에 저장하고 WebSocket을 끊었다가 다시 연결합니다.

### 디바이스 페어링

OpenClaw는 처음 연결 시 **디바이스 승인**이 필요할 수 있습니다.

- 앱은 **승인 대기 중** 상태가 되면 주기적으로 재시도합니다.
- OpenClaw 쪽에서 해당 클라이언트를 **승인**하면 이후 **연결됨**으로 바뀌고, 필요 시 자동으로 재연결됩니다.

---

## 튜토리얼: 처음부터 연결까지

아래 순서대로 진행하면 됩니다.

### 1단계: OpenClaw Gateway 준비

- 맥미니(또는 서버)에서 OpenClaw가 실행 중인지 확인합니다.
- 방화벽에서 **WebSocket 포트**(기본 `18789`)가 같은 LAN의 클라이언트에서 열려 있는지 확인합니다.

### 2단계: IP 확인

- 서버에서 `ifconfig`(macOS/Linux) 등으로 **로컬 IP**를 확인합니다.
- **휴대폰에서 테스트**하는 경우, PC/맥미니와 **같은 Wi-Fi**에 붙어 있어야 합니다.

### 3단계: Flutter 앱 실행

```bash
flutter pub get
flutter run -d <기기>
```

### 4단계: 서버 주소 입력

1. 앱 하단 **설정** 탭으로 이동합니다.
2. **맥미니 IP 주소**에 실제 IP를 입력합니다. (예: `192.168.0.10`)
3. **포트**에 `18789`(또는 변경한 포트)를 입력합니다.
4. Gateway에 토큰 인증을 쓰는 경우 **Gateway Token**을 입력합니다.
5. **저장 및 재연결**을 누릅니다.

### 5단계: 페어링(필요한 경우)

1. 상단 배너가 **승인 대기 중**이면 OpenClaw 관리 UI/로그에서 **새 디바이스 승인**을 진행합니다.
2. 승인 후 앱이 자동으로 재연결되며, 배너가 **연결됨**으로 바뀌는지 확인합니다.

### 6단계: 채팅·뉴스 사용

- **채팅** 탭에서 메시지를 보내 Gateway·봇과 대화합니다.
- **뉴스** 탭은 서버가 뉴스/이벤트 스트림을 보낼 때 목록이 갱신됩니다.

---

## 연결 상태 안내

| 상태 | 의미 |
|------|------|
| 연결 중… | TCP/WebSocket 연결 시도 중 |
| 승인 대기 중 | Gateway에서 디바이스 허용이 필요할 수 있음 |
| 연결됨 | 핸드셰이크 완료, 채팅 등 API 사용 가능 |
| 연결 끊김 | 소켓 종료 또는 네트워크 단절 |
| 연결 오류 | 연결 실패 또는 인증/프로토콜 오류 등 |

자동 재연결은 일정 횟수까지 시도합니다. 계속 실패하면 설정의 IP/포트·토큰·서버 실행 여부를 다시 확인하세요.

---

## 트러블슈팅

| 현상 | 확인할 것 |
|------|-----------|
| `[WS] Connection closed` 로그 | 서버가 꺼졌거나, 주소가 잘못됐거나, 서버가 연결 직후 끊는 경우(인증/설정). **설정의 IP가 `192.168.0.x` 그대로면 실제 IP로 변경** |
| 계속 연결 오류 | 같은 Wi-Fi인지, 포트 개방 여부, Gateway Token 필요 여부 |
| macOS 콘솔의 `TSM AdjustCapsLockLED...`, `IMKCFRunLoopWakeUpReliable` | Flutter/macOS에서 흔한 **시스템 로그**로, 앱 동작과 무관한 경우가 많음 |
| 뉴스 탭이 비어 있음 | 서버가 앱이 구독하는 형식의 뉴스/이벤트를 보내는지 확인 (클라이언트는 WebSocket 이벤트 수신 기반) |

---

## 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입, Provider 설정
├── models/                   # NewsItem 등
├── providers/                # ChatProvider, NewsProvider, ThemeProvider
├── screens/                  # Home, News, Chat, Settings
├── services/
│   └── websocket_service.dart  # OpenClaw WebSocket, 페어링, chat.send
└── widgets/                  # 연결 배너, 채팅 버블, 뉴스 카드 등
```

초기 기획·요구사항은 루트의 `GUIDE.MD`를 참고할 수 있습니다.

---

## 참고

- **프로토콜**: WebSocket `connect` 핸드셰이크, Ed25519 서명, `minProtocol` / `maxProtocol` 3 사용 (`websocket_service.dart`).
- **클라이언트 식별**: 플랫폼별 `client.id` (예: `openclaw-macos`, `openclaw-ios`).

문의나 개선은 이 저장소의 이슈/PR로 정리하면 좋습니다.
