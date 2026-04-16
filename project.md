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

## 이벤트 모델 (권장)
- 이벤트 인터페이스: { id, name, baseIntensity, apply(intensity) }
- 이벤트 풀: 시간·강도에 따라 활성화되는 이벤트 목록과 대기 풀 유지
- 예시 이벤트: 사운드(타자기), 커서 지터, 커서 반전, 입력 교란, 창 최소화, 전체화면 경고

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
