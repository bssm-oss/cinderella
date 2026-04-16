# 👠 Cinderella — 기능 중심 요약 (툴바 · 스케줄링 상세)

## 목적
사용자가 설정한 퇴근 시간 이후에 유머러스하고 점진적으로 귀가를 권장하는 macOS 앱(테스트/데모용). 모든 효과는 사용자가 설정에서 개별 토글 가능해야 합니다.

## 핵심 UX: 상태바(툴바)
- 상태바(NSStatusItem)에 현재 '퇴근 시간'을 항상 표시 (예: "퇴근 18:00").
- 상태바 팝오버에 컨트롤: 시간 선택(UI), [출근(Start)] 버튼, [퇴근(Stop)] 버튼, 전체 비활성화 토글.
- 동작:
  - 사용자가 '퇴근 시간' 텍스트를 클릭하면 시간 선택 팝오버가 열려 WORK_END_TIME을 변경할 수 있음.
  - ‘출근(Start)’ 눌러 IS_ACTIVE=true: 앱이 모니터링을 시작.
  - ‘퇴근(Stop)’ 눌러 IS_ACTIVE=false: 모든 효과 중지, 강도와 타이머 리셋.

## 동작·스케줄링 규칙
- 시작 조건: IS_ACTIVE == true && 현재 시각 >= WORK_END_TIME
- 타이머: 1분 간격으로 tick
  - 10분 단위(INTENSITY_TICK_MIN = 10): 매 10분마다 이벤트 강도(intensity) 증가
  - 새 이벤트 추가: NEW_EVENT_INTERVAL_MIN (권장 30 또는 60)마다 새로운 이벤트 등록
- 기본 흐름 예시:
  - 0분: Phase 1 기본 효과 활성 (intensity 1)
  - 10분: intensity 2 (효과 빈도/세기 증가)
  - 20분: intensity 3
  - 30분: 새 이벤트 추가(예: 경고창 또는 창 최소화)
  - 40분: intensity 4
  - 60분: 또 다른 이벤트 추가

## 변수(파일 상단 또는 설정에 노출)
- WORK_END_TIME: "18:00" (문자열)
- ENABLED: true/false (앱 전체 활성화)
- IS_ACTIVE: true/false (사용자가 Start/Stop으로 제어)
- INTENSITY_TICK_MIN: 10 (강도 증가 주기, 분)
- EVENT_INTENSITY_STEP: 1 (강도 증가 단위)
- NEW_EVENT_INTERVAL_MIN: 30 (새 이벤트 생성 간격, 분)

수정 팁: 이 변수들만 바꾸면 동작을 쉽게 조정할 수 있게 문서 최상단에 배치하세요.

## 이벤트 모델 및 목록
- 이벤트 인터페이스: { id, name, baseIntensity, apply(intensity) }
- 이벤트 풀: 시간·강도에 따라 활성화되는 이벤트 목록과 대기 풀 유지
- 이벤트 설계 원칙: 안전(사용자 토글/핫키), 점진성(intensity 기반), 모듈화(apply 함수)

주요 이벤트 (id · 설명 · 주요 변수 예시)
- gentle_sound · 은은한 알림음 (probability:0.1, volume:0.3, baseIntensity:1)
- typing_glass · 유리구두 타이핑(키 입력 확률성) (probability:0.1, volume:0.3)
- cursor_jitter · 커서 미세 떨림 (interval:60s, distance:1-2px, baseIntensity:1)
- pumpkin_cursor · 커서 아이콘 일시 변경 (duration:0.5s)
- vintage_typewriter · 전역 타자기 타격음 (volume:0.5)
- enter_bell · Enter 키 벨소리 (volume:0.5)
- drunken_mouse · 마우스 튕김 (interval:10s, distance:20px)
- cursor_inversion · 커서 이동 반전 (duration:5s)
- key_substitution · 특정 키 교란 (keys:["i","o","u"], substitute:adjacentKey)
- force_volume_100 · 효과음 강제 100% (duration: until reset)
- hide_windows · 활성 창 최소화
- fullscreen_warning · 전체화면 경고창 "집에 가세요!" (dismissable:true)
- ambient_typing_noise · 무작위 타자기 소음(비활성화 가능)

각 이벤트는 baseIntensity와 현재 intensity를 받아 강도에 맞게 동작하도록 구현하세요. 모듈화하여 SoundModule, CursorModule, InputInterceptor 등에서 호출하도록 설계합니다.

## 권한·개인정보
- 필수 권한: Accessibility(키/마우스 제어), 오디오 출력
- 안면 인식 사용 시: 명확한 옵트인, 로컬 처리, 저장 금지

## 저장 방식
- 간단: UserDefaults에 WORK_END_TIME, ENABLED, NEW_EVENT_INTERVAL_MIN, IS_ACTIVE 저장
- 고급: 앱 컨테이너의 설정 JSON 파일로 노출(수동 편집 가능)

## 빠른 적용 포인트
- 최상단: 변수 블록(WORK_END_TIME 등) — 사용자 수정 용이
- 툴바 설명: 사용자가 어디서 시간 설정·Start·Stop을 하는지 명확히 기재
- 타이머 로직: INTENSITY_TICK_MIN과 NEW_EVENT_INTERVAL_MIN 설명을 예시와 함께 제공

---

원하시면 이 문구를 영어 버전으로도 추가하거나, 변수 이름을 코드·설정 파일과 정확히 맞춰 드리겠습니다.
