# EazyCal

EazyCal은 macOS의 캘린더와 미리 알림을 한 화면에서 관리하는 SwiftUI 일정 관리 앱입니다. 월간 일정, 미리 알림, 일정 체크리스트와 반복적으로 사용하는 일정 템플릿을 함께 관리할 수 있습니다.

## 주요 기능

- 월간 캘린더에서 단일·다일 일정 표시
- 일정 생성, 수정, 단일 항목 삭제
- 드래그 앤 드롭으로 일정 날짜 이동
- 매일·매주·매월·매년 반복 일정 생성
- EventKit 캘린더 생성, 수정, 삭제 및 표시 여부 설정
- 사용자 정의 캘린더 그룹 분류
- 미리 알림 생성, 수정, 완료 처리 및 우선순위 설정
- 날짜가 지정된 미리 알림을 월간 캘린더에 표시하고, 즉시 완료하거나 드래그로 재예약
- 일정 메모를 이용한 체크리스트 관리
- 자주 사용하는 일정을 SwiftData 템플릿으로 저장하고 캘린더에 드롭
- 향후 30일 일정 목록 제공
- 한국어·영어 지역화

## 기술 스택

- Swift 5
- SwiftUI
- EventKit
- SwiftData
- Swift Concurrency (`async`/`await`)
- XCTest
- macOS 14 이상

외부 패키지 의존성은 없습니다.

## 아키텍처

```text
EazyCalApp
├── EventStoreManager
│   ├── CalendarRepository
│   └── ReminderRepository
│       └── EventStore / EventKit
├── CalendarEntry (Event + Reminder presentation model)
├── CalendarViewModel
└── Home
    ├── CalendarTabView
    │   ├── CalendarCategoryView
    │   └── TemplateView
    ├── TodoView
    ├── ScheduleListView
    └── CalendarView
```

`EventStore`는 EventKit 접근과 CRUD를 담당하고, 캘린더와 미리 알림 기능은 각각 `CalendarRepository`, `ReminderRepository` 인터페이스로 분리되어 있습니다. 변경 후 관련 데이터를 다시 조회하는 애플리케이션 흐름은 `CalendarEventUseCase`, `ReminderUseCase`가 담당하며, `EventStoreManager`는 권한과 공유 데이터를 관리합니다. EventKit 모델은 `CalendarEntryMapper`에서 프레임워크 독립적인 값으로 변환되고, 카테고리 필터링·레이어 배치·날짜별 항목 계산은 `MonthCalendarState`가 담당합니다.

### 데이터 저장

| 데이터 | 저장 위치 |
| --- | --- |
| 캘린더, 일정, 미리 알림 | macOS EventKit 저장소 |
| 캘린더 사용자 그룹 | SwiftData |
| 일정 템플릿 | SwiftData |
| 화면에 표시할 캘린더 식별자 | UserDefaults |

앱은 캘린더와 미리 알림 권한을 각각 관리합니다. 캘린더 권한이 없으면 복구 안내 화면을 표시하고, 미리 알림 권한만 없을 때는 캘린더 기능을 계속 사용할 수 있도록 별도의 설정 버튼을 제공합니다.

## 프로젝트 구조

```text
EazyCal/
├── EazyCalApp.swift             # 앱 진입점, 권한 UI, SwiftData 구성
├── Home.swift                   # 메인 화면과 탭 상태
├── Model/                       # SwiftData 모델과 날짜 계산
├── Store/                       # EventKit 추상화 및 상태 관리자
├── View/
│   ├── Calendar/                # 월간 캘린더와 일정 셀
│   ├── PopoverView/             # 일정 생성·수정 화면
│   ├── ScheduleList/            # 향후 일정 목록
│   └── Todo/                    # 미리 알림과 체크리스트
└── Resource/                    # 색상, 아이콘, 지역화 리소스

EazyCalTests/
└── EazyCalTests.swift           # 날짜, 반복 규칙, 저장소 관리자 테스트
```

## 실행 방법

### 요구 사항

- macOS 14 이상
- Xcode 15 이상
- 캘린더 및 미리 알림 접근 권한

### Xcode에서 실행

1. `EazyCal.xcodeproj`를 엽니다.
2. `EazyCal` 스킴과 `My Mac` 실행 대상을 선택합니다.
3. 앱을 실행하고 캘린더 및 미리 알림 접근을 허용합니다.

권한을 거부한 경우 앱의 **Open Settings** 버튼을 통해 시스템 설정으로 이동할 수 있습니다.

### 명령행 빌드

```bash
xcodebuild \
  -project EazyCal.xcodeproj \
  -scheme EazyCal \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  build CODE_SIGNING_ALLOWED=NO
```

## 테스트

테스트 타깃은 다음 동작을 검증합니다.

- 연도를 넘는 월간 조회 범위
- 날짜 이동 시 시간 보존
- 다일 일정의 레이어 충돌 처리
- 서로 다른 연도의 동일 월·일 처리
- 반복 규칙 생성과 무제한 반복
- 미리 알림 우선순위 변환
- 권한 승인 상태의 초기 데이터 로딩
- 데이터 변경 후 명시적 새로고침
- 미리 알림 재예약 시 기존 시간 보존과 관련 데이터 새로고침

다음 명령으로 전체 테스트를 실행할 수 있습니다.

```bash
xcodebuild test \
  -project EazyCal.xcodeproj \
  -scheme EazyCal \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGNING_ALLOWED=NO
```

정적 분석은 다음과 같이 실행합니다.

```bash
xcodebuild analyze \
  -project EazyCal.xcodeproj \
  -scheme EazyCal \
  -configuration Debug \
  -destination 'platform=macOS,arch=arm64' \
  CODE_SIGNING_ALLOWED=NO
```

## 구현 세부 사항

- EventKit 권한 요청은 데이터 조회와 분리되어 앱 시작 시 한 번 처리됩니다.
- `EKEventStoreChanged` 알림은 중복 등록되지 않는 단일 옵저버로 감시합니다.
- EventKit CRUD가 성공하면 관련 화면 데이터를 즉시 다시 불러옵니다.
- 날짜가 지정된 미완료 미리 알림은 현재 월간 캘린더 범위로 조회해 일정과 함께 표시합니다.
- 월간 캘린더의 미리 알림은 완료 버튼과 날짜 셀 드래그 재예약을 지원합니다.
- 최초 실행 시 사용 가능한 모든 캘린더를 기본 표시 대상으로 설정합니다.
- 반복 일정 삭제는 의도하지 않은 이후 일정 삭제를 막기 위해 선택한 일정 하나에만 적용됩니다.
- SwiftData 영구 저장소를 열 수 없으면 앱 종료 대신 메모리 저장소로 대체하고 사용자에게 안내합니다.
- Repository 프로토콜을 통해 캘린더와 미리 알림의 EventKit 의존성을 각각 테스트 대역으로 교체할 수 있습니다.

## 개인정보

EazyCal은 별도의 서버를 사용하지 않습니다. 캘린더와 미리 알림은 macOS의 EventKit 저장소에, 앱 전용 그룹과 템플릿은 로컬 SwiftData 저장소에 보관됩니다.
