Mac Mini에서 실행 중인 OpenClaw(구 ClawdBot) Gateway와 연동되는 Flutter 앱의 핵심 기능을 개발해줘.

### 프로젝트 개요

- 프레임워크: Flutter (Clean Architecture 지향)
- 주요 기능: 맥미니 서버(OpenClaw)와 WebSocket 연결, 실시간 메시지 수신(뉴스/소식), 챗 UI 구현
- 통신 대상: ws://[MAC_MINI_IP]:18789 (OpenClaw 기본 포트)

### 상세 요청 사항

1. **WebSocket 클라이언트 구현**:
   - `web_socket_channel` 패키지를 사용하여 OpenClaw Gateway와 연결하는 Service 클래스를 작성해줘.
   - OpenClaw의 Node 등록 절차(Pairing Request)를 위한 초기 핸드셰이크 로직을 포함해줘.
2. **상태 관리**:
   - 연결 상태(연결됨, 끊김, 승인 대기 중)를 관리할 수 있도록 'Provider' 또는 'Bloc'을 사용해줘.
3. **채팅 UI (StreamBuilder)**:

   - 서버에서 실시간으로 들어오는 소식(JSON 데이터)을 리스트 형태로 보여주는 UI를 만들어줘.
   - 봇이 보내는 실시간 뉴스 브리핑은 별도의 카드(Card) 스타일로 강조해줘.

4. **설정 화면**:
   - 맥미니의 로컬 IP 주소를 입력하고 저장할 수 있는 간단한 설정 페이지를 포함해줘.

### 기술적 제약

- OpenClaw는 연결 시 디바이스 승인이 필요하므로, 처음 연결 시 "승인 대기 중" 상태를 화면에 명시해줘.
- 메시지 포맷은 OpenClaw의 표준 JSON 스펙을 따르도록 인터페이스를 정의해줘.

이 내용을 바탕으로 `lib/` 폴더 구조와 핵심 Dart 코드를 생성해줘.
