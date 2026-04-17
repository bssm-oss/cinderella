Cinderella — 기능 중심 요약

목표
- macOS 상태바 앱으로 사용자가 안전하고 정시에 귀가하도록 유도하는 이벤트 기반 알림기 구현.

핵심 기능 (기능 중심, 수정하기 쉽게)
- 스케줄러: 작업 종료 시간 감지 및 intensity(강도) 증가 로직
- 이벤트 관리: 이벤트 활성화/비활성화, 수명주기 (activate / deactivate)
- 이벤트 모듈(예시): FullscreenWarning, HideWindows, KeySubstitution, PanicHotkey
- 모듈형 액션: SoundModule, CursorModule, InputInterceptor(키 대체), Overlay(강한 시각 데모)
- 사용자 설정: 퇴근시간, 이벤트 토글, baseIntensity 편집
- 개발용 플래그: CINDERELLA_FORCE_START, CINDERELLA_FAST_TICK

아키텍처 (간단)
- EventScheduler: 틱 기반(기본 1분, FAST_TICK=테스트용 1초), intensity 계산, 새 이벤트 브로드캐스트
- EventManager: NotificationCenter 구독, 활성 이벤트 목록, activate -> apply, deactivate 호출
- Events 프로토콜: id, name, baseIntensity, apply(), deactivate() (기본 no-op)
- 모듈: 각 기능별로 분리되어 재사용 및 테스트 용이

런타임/권한
- Accessibility(AX) 권한 필요: CGEventTap, 커서 워프, 창 숨김/보여주기 등
- GUI 앱은 stdout 로그가 빈 경우가 있음. /tmp/cinderella.log에 마커 기록을 권장

개발자 가이드 (짧게)
- 빌드: swift build
- 실행(데모/테스트): env CINDERELLA_FORCE_START=1 CINDERELLA_FAST_TICK=1 .build/debug/Cinderella
- 로그: tail -f /tmp/cinderella.log
- 권한: System Settings → Privacy & Security → Accessibility → Terminal 및 앱 추가

주요 파일 (수정 포인트)
- Sources/Cinderella/AppDelegate.swift — 상태바, Preferences, 데모 오버레이
- Sources/Cinderella/EventScheduler.swift — 틱/스케줄/강도 로직
- Sources/Cinderella/EventManager.swift — 이벤트 수명주기 관리
- Sources/Cinderella/Events.swift — CinderellaEvent 프로토콜
- Sources/Cinderella/InputInterceptor.swift — 키 대체/이벤트 탭
- Sources/Cinderella/*Event.swift — 개별 이벤트 구현(activate/deactivate)

다음 할 일 (권장)
- 상태바 표시 안정화(포그라운드 실행/activationPolicy 검토)
- Accessibility 권한 요청 흐름 문서화 및 권장 entitlements 정리
- Preferences UI 확장: 개별 이벤트의 설명, baseIntensity 편집
- 이벤트 deactivate 보강(특히 HideWindows undo 전략)

수정 팁
- 기능 추가 시 새 이벤트 파일을 만들고 Events 프로토콜을 구현하세요.
- UI 변경은 AppDelegate에서 상태바 메뉴와 Preferences 연결을 확인하세요.

