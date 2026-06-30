# GitHub 기계적 매매 전략 분석

작성일: 2026-06-18

## 조사 대상

별 수와 전략 관련성을 기준으로 아래 저장소를 우선 확인했다.

| 저장소 | 별 수(확인 시점) | 핵심 참고 포인트 |
| --- | ---: | --- |
| https://github.com/freqtrade/freqtrade | 51.6k | 백테스트, 드라이런, 전략 최적화, 지표 기반 전략 구조 |
| https://github.com/mementum/backtrader | 22.0k | 범용 백테스트 프레임워크 관점 |
| https://github.com/hummingbot/hummingbot | 18.9k | 고빈도 봇, CLOB/AMM, 마켓메이킹/전략 실행 구조 |
| https://github.com/kernc/backtesting.py | 8.5k | 간결한 전략 검증 구조 |
| https://github.com/jesse-ai/jesse | 8.1k | 전략형 암호화폐 봇/백테스트 구조 |
| https://github.com/drakkar-software/OctoBot | 6.1k | Grid, DCA, TradingView, 백테스트 자동화 |
| https://github.com/chrisleekr/binance-trading-bot | 5.5k | Buy low/sell high 방식의 Grid Trading |
| https://github.com/ctubio/Krypto-trading-bot | 3.7k | 저지연 마켓메이킹, 웹 UI 기반 호가 파라미터 |
| https://github.com/Open-Trader/opentrader | 2.7k | GRID/DCA/RSI 전략, highPrice/lowPrice/gridLevels 구조 |
| https://github.com/enarjord/passivbot | 2.0k | contrarian market maker, 가격 밴드, 그리드 재진입, 리스크 제어 |

## 핵심 결론

Grid Trading, Mean Reversion, Market Making은 서로 다르지만 공통적으로 “예측”보다 “가격 구간과 반복 실행”을 중시한다. 초보자용 앱에서는 복잡한 최적화보다 다음 네 가지를 먼저 고정해야 한다.

1. 신호가 너무 자주 나올 때 주문을 막는 쿨다운
2. 한 번에 큰 금액이 들어가지 않도록 금액 분할
3. 상단 매도와 하단 매수를 분리한 양방향 조건
4. 실주문 전 알림/승인 모드를 기본값으로 유지

## 1. Grid Trading

GitHub에서 반복적으로 보인 구조는 “상단 가격, 하단 가격, 그리드 개수, 각 그리드당 수량”이다. OpenTrader는 grid 전략 예시에서 `highPrice`, `lowPrice`, `gridLevels`, `quantityPerGrid`를 둔다. OctoBot은 정해진 간격에 여러 매수/매도 주문을 유지하고 양쪽 체결이 이어질 때 수익을 얻는 식으로 설명한다.

앱 적용 방식:

- 기준가(anchor)를 중심으로 일정 퍼센트 간격(gap)을 만든다.
- 기준가보다 아래쪽에서 가격이 한 칸 더 내려가면 매수 후보.
- 기준가보다 위쪽에서 가격이 한 칸 더 올라가면 매도 후보.
- 기준가 아래에서 위로 되돌아오는 움직임은 “신규 매도”로 보지 않고, 기준가 위에서만 매도 그리드를 계산한다.
- 같은 방향 반복 체결은 전략의 쿨다운으로 제한한다.

장점:

- 횡보장과 2~3% 박스권에서 이해하기 쉽다.
- 초보자에게 “정해진 간격마다 조금씩 사고판다”는 설명이 직관적이다.

위험:

- 추세 하락장에서는 계속 물타기가 될 수 있다.
- 상단 매도 없이 매수만 켜두면 포지션이 누적된다.
- 토스 API 호출 제한 때문에 촘촘한 고빈도 그리드보다는 1분 감시 기반 간이 그리드가 적절하다.

## 2. Mean Reversion

평균회귀는 가격이 평균에서 과하게 멀어졌을 때 다시 평균 쪽으로 돌아온다는 가정이다. Bollinger Bands와 RSI가 가장 흔한 조합이다.

앱 적용 방식:

- Bollinger 하단 터치: 매수 후보
- Bollinger 상단 터치: 매도 후보
- RSI 과매도 진입: 매수 후보
- RSI 과매수 진입: 매도 후보
- Bollinger 하단 + RSI 과매도 동시 만족: 더 보수적인 평균회귀 매수 후보
- 조합 전략의 매도는 설명과 맞게 Bollinger 중간선이 아니라 상단 밴드 또는 RSI 과매수에서만 만든다.

장점:

- 횡보장, 과매도 반등 구간에서 초보자가 이해하기 쉽다.
- 단독 가격 하락률보다 지표 기반이라 조건이 명확하다.

위험:

- 강한 추세장에서는 “싸 보이는 가격”이 계속 더 싸질 수 있다.
- RSI와 Bollinger는 후행 지표라 급변 구간에서는 반응이 늦다.
- 그래서 앱에서는 손절/익절/최대 보유 봉수를 함께 백테스트에 반영했다.

## 3. Market Making

Hummingbot, Krypto-trading-bot, Passivbot 계열에서 공통적으로 보이는 개념은 기준 가격 주변에 매수/매도 호가를 동시에 두고 스프레드와 재고 위험을 관리하는 것이다. 다만 이 앱은 개인용 주식 매크로이고 토스 API는 고빈도 양방향 호가 취소/재제출용으로 쓰기에는 호출 제한과 체결 지연 위험이 있다.

앱 적용 방식:

- 진짜 HFT 마켓메이킹이 아니라 “간이 마켓메이킹”으로 제한한다.
- 최근 N봉 평균가격을 중심가격(mid)으로 둔다.
- 가격이 mid 아래 스프레드만큼 내려오면 매수 후보.
- 가격이 mid 위 스프레드만큼 올라가면 매도 후보.
- 중심선 기울기가 너무 크면 추세장으로 보고 신호를 줄인다.

장점:

- 스프레드와 중심가격 개념을 초보자도 볼 수 있다.
- 횡보장에서 가격이 양쪽으로 움직이는 구간을 감시하기 좋다.

위험:

- 실제 시장조성처럼 호가 대기열, 취소 속도, 재고 관리가 정교하지 않다.
- 급등락/갭/장 시작 직후에는 손실이 커질 수 있다.
- 앱에서는 기본적으로 알림/승인 모드에서 쓰는 것이 맞다.

## 앱에 추가한 전략

1. 고정 간격 그리드
   - `MECH:FIXED_GRID`
   - 기준가, 간격 %, BUY/SELL 방향을 노트에 저장한다.

2. 볼린저 하단 매수·상단 매도
   - `MECH:BOLLINGER_CHANNEL`
   - 하단 밴드 터치 BUY, 상단 밴드 터치 SELL.

3. RSI 과매도 매수·과매수 매도
   - `MECH:RSI_CHANNEL`
   - 과매도 BUY, 과매수 SELL.

4. 볼린저+RSI 평균회귀
   - `MECH:MEAN_REVERSION_COMBO`
   - 하단 밴드와 RSI 과매도를 같이 확인.

5. 간이 마켓메이킹
   - `MECH:MARKET_MAKING_LITE`
   - 최근 평균가격 기준 아래/위 스프레드 터치.

## 구현상 안전장치

- 양방향 전략은 매수 조건과 매도 조건을 각각 별도 `StrategyCondition`으로 저장한다.
- 백테스트는 전략 매도 신호를 `전략매도` 청산 사유로 표시한다.
- 손절/익절/최대 보유 봉수는 계속 적용한다.
- 실제 주문은 기존 안전 설정, 쿨다운, 라이브 주문 허용 여부를 그대로 따른다.
- 1분 감시 앱이므로 초단타 HFT처럼 수 밀리초 단위 주문/취소를 하지 않는다.
