# TODO — Cinderella (작업 항목)

작은 단위로 커밋하세요. 각 항목 완료 시 커밋하고 메시지를 적어 주세요.

1. statusbar-ui - 상태바 아이템 및 팝오버(시간 선택, Start/Stop, 전체 토글)
2. settings-storage - UserDefaults 기반 설정 저장 및 로드 (WORK_END_TIME 등)
3. scheduler-core - EventScheduler: 1분 타이머, elapsedMinutes, intensity 로직
4. events-model - 이벤트 인터페이스 및 이벤트 팩토리(이벤트 풀)
5. sound-module-stub - SoundModule 기본 (효과음 재생 API)
6. cursor-module-stub - CursorModule 기본 (커서 이동/아이콘 조작 API)
7. input-interceptor-stub - 입력 교란 스텁(테스트용 안전 구현)
8. panic-hotkey - 즉시 종료 핫키 구현 및 문서화
9. ui-tests - 기본 UI 동작(팝오버 열기/시간 변경/Start/Stop) 자동화 테스트
10. docs - README, PRD, 프로젝트 문서 정리
11. packaging - macOS 앱 번들화 초기 설정

각 항목은 작게 쪼개 커밋하세요(예: "feat: add statusbar icon and popover").