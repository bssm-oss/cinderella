# Cinderella

[English README (README.md)](./README.md)

퇴근 시간이 지나도 일을 계속할 때, 상태바에서 단계적으로 개입해 귀가를 유도하는 macOS 메뉴바 앱입니다.

## 주요 기능
- 메뉴바에서 `Start (출근)` / `Stop (퇴근)` 제어
- 퇴근 시간(`HH:mm`) 기반 동작 시작
- 퇴근시간 이후 상태 문구/색상 표시
- 이벤트 토글
  - `hide_windows`
  - `fullscreen_warning`
  - `key_substitution`
  - `cursor_jitter`
- 긴급 정지 핫키: `Cmd + Opt + Ctrl + Shift + Esc`

## 요구사항
- macOS 12+
- Xcode Command Line Tools (`swift`, `hdiutil`)

## 빠른 시작 (개발 실행)
```bash
swift build
open .build/debug/Cinderella
```

## 앱 번들 빌드 (.app)
```bash
./scripts/make_app.sh
```

생성물:
- `dist/Cinderella.app`

## DMG 빌드 (다운로드/배포용)
```bash
./scripts/make_dmg.sh
```

생성물:
- `dist/Cinderella.dmg`

배포 시에는 `dist/Cinderella.dmg` 파일만 공유하면 됩니다.

## 설치 방법 (최종 사용자)
1. `Cinderella.dmg` 열기
2. `Cinderella.app`을 `Applications`로 드래그
3. `/Applications/Cinderella.app` 실행

## 필수 권한 설정 (한글 macOS 기준)
`시스템 설정` -> `개인정보 보호 및 보안`

1. `손쉬운 사용`
- `Cinderella` 추가 후 켜기

2. `입력 모니터링`
- `Cinderella` 추가 후 켜기

권한 변경 후 앱을 완전히 종료하고 다시 실행하세요.

## 기본 사용법
1. 메뉴바에서 Cinderella 클릭
2. `Preferences...`에서 설정
   - `Work end time (HH:mm)`
   - `After work-end message`
3. `Start (출근)` 클릭
4. 필요 시 `Events`에서 이벤트 on/off
5. 중단은 `Stop (퇴근)` 또는 긴급 핫키

## 상태바 문구 규칙
- 비근무중: `퇴근 HH:mm`
- 근무중 + 퇴근시간 이전: `퇴근 HH:mm (근무중)`
- 근무중 + 퇴근시간 이후: `퇴근 HH:mm (<설정 문구>)` + 빨간색

## 문제 해결
### 메뉴바 아이콘/문구가 안 보일 때
- 메뉴바 자동 숨김을 끄고 다시 확인
- 메뉴바 아이콘이 많은 경우 여유 공간 확보
- 앱 재실행

### 권한을 줬는데 동작이 안 될 때
- 권한 토글 off/on 후 앱 재실행
- 필요 시 Gatekeeper 우회 안내 확인:
  - `docs/GATEKEEPER.md`
  - `scripts/approve_instructions.sh`

## 스크립트
- 앱 번들 생성: `scripts/make_app.sh`
- DMG 생성: `scripts/make_dmg.sh`
- 권한 안내: `scripts/check_permissions.sh`

## 주의
이 프로젝트는 데모/학습 목적입니다. 실제 배포/운영 전에는 사용자 동의, 보안, 법적 검토를 진행하세요.
