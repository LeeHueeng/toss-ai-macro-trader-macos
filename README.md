# Toss AI Macro Trader for macOS

토스증권 Open API와 AI CLI를 연결해 시세 조회, 관심종목 관리, 전략 검토, 가격 알림, 조건 기반 자동매매 보조를 수행하는 macOS 네이티브 SwiftUI 앱입니다.

이 프로젝트의 목표는 사용자가 직접 정한 조건과 안전장치 안에서 자동매매를 보조하고, AI가 전략과 리스크를 더 읽기 쉬운 형태로 설명하도록 돕는 것입니다. 수익을 보장하거나 확정적인 매수·매도 결정을 대신하지 않습니다.

## 핵심 요약

- 플랫폼: macOS 14+
- 앱: SwiftUI 네이티브 앱
- 언어: Swift 6
- 네트워크: URLSession
- 차트: Swift Charts
- 보안: macOS Keychain
- 알림: UserNotifications
- AI 연동: Codex CLI, Claude CLI, Gemini CLI
- 데이터: 토스증권 Open API, 네이버 모바일 공개 거래대금 랭킹, NXT 공개 데이터 fallback, 로컬 JSON 상태 저장

## 주요 기능

### 대시보드

- 현재 선택 종목의 현재가, 캔들 차트, 거래량 차트 표시
- 1분봉, 전체 1분봉, 일봉, 주봉, 월봉 보기
- 차트 확대/축소
- 호가, 보유 상태, 최신 AI 코멘트 표시
- 자동매매 감시 상태 상단 표시
- AI 실행 중 전역 표시줄
- 종목 인사이트 카드
- 관심종목 AI 브리프

### 관심종목

OpenStock의 Watchlist UX를 macOS 앱 방식으로 재구성했습니다.

- 관심종목 추가/삭제
- 관심종목 표에서 현재가, 보유 수량, 알림 개수 확인
- 관심종목에서 바로 대시보드 이동
- 가격 알림 생성
- 가격 알림 활성/비활성 전환
- 가격 알림 삭제
- 자동 감시가 켜져 있으면 1분마다 가격 조건 확인
- 조건 도달 시 macOS 알림과 주문 로그 기록

### 시장 랭킹

- OpenStock의 Market Overview / Stock Heatmap UX를 SwiftUI 네이티브로 재구성
- 시장 개요와 랭킹 탭 전환
- 반도체, 2차전지, 바이오/의료, 인터넷/플랫폼, 자동차 등 섹터별 흐름 표시
- 섹터별 가중 평균 등락률
- 빨강/파랑 히트맵으로 상승/하락 종목 표시
- 섹터별 종목 필터
- 국내/해외/전체 필터
- 거래대금/거래량 정렬
- 네이버 모바일 공개 시세 기반 KOSPI/KOSDAQ 거래대금 랭킹
- NXT 공개 데이터 fallback
- 거래대금 데이터 검산
- 단위 오류가 의심되면 자동 종목 선택 차단

### 전략 관리

초보자도 쓸 수 있도록 자동 선택, 기계적 매매, AI 모드, 직접 입력 모드로 나누었습니다.

- 예산 기반 자동 종목 후보 찾기
- 1주 가격이 예산보다 큰 종목 자동 제외
- 자동 리밸런싱
- 전략 삭제
- 승인 후 주문, 알림 모드, AI 검토 모드, 완전 자동 모드
- 다음 매수/매도 조건 설명
- 왜 아직 사지 않는지 설명
- 분봉 기반 미리보기
- 예상 손익 표시

### 기계적 매매 공식

GitHub의 systematic trading, koquant, OpenStock, ai-berkshire 등 공개 프로젝트의 아이디어를 앱 구조에 맞게 재해석했습니다. 외부 코드를 그대로 복사하지 않고 Swift 로직으로 구현했습니다.

포함된 전략 예시:

- Grid Trading
- Mean Reversion
- Market Making Lite
- Bollinger Band 하단 매수 / 상단 매도
- RSI 과매도 매수 / 과매수 매도
- 고정 간격 분할매수/분할매도
- 거래대금 돌파
- 급등 거래량 추세
- 급락 반등 확인
- KOQUANT 분봉 거래대금 돌파
- 한국 반도체 이슈 특화형 전략

### AI 분석

- Codex CLI, Claude CLI, Gemini CLI 연결 테스트
- 종목별 리포트 생성
- 관심종목 브리프 생성
- 전략 조건 자연어 변환
- 기계적 매매 파라미터 AI 추천
- AI 추천값 미리보기 후 적용
- 출력 정리 및 초보자용 리포트 가독성 개선
- 토큰 사용량, workdir, 모델명, 원문 프롬프트 등 불필요한 CLI 로그 제거

### Berkshire Guard

`xbtlin/ai-berkshire`의 투자 검토 규율을 자동매매 안전 필터로 재구성했습니다.

- 자동 후보별 `통과 / 조건부 / 보류` 판정
- 데이터 신뢰도 A/B/C 사고방식 반영
- 시장 랭킹 검증 실패 시 자동선택 차단
- 완전 자동 모드에서도 Guard 미통과 후보는 승인 후 주문으로 낮춤
- 사용자가 나중에 완전 자동으로 바꿔도 주문 직전 preflight에서 다시 차단

### 계좌와 주문 테스트

- 토스 API 키 키체인 저장
- 계좌 조회
- 보유 종목 조회
- 보유 종목 기반 매수/매도 주문 후보 생성
- 승인 대기 주문 관리
- 실주문 연결 점검
- 실제 주문 전 안전장치 확인

## 안전장치

기본값은 실제 주문이 잠긴 상태입니다.

- 라이브 주문 허용 스위치
- 시장가 주문 추가 확인
- 중복 주문 차단
- 주문 쿨다운
- 하루 매수 한도
- 하루 손실 한도
- 종목 최대 비중
- 레버리지/인버스 경고
- 네트워크/API 오류 시 주문 차단
- API 오류 발생 시 자동매매 중지
- 429 요청 한도 감지 및 쿨다운
- 1주를 살 수 없는 예산 자동 차단
- 자동선택 데이터 품질 검증

## 실제 주문에 대한 주의

이 앱은 실제 주문 API를 호출할 수 있는 구조를 포함합니다. 다만 다음 조건이 모두 맞아야 실주문 제출을 시도합니다.

1. 토스증권 Open API 키가 저장되어 있어야 합니다.
2. 계좌가 선택되어 있어야 합니다.
3. 설정의 `라이브 주문 허용`이 켜져 있어야 합니다.
4. 전략 모드가 `완전 자동`이거나 승인 대기 주문에서 사용자가 `실주문 제출`을 눌러야 합니다.
5. preflight 안전검사를 통과해야 합니다.
6. 주문 수량 또는 금액이 토스 API 규칙에 맞아야 합니다.

기본 동작은 주문 후보 생성, 알림, 로그 저장입니다. 실제 주문을 켜기 전에는 반드시 소액으로 테스트하고, 토스증권 공식 문서와 약관을 확인하세요.

## 빌드 요구사항

- macOS 14 이상
- Xcode Command Line Tools
- Swift 6 toolchain
- 선택 사항: Codex CLI, Claude CLI, Gemini CLI
- 선택 사항: 토스증권 Open API client_id/client_secret

## 설치와 실행

```sh
git clone https://github.com/LeeHueeng/toss-ai-macro-trader-macos.git
cd toss-ai-macro-trader-macos
swift build
swift run TossAIMacroTrader
```

앱 번들로 패키징하려면:

```sh
./scripts/package-app.sh
open ".build/토스 AI 매크로 트레이더.app"
```

## 토스 API 문서 갱신

토스증권 개발자 문서를 다시 수집하고 구조화하려면:

```sh
node scripts/fetch-tossinvest-docs.mjs
```

생성된 문서는 `docs/tossinvest`에 저장됩니다.

## AI CLI 설정

앱의 설정 탭에서 각 CLI 명령어를 수정할 수 있습니다.

예시:

- Codex CLI: `codex exec --skip-git-repo-check --output-last-message`
- Claude CLI: `claude`
- Gemini CLI: `gemini`

CLI가 설치되어 있지 않으면 분석 결과에 명령어 오류가 표시됩니다. 이 오류는 주문과 분리되어 있으며, AI 분석 실패가 곧바로 주문으로 이어지지 않습니다.

## 프로젝트 구조

```text
Sources/TossChart/
  AppShell.swift                 macOS 앱 화면 구성
  AppSession.swift               앱 상태, API 호출, 자동감시, 주문 흐름
  Models.swift                   주요 모델과 설정
  TradingViews.swift             전략 관리, 자동선택, 주문 로그
  AIAnalysisView.swift           AI 분석 화면
  MechanicalSignalEngine.swift   기계적 매매 신호와 백테스트 요약
  TossInvestClient.swift         토스증권 Open API 클라이언트
  NaverMarketRankingClient.swift 네이버 공개 거래대금 랭킹 클라이언트
  NextradeMarketRankingClient.swift NXT fallback 클라이언트
  KeychainStore.swift            API 키 키체인 저장
docs/
  tossinvest/                    토스증권 API 구조화 문서
  strategy-research-github.md    공개 전략 레포 조사 기록
  koquant-adaptation.md          koquant 적용 메모
scripts/
  fetch-tossinvest-docs.mjs      토스 문서 수집 스크립트
  package-app.sh                 macOS 앱 번들 패키징
```

## 참고한 공개 프로젝트와 아이디어

- [Open-Dev-Society/OpenStock](https://github.com/Open-Dev-Society/OpenStock): 관심종목, 가격 알림, 종목 상세, 개인화 브리프 UX 참고
- [xbtlin/ai-berkshire](https://github.com/xbtlin/ai-berkshire): 투자 검토 규율과 데이터 신뢰도 사고방식 참고
- [DAWNCR0W/koquant](https://github.com/DAWNCR0W/koquant): 한국 퀀트/분봉 전략 아이디어 참고
- [paperswithbacktest/awesome-systematic-trading](https://github.com/paperswithbacktest/awesome-systematic-trading): 시스템 트레이딩 자료 조사 참고
- [JungHoonGhae/tossinvest-cli](https://github.com/JungHoonGhae/tossinvest-cli): 토스 CLI 후보 보강 아이디어 참고

각 프로젝트의 코드를 그대로 복사하지 않고 앱 목적에 맞게 SwiftUI와 토스 API 구조로 재구현했습니다.

## 데이터 출처와 한계

- 토스증권 Open API의 실제 제공 범위, 호출 제한, 주문 가능 여부는 공식 문서를 기준으로 합니다.
- 네이버/NXT 공개 데이터는 시장 랭킹 보조용입니다.
- 공개 데이터는 지연되거나 변경될 수 있습니다.
- 해외 전 종목 거래대금 랭킹은 아직 검증되지 않아 자동선택을 차단합니다.
- AI 분석은 참고용이며 최신 뉴스나 재무 데이터를 완전히 보장하지 않습니다.

## 투자 고지

이 앱은 투자 수익을 보장하지 않습니다. 모든 투자 판단과 손실 책임은 사용자에게 있습니다.

AI 분석, 기계적 매매 공식, 자동매매 로직은 판단 보조 도구입니다. 급격한 변동성, 네트워크 장애, API 장애, 주문 지연, 중복 주문, 데이터 오류로 손실이 발생할 수 있습니다.

실제 주문을 켜기 전에는 반드시 다음을 확인하세요.

- 토스증권 공식 API 문서
- 계좌와 주문 가능 금액
- 종목별 거래 가능 시간
- 주문 유형과 수량/금액 규칙
- 세금, 수수료, 환율, 지연 가능성

## 라이선스

아직 별도 라이선스를 지정하지 않았습니다. 공개 저장소이지만, 라이선스가 추가되기 전까지 재사용 권한은 명시적으로 부여되지 않습니다.
