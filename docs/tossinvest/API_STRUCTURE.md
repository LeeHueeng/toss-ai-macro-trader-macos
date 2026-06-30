# 토스증권 Open API Structure

Generated at: 2026-06-17T05:46:28.997Z

## Sources

| Name | URL |
| --- | --- |
| llms | https://developers.tossinvest.com/llms.txt |
| overview | https://openapi.tossinvest.com/openapi-docs/overview.md |
| apiReference | https://openapi.tossinvest.com/openapi-docs/latest/api-reference/README.md |
| openapi | https://openapi.tossinvest.com/openapi-docs/latest/openapi.json |

## API Metadata

| Title | Version | OpenAPI | Servers |
| --- | --- | --- | --- |
| 토스증권 Open API | 1.1.1 | 3.1.0 | https://openapi.tossinvest.com |

## Security Schemes

| Name | Type | Scheme | BearerFormat | TokenUrl |
| --- | --- | --- | --- | --- |
| oauth2ClientCredentials | oauth2 |  |  | /oauth2/token |

## Endpoint Index

| Method | Path | Tag | Operation | Auth | Summary |
| --- | --- | --- | --- | --- | --- |
| POST | /oauth2/token | Auth | issueOAuth2Token | none | OAuth2 액세스 토큰 발급 |
| GET | /api/v1/orderbook | Market Data | getOrderbook | oauth2ClientCredentials | 호가 조회 |
| GET | /api/v1/prices | Market Data | getPrices | oauth2ClientCredentials | 현재가 조회 |
| GET | /api/v1/trades | Market Data | getTrades | oauth2ClientCredentials | 최근 체결 내역 조회 |
| GET | /api/v1/price-limits | Market Data | getPriceLimit | oauth2ClientCredentials | 상/하한가 조회 |
| GET | /api/v1/candles | Market Data | getCandles | oauth2ClientCredentials | 캔들 차트 조회 |
| GET | /api/v1/stocks | Stock Info | getStocks | oauth2ClientCredentials | 종목 기본 정보 조회 |
| GET | /api/v1/stocks/{symbol}/warnings | Stock Info | getStockWarnings | oauth2ClientCredentials | 매수 유의사항 조회 |
| GET | /api/v1/exchange-rate | Market Info | getExchangeRate | oauth2ClientCredentials | 환율 조회 |
| GET | /api/v1/market-calendar/KR | Market Info | getKrMarketCalendar | oauth2ClientCredentials | 국내 장 운영 정보 조회 |
| GET | /api/v1/market-calendar/US | Market Info | getUsMarketCalendar | oauth2ClientCredentials | 해외 장 운영 정보 조회 |
| GET | /api/v1/accounts | Account | getAccounts | oauth2ClientCredentials | 계좌 목록 조회 |
| GET | /api/v1/holdings | Asset | getHoldings | oauth2ClientCredentials | 보유 주식 조회 |
| GET | /api/v1/orders | Order History | getOrders | oauth2ClientCredentials | 주문 목록 조회 |
| POST | /api/v1/orders | Order | createOrder | oauth2ClientCredentials | 주문 생성 |
| GET | /api/v1/orders/{orderId} | Order History | getOrder | oauth2ClientCredentials | 주문 상세 조회 |
| POST | /api/v1/orders/{orderId}/modify | Order | modifyOrder | oauth2ClientCredentials | 주문 정정 |
| POST | /api/v1/orders/{orderId}/cancel | Order | cancelOrder | oauth2ClientCredentials | 주문 취소 |
| GET | /api/v1/buying-power | Order Info | getBuyingPower | oauth2ClientCredentials | 매수 가능 금액 조회 |
| GET | /api/v1/sellable-quantity | Order Info | getSellableQuantity | oauth2ClientCredentials | 판매 가능 수량 조회 |
| GET | /api/v1/commissions | Order Info | getCommissions | oauth2ClientCredentials | 매매 수수료 조회 |

## Endpoints By Tag

### Auth

| Method | Path | Operation | Summary |
| --- | --- | --- | --- |
| POST | /oauth2/token | issueOAuth2Token | OAuth2 액세스 토큰 발급 |

### Market Data

| Method | Path | Operation | Summary |
| --- | --- | --- | --- |
| GET | /api/v1/orderbook | getOrderbook | 호가 조회 |
| GET | /api/v1/prices | getPrices | 현재가 조회 |
| GET | /api/v1/trades | getTrades | 최근 체결 내역 조회 |
| GET | /api/v1/price-limits | getPriceLimit | 상/하한가 조회 |
| GET | /api/v1/candles | getCandles | 캔들 차트 조회 |

### Stock Info

| Method | Path | Operation | Summary |
| --- | --- | --- | --- |
| GET | /api/v1/stocks | getStocks | 종목 기본 정보 조회 |
| GET | /api/v1/stocks/{symbol}/warnings | getStockWarnings | 매수 유의사항 조회 |

### Market Info

| Method | Path | Operation | Summary |
| --- | --- | --- | --- |
| GET | /api/v1/exchange-rate | getExchangeRate | 환율 조회 |
| GET | /api/v1/market-calendar/KR | getKrMarketCalendar | 국내 장 운영 정보 조회 |
| GET | /api/v1/market-calendar/US | getUsMarketCalendar | 해외 장 운영 정보 조회 |

### Account

| Method | Path | Operation | Summary |
| --- | --- | --- | --- |
| GET | /api/v1/accounts | getAccounts | 계좌 목록 조회 |

### Asset

| Method | Path | Operation | Summary |
| --- | --- | --- | --- |
| GET | /api/v1/holdings | getHoldings | 보유 주식 조회 |

### Order History

| Method | Path | Operation | Summary |
| --- | --- | --- | --- |
| GET | /api/v1/orders | getOrders | 주문 목록 조회 |
| GET | /api/v1/orders/{orderId} | getOrder | 주문 상세 조회 |

### Order

| Method | Path | Operation | Summary |
| --- | --- | --- | --- |
| POST | /api/v1/orders | createOrder | 주문 생성 |
| POST | /api/v1/orders/{orderId}/modify | modifyOrder | 주문 정정 |
| POST | /api/v1/orders/{orderId}/cancel | cancelOrder | 주문 취소 |

### Order Info

| Method | Path | Operation | Summary |
| --- | --- | --- | --- |
| GET | /api/v1/buying-power | getBuyingPower | 매수 가능 금액 조회 |
| GET | /api/v1/sellable-quantity | getSellableQuantity | 판매 가능 수량 조회 |
| GET | /api/v1/commissions | getCommissions | 매매 수수료 조회 |

## Endpoint Details

### POST /oauth2/token

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| issueOAuth2Token | Auth | none | no | 200 (OAuth2TokenResponse), 400 (OAuth2ErrorResponse), 401 (OAuth2ErrorResponse), 429 (ErrorResponse) |

Request body:

| ContentType | Required | Schema |
| --- | --- | --- |
| application/x-www-form-urlencoded | yes | OAuth2TokenRequest |

### GET /api/v1/orderbook

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getOrderbook | Market Data | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 404 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| symbol | query | yes | string | 종목 심볼. KRX: 6자리 숫자 (예: 005930), US: 영문 티커 (예: AAPL). 영문 대/소문자, 숫자, '.', '-' 만 허용한다. |

### GET /api/v1/prices

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getPrices | Market Data | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 404 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| symbols | query | yes | string | 종목 심볼. 최대 200 개를 콤마(`,`)로 구분. 예: `005930,000660` 또는 `AAPL,MSFT`. 영문 대/소문자, 숫자, '.', '-' 만 허용한다. |

### GET /api/v1/trades

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getTrades | Market Data | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 404 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| symbol | query | yes | string | 종목 심볼. KRX: 6자리 숫자 (예: 005930), US: 영문 티커 (예: AAPL). 영문 대/소문자, 숫자, '.', '-' 만 허용한다. |
| count | query | no | integer | 조회 건수 (최대 50) |

### GET /api/v1/price-limits

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getPriceLimit | Market Data | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 404 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| symbol | query | yes | string | 종목 심볼. KRX: 6자리 숫자 (예: 005930), US: 영문 티커 (예: AAPL). 영문 대/소문자, 숫자, '.', '-' 만 허용한다. |

### GET /api/v1/candles

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getCandles | Market Data | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 404 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| symbol | query | yes | string | 종목 심볼. KRX: 6자리 숫자 (예: 005930), US: 영문 티커 (예: AAPL). 영문 대/소문자, 숫자, '.', '-' 만 허용한다. |
| interval | query | yes | enum<1m \| 1d> | 봉 단위 |
| count | query | no | integer | 조회 봉 수 (최대 200) |
| before | query | no | string:date-time | 페이지네이션 상한 (exclusive, ISO 8601). 이 시각보다 이전의 봉만 반환합니다. 미지정 시 가장 최신 봉부터 반환. 다음 페이지 요청 시 이전 응답의 `nextBefore` 값을 그대로 전달합니다.  |
| adjusted | query | no | boolean | 수정주가 적용 여부. `true` 면 수정주가 적용, `false` 면 미적용. |

### GET /api/v1/stocks

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getStocks | Stock Info | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 401 (ErrorResponse), 403 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| symbols | query | yes | string | 종목 심볼. 콤마로 구분하여 최대 200건. 예: 005930 또는 005930,AAPL. 영문 대/소문자, 숫자, '.', '-' 만 허용한다. |

### GET /api/v1/stocks/{symbol}/warnings

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getStockWarnings | Stock Info | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 401 (ErrorResponse), 403 (ErrorResponse), 404 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| symbol | path | yes | string | 종목 심볼. KRX: 6자리 숫자 (예: 005930), US: 영문 티커 (예: AAPL). 영문 대/소문자, 숫자, '.', '-' 만 허용한다. |

### GET /api/v1/exchange-rate

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getExchangeRate | Market Info | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 404 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| dateTime | query | no | string:date-time | 조회할 환율 시각. 특정 시점의 환율을 조회할 수 있습니다. |
| baseCurrency | query | yes | Currency | 기준 통화 |
| quoteCurrency | query | yes | Currency | 표시 통화 (quote currency) |

### GET /api/v1/market-calendar/KR

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getKrMarketCalendar | Market Info | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| date | query | no | string:date | 조회 기준일 (YYYY-MM-DD) |

### GET /api/v1/market-calendar/US

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getUsMarketCalendar | Market Info | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| date | query | no | string:date | 조회 기준일 (YYYY-MM-DD, 미국 현지 날짜) |

### GET /api/v1/accounts

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getAccounts | Account | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 401 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

### GET /api/v1/holdings

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getHoldings | Asset | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 401 (ErrorResponse), 404 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| X-Tossinvest-Account | header | yes | integer:int64 | API 요청 시 사용할 계좌의 accountSeq. `GET /api/v1/accounts` 응답의 `accountSeq` 값을 사용합니다.  |
| symbol | query | no | string | 종목 심볼. KR: 6자리 숫자 (예: 005930), US: 티커 (예: AAPL). 영문 대/소문자, 숫자, '.', '-' 만 허용한다. 제공 시 해당 종목만 필터링하여 반환하며, 요약 필드도 해당 종목 기준으로 재계산합니다. 미제공 시 전체 보유 종목을 반환합니다.  |

### GET /api/v1/orders

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getOrders | Order History | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 401 (ErrorResponse), 404 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| X-Tossinvest-Account | header | yes | integer:int64 | API 요청 시 사용할 계좌의 accountSeq. `GET /api/v1/accounts` 응답의 `accountSeq` 값을 사용합니다.  |
| status | query | yes | enum<OPEN \| CLOSED> | 주문 라이프사이클 그룹 필터. 이 값은 각 주문의 세부 상태(`orders[].status`)를 **그룹화한 라벨**이며, `orders[].status` 와 값 체계가 다릅니다.  - `OPEN`: 진행 중 주문 그룹 — `orders[].status` ∈ `{PENDING, PARTIAL_FILLED, PENDING_CANCEL, PENDING_REPLACE}` - `CLOSED`: 종료된 주문 그룹 — `orders[].status` ∈ `{FILLED, CANCELED, REJECTED, REPLACED, CANCEL_REJECTED, REPLACE_REJECTED, PARTIAL_FILLED}`  예: `status=OPEN` 을 요청하면 응답의 `orders[].status` 는 개별 주문에 따라 `PENDING`, `PARTIAL_FILLED`, `PENDING_CANCEL`, `PENDING_REPLACE` 중 하나로 내려옵니다.  |
| symbol | query | no | string | 종목 심볼. 지정 시 해당 종목의 주문만 조회. KRX: 6자리 숫자 (`005930`), US: 영문 티커 (`AAPL`). 영문 대/소문자, 숫자, '.', '-' 만 허용한다.  |
| from | query | no | string:date | 조회 시작일 (inclusive, KST 기준). 주문 생성 시간(`orderedAt`) 기준. 미지정 시 전체 기간.  |
| to | query | no | string:date | 조회 종료일 (inclusive, KST 기준). 주문 생성 시간(`orderedAt`) 기준. 미지정 시 전체 기간.  |
| cursor | query | no | string | 페이지네이션 커서. `OPEN` 에서는 무시됩니다. `CLOSED` 에서는 다음 페이지 조회에 사용됩니다.  |
| limit | query | no | integer | 페이지 크기. `OPEN` 에서는 무시됩니다 (전량 반환). `CLOSED` 에서는 적용됩니다 (기본 20, 최대 100).  |

### POST /api/v1/orders

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| createOrder | Order | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 401 (ErrorResponse), 409 (ErrorResponse), 422 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| X-Tossinvest-Account | header | yes | integer:int64 | API 요청 시 사용할 계좌의 accountSeq. `GET /api/v1/accounts` 응답의 `accountSeq` 값을 사용합니다.  |

Request body:

| ContentType | Required | Schema |
| --- | --- | --- |
| application/json | yes | OrderCreateRequest |

### GET /api/v1/orders/{orderId}

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getOrder | Order History | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 401 (ErrorResponse), 404 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| X-Tossinvest-Account | header | yes | integer:int64 | API 요청 시 사용할 계좌의 accountSeq. `GET /api/v1/accounts` 응답의 `accountSeq` 값을 사용합니다.  |
| orderId | path | yes | string | 주문 식별자. 서버에서 발급한 opaque token 입니다.  |

### POST /api/v1/orders/{orderId}/modify

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| modifyOrder | Order | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 401 (ErrorResponse), 404 (ErrorResponse), 409 (ErrorResponse), 422 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| X-Tossinvest-Account | header | yes | integer:int64 | API 요청 시 사용할 계좌의 accountSeq. `GET /api/v1/accounts` 응답의 `accountSeq` 값을 사용합니다.  |
| orderId | path | yes | string | 주문 식별자. 서버에서 발급한 opaque token 입니다.  |

Request body:

| ContentType | Required | Schema |
| --- | --- | --- |
| application/json | yes | OrderModifyRequest |

### POST /api/v1/orders/{orderId}/cancel

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| cancelOrder | Order | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 401 (ErrorResponse), 404 (ErrorResponse), 409 (ErrorResponse), 422 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| X-Tossinvest-Account | header | yes | integer:int64 | API 요청 시 사용할 계좌의 accountSeq. `GET /api/v1/accounts` 응답의 `accountSeq` 값을 사용합니다.  |
| orderId | path | yes | string | 주문 식별자. 서버에서 발급한 opaque token 입니다.  |

Request body:

| ContentType | Required | Schema |
| --- | --- | --- |
| application/json | no | object |

### GET /api/v1/buying-power

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getBuyingPower | Order Info | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 401 (ErrorResponse), 404 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| X-Tossinvest-Account | header | yes | integer:int64 | API 요청 시 사용할 계좌의 accountSeq. `GET /api/v1/accounts` 응답의 `accountSeq` 값을 사용합니다.  |
| currency | query | yes | Currency | 통화 코드 |

### GET /api/v1/sellable-quantity

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getSellableQuantity | Order Info | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 401 (ErrorResponse), 404 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| X-Tossinvest-Account | header | yes | integer:int64 | API 요청 시 사용할 계좌의 accountSeq. `GET /api/v1/accounts` 응답의 `accountSeq` 값을 사용합니다.  |
| symbol | query | yes | string | 종목 심볼. KRX: 6자리 숫자 (예: 005930), US: 영문 티커 (예: AAPL). 영문 대/소문자, 숫자, '.', '-' 만 허용한다. |

### GET /api/v1/commissions

| Operation | Tags | Auth | Deprecated | Responses |
| --- | --- | --- | --- | --- |
| getCommissions | Order Info | oauth2ClientCredentials | no | 200 (allOf<ApiResponse, object>), 400 (ErrorResponse), 401 (ErrorResponse), 429 (ErrorResponse), 500 (ErrorResponse) |

Parameters:

| Name | In | Required | Schema | Description |
| --- | --- | --- | --- | --- |
| X-Tossinvest-Account | header | yes | integer:int64 | API 요청 시 사용할 계좌의 accountSeq. `GET /api/v1/accounts` 응답의 `accountSeq` 값을 사용합니다.  |

## Schemas

### ApiResponse

성공 응답 envelope. 200 응답에 사용됩니다. 각 엔드포인트의 성공 응답 스키마는 `allOf` 로 본 스키마를 상속하며 `result` 를 구체 타입으로 specialize 합니다. 실패 응답은 별도의 `ErrorResponse` 스키마를 사용합니다 (4xx/5xx). `result` 와 `error` 는 동시에 나타나지 않습니다. 

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| result | yes |  | 성공 응답의 페이로드. 엔드포인트별 타입이 다르며, 각 엔드포인트 스펙에서 `allOf` 로 구체 타입을 명시합니다.  |

### ErrorResponse

에러 응답 envelope. 4xx/5xx 응답에 사용됩니다. 성공 응답은 별도의 `ApiResponse` 스키마를 사용합니다. 

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| error | yes | ApiError |  |

### ApiError

에러 객체. 에러 식별에 필요한 최소 정보(`requestId`, `code`, `message`)와 필요 시 해결 힌트(`data`)를 포함합니다. 

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| requestId | yes | string | 요청을 식별하는 고유 ID. 응답 헤더 `X-Request-Id` 와 동일한 값입니다. 토스증권 CS 문의 시 첨부를 권장합니다.  |
| code | yes | string | 에러 코드. flat string 식별자. 도메인 에러는 이유를 직접 표현하는 단일 식별자 (예: `invalid-request`, `order-not-found`) 를 사용합니다. 클라이언트는 unknown code 를 허용하도록 구현해야 합니다.  |
| message | yes | string | 사용자에게 노출 가능한 에러 메시지. 내부 정책상 노출이 제한되는 경우 빈 문자열로 내려갈 수 있으므로 클라이언트는 `code` 기반으로 메시지를 자체 매핑할 것을 권장합니다.  |
| data | no | object,null | 에러 해결 힌트. 에러 코드별로 포함 여부와 키 구조가 다르며, 없는 경우 필드 자체가 생략됩니다. 모든 표준 키가 항상 함께 내려가지 않으며, 각 에러 코드에 해당하는 서브셋만 포함됩니다.  ## 표준 키 (camelCase)  \| 키 \| 타입 \| 설명 \| \|---\|---\|---\| \| `field` \| string \| 검증 실패 원인 필드. 외부 API 에 노출된 이름 (request body JSON key 또는 query parameter name) 을 사용합니다. 복수 필드는 쉼표로 구분 (예: `"quantity,orderAmount"`). \| \| `allowedValues` \| string[] \| enum 후보 값 전체. \| \| `allowedConditions` \| object \| 조건부 허용 규칙 (`marketCountry` / `orderType` / `side` 등). \| \| `constraint` \| object \| 필드 제약 (`min` / `max` / `integerOnly` / `step`). \| \| `format` \| string \| 포맷 규칙명 (예: `decimal`). \| \| `pattern` \| string \| 정규식. \| \| `maxLength` \| number \| 문자열 길이 상한. \| \| `limits` \| object \| 금액 / 수량 한도 (`threshold` / `minimum` / `maximum` + `currency`). \| \| `retryAfterAt` \| string \| 절대 재시도 시각 (ISO 8601 offset, KST). \| \| `retryAfterSeconds` \| number \| 상대 재시도 시각 (초). \| \| `tickSize` \| string \| 호가 단위. \| \| `nearestPrices` \| string[] \| 근접 유효 가격 (`[lower, upper]`). \|  구체적인 에러 코드별 `data` 예시는 각 엔드포인트의 4xx / 5xx 응답 예시를 참고합니다.  |

### Currency

통화 코드. - KRW: 한국 원화 - USD: 미국 달러  클라이언트는 unknown enum 값을 허용하도록 구현해야 합니다. 

Enum: KRW, USD

### MarketCountry

시장 국가 구분. - KR: 국내 주식 (KRX) - US: 미국 주식 (NYSE, NASDAQ 등)  클라이언트는 unknown enum 값을 허용하도록 구현해야 합니다. 

Enum: KR, US

### OAuth2TokenRequest

OAuth2 Client Credentials Grant 토큰 발급 요청. `application/x-www-form-urlencoded` 으로 전송합니다. 

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| grant_type | yes | enum<client_credentials> | 인증 방식. `client_credentials` 만 지원합니다. |
| client_id | yes | string | 발급받은 클라이언트 ID |
| client_secret | yes | string:password | 발급받은 클라이언트 시크릿. 노출되지 않도록 서버 측에서만 사용합니다. |

### OAuth2TokenResponse

토큰 발급 성공 응답. BFF 의 공통 `ApiResponse` envelope 을 사용하지 않고 OAuth2 표준 형식으로 응답합니다. 

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| access_token | yes | string | JWT 형식의 access token. 모든 API 요청의 `Authorization: Bearer` 헤더에 담습니다. |
| token_type | yes | enum<Bearer> | 토큰 타입. 항상 `Bearer`. |
| expires_in | yes | integer:int64 | 토큰 만료까지 남은 초. |

### OAuth2ErrorResponse

OAuth2 토큰 발급 실패 응답. `/oauth2/token` 엔드포인트는 BFF 공통 `ErrorResponse` envelope 이 아닌 OAuth2 표준 포맷으로 응답합니다. 클라이언트는 `code` 가 아닌 `error` 필드로 에러를 식별해야 합니다. 

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| error | yes | enum<invalid_request \| invalid_client \| invalid_grant \| unauthorized_client \| unsupported_grant_type> | 에러 코드. |
| error_description | no | string | 에러 상세 설명 (선택). 메시지에 non-ASCII 문자가 포함되는 경우 생략될 수 있습니다.  |
| error_uri | no | string:uri | 에러 정보가 게시된 페이지 URI (선택). |

### OrderbookEntry

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| price | yes | string:decimal | 호가 |
| volume | yes | string:decimal | 잔량 |

### OrderbookResponse

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| timestamp | no | string,null:date-time | 데이터 시각. 데이터 미제공 시 null |
| currency | yes | Currency |  |
| asks | yes | array<OrderbookEntry> | 매도호가 목록 (낮은 가격순) |
| bids | yes | array<OrderbookEntry> | 매수호가 목록 (높은 가격순) |

### PriceResponse

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| symbol | yes | string | 종목 심볼 |
| timestamp | no | string,null:date-time | 데이터 시각. 체결 미발생 등으로 시각이 없을 경우 null |
| lastPrice | yes | string:decimal | 현재가 |
| currency | yes | Currency |  |

### Trade

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| price | yes | string:decimal | 체결가 |
| volume | yes | string:decimal | 체결 수량 |
| timestamp | yes | string:date-time | 체결 시각 |
| currency | yes | Currency |  |

### PriceLimitResponse

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| timestamp | yes | string:date-time | 데이터 시각 |
| upperLimitPrice | no | string,null:decimal | 상한가. 미국 주식 등 가격제한이 없는 시장에서는 null |
| lowerLimitPrice | no | string,null:decimal | 하한가. 미국 주식 등 가격제한이 없는 시장에서는 null |
| currency | yes | Currency |  |

### CandlePageResponse

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| candles | yes | array<Candle> | 캔들 목록 |
| nextBefore | no | string,null:date-time | 다음 페이지 조회 시 `before` 쿼리 파라미터에 그대로 전달. 마지막 페이지면 null. |

### Candle

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| timestamp | yes | string:date-time | 봉 시작 시각 |
| openPrice | yes | string:decimal | 시가 |
| highPrice | yes | string:decimal | 고가 |
| lowPrice | yes | string:decimal | 저가 |
| closePrice | yes | string:decimal | 종가 |
| volume | yes | string:decimal | 거래량 |
| currency | yes | Currency |  |

### StockInfo

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| symbol | yes | string | 종목 심볼. |
| name | yes | string | 종목명 (한글) |
| englishName | yes | string | 영문 종목명 |
| isinCode | yes | string | 국제증권식별번호 (ISO 6166) |
| market | yes | enum<KOSPI \| KOSDAQ \| NYSE \| NASDAQ \| AMEX \| KR_ETC \| US_ETC> | 상장 시장. warnings API의 exchange(거래소 단위)와 달리 시장 세그먼트 단위로 구분 |
| securityType | yes | enum<STOCK \| FOREIGN_STOCK \| DEPOSITARY_RECEIPT \| INFRASTRUCTURE_FUND \| REIT \| ETF \| FOREIGN_ETF \| ETN \| STOCK_WARRANTS> | 종목 유형 |
| isCommonShare | yes | boolean | 보통주 여부. 우선주인 경우 false |
| status | yes | enum<SCHEDULED \| ACTIVE \| DELISTED> | 상장 상태 |
| currency | yes | Currency |  |
| listDate | no | string,null:date | 상장일 (YYYY-MM-DD, KST 기준). 정보 미제공 시 null |
| delistDate | no | string,null:date | 상장폐지일 (YYYY-MM-DD, KST 기준). 활성 종목은 null |
| sharesOutstanding | yes | string:decimal | 발행주식수 |
| leverageFactor | no | string,null:decimal | 레버리지 배수. ETF/ETN에만 적용 (1.0, 2.0, -1.0 등). 일반 주식 등 해당 없는 종목은 null |
| koreanMarketDetail | no | oneOf<KrMarketDetail, null> | 국내 시장 상세 정보. 국내 종목(KOSPI, KOSDAQ, KR_ETC)에만 제공되며, 해외 종목은 null |

### KrMarketDetail

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| liquidationTrading | yes | boolean | 정리매매 여부 (상장폐지 절차 진행 중). |
| nxtSupported | yes | boolean | NXT 대체거래소 지원 여부 |
| krxTradingSuspended | yes | boolean | KRX 거래정지 여부 |
| nxtTradingSuspended | no | boolean,null | NXT 거래정지 여부. NXT 미지원 종목(nxtSupported=false)은 null |

### StockWarning

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| warningType | yes | enum<LIQUIDATION_TRADING \| OVERHEATED \| INVESTMENT_WARNING \| INVESTMENT_RISK \| VI_STATIC_AND_DYNAMIC \| VI_STATIC \| VI_DYNAMIC \| STOCK_WARRANTS> | 유의사항 유형. 클라이언트는 unknown code 를 허용하도록 구현해야 합니다.  \| 값 \| 의미 \| \|------\|------\| \| `LIQUIDATION_TRADING` \| 정리매매 (상장폐지 절차 진행 중) \| \| `OVERHEATED` \| 단기과열종목 지정 \| \| `INVESTMENT_WARNING` \| 투자경고종목 지정 \| \| `INVESTMENT_RISK` \| 투자위험종목 지정 \| \| `VI_STATIC_AND_DYNAMIC` \| 변동성 완화장치(VI) 정적 + 동적 동시 발동 \| \| `VI_STATIC` \| 변동성 완화장치(VI) 정적 발동 \| \| `VI_DYNAMIC` \| 변동성 완화장치(VI) 동적 발동 \| \| `STOCK_WARRANTS` \| 신주인수권증서/증권 \|  |
| exchange | no | string,null | 거래소 코드 (KRX, NXT 등 물리적 거래소 단위). stocks API의 market(상장 시장 단위)과 추상화 수준이 다름. 거래소 무관 경고는 null |
| startDate | no | string,null:date | 적용 시작일 (inclusive, YYYY-MM-DD, KST 기준). 시작일 미정 시 null |
| endDate | no | string,null:date | 적용 종료일 (inclusive, YYYY-MM-DD, KST 기준). 진행 중이거나 미정 시 null |

### ExchangeRateResponse

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| baseCurrency | yes | Currency | 기준 통화 |
| quoteCurrency | yes | Currency | 표시 통화 (quote currency) |
| rate | yes | string:decimal | 매수 환율 (1 baseCurrency = ? quoteCurrency) |
| midRate | yes | string:decimal | 매매기준율 (은행간 mid rate) |
| basisPoint | yes | string:decimal | 매매기준율(midRate) 대비 basis points. (rate - midRate) / midRate * 10000 |
| rateChangeType | yes | enum<UP \| EQUAL \| DOWN> | 등락 구분 |
| validFrom | yes | string:date-time | 환율 유효 시작 시각 |
| validUntil | yes | string:date-time | 환율 유효 종료 시각 |

### KrMarketCalendarResponse

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| today | yes | KrMarketDay |  |
| previousBusinessDay | yes | KrMarketDay |  |
| nextBusinessDay | yes | KrMarketDay |  |

### KrMarketDay

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| date | yes | string:date | 영업일 (KST 기준) |
| integrated | no | oneOf<IntegratedHour, null> | 거래 가능 시간 (통합 모드 (KRX+NXT) 기준). 둘 다 휴장이면 null |

### IntegratedHour

거래 가능 시간. 특수장(시간외종가/시간외단일가) 제외, 통합 모드 (KRX+NXT) 기준. 세 세션(`preMarket`, `regularMarket`, `afterMarket`) 각각 nullable. 해당 세션이 휴장이면 null, 세 세션 모두 null 이면 상위 `integrated` 자체가 null. 

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| preMarket | no | oneOf<PreMarketSession, null> | 프리마켓 (NXT 접속매매). NXT 프리마켓이 휴장이면 null |
| regularMarket | no | oneOf<RegularMarketSession, null> | 정규장. KRX·NXT 정규장의 합집합. 둘 다 휴장이면 null |
| afterMarket | no | oneOf<AfterMarketSession, null> | 애프터마켓 (NXT). NXT 애프터마켓이 휴장이면 null |

### PreMarketSession

프리마켓 세션

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| startTime | yes | string:date-time | 프리마켓 시작 |
| singlePriceAuctionStartTime | no | oneOf<string:date-time, null> | 프리마켓 내 시가단일가 구간 시작 (NXT 프리마켓 접속매매 종료). 단일가 정보 결손 시 null |
| endTime | yes | string:date-time | 프리마켓 종료 (시가단일가 종료) |

### RegularMarketSession

정규장 세션. KRX·NXT 정규장의 합집합(가장 이른 시작 ~ 가장 늦은 종료). 종가단일가 구간을 포함

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| startTime | yes | string:date-time | 정규장 시작. 가장 이른 KRX/NXT 정규장 시작 시각 |
| singlePriceAuctionStartTime | no | oneOf<string:date-time, null> | 정규장 내 종가단일가 구간 시작 (KRX 기준). KRX 휴장이면 null |
| endTime | yes | string:date-time | 정규장 종료 (종가단일가 종료) |

### AfterMarketSession

애프터마켓 세션 (NXT)

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| startTime | yes | string:date-time | 애프터마켓 시작 |
| singlePriceAuctionEndTime | no | oneOf<string:date-time, null> | 애프터마켓 내 시가단일가 구간 종료. |
| endTime | yes | string:date-time | 애프터마켓 전체 종료 |

### UsMarketCalendarResponse

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| today | yes | UsMarketDay |  |
| previousBusinessDay | yes | UsMarketDay |  |
| nextBusinessDay | yes | UsMarketDay |  |

### UsMarketDay

미국 시장 영업일 정보. 4 세션(`dayMarket`, `preMarket`, `regularMarket`, `afterMarket`) 각각 nullable. 휴장일이면 4 세션 모두 null. 

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| date | yes | string:date | 영업일 (미국 현지 기준) |
| dayMarket | no | oneOf<UsDayMarketSession, null> | 데이마켓 세션 (토스증권). 휴장이면 null |
| preMarket | no | oneOf<UsPreMarketSession, null> | 프리마켓 세션. 휴장이면 null |
| regularMarket | no | oneOf<UsRegularMarketSession, null> | 정규장 세션. 휴장이면 null |
| afterMarket | no | oneOf<UsAfterMarketSession, null> | 애프터마켓 세션. 휴장이면 null |

### UsDayMarketSession

데이마켓 세션 (토스증권)

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| startTime | yes | string:date-time | 데이마켓 시작 |
| endTime | yes | string:date-time | 데이마켓 종료 |

### UsPreMarketSession

프리마켓 세션

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| startTime | yes | string:date-time | 프리마켓 시작 |
| endTime | yes | string:date-time | 프리마켓 종료 |

### UsRegularMarketSession

정규장 세션

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| startTime | yes | string:date-time | 정규장 시작 |
| endTime | yes | string:date-time | 정규장 종료 |

### UsAfterMarketSession

애프터마켓 세션

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| startTime | yes | string:date-time | 애프터마켓 시작 |
| endTime | yes | string:date-time | 애프터마켓 종료 |

### Account

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| accountNo | yes | string | 계좌번호 |
| accountSeq | yes | integer:int64 | 계좌 식별 키. 주문 등 API 호출 시 이 값을 사용 |
| accountType | yes | enum<BROKERAGE \| OVERSEAS_DERIVATIVES \| PENSION_SAVINGS \| RESHORING_INVESTMENT> | 계좌 유형. 현재는 BROKERAGE 만 지원합니다. - BROKERAGE: 종합매매. 국내·해외 주식 통합 매매 계좌 - OVERSEAS_DERIVATIVES: 해외파생. 해외 파생상품 거래 계좌 - PENSION_SAVINGS: 연금저축. 세제혜택 연금저축 계좌 - RESHORING_INVESTMENT: RIA 계좌  클라이언트는 unknown enum 값을 허용하도록 구현해야 합니다.  |

### HoldingsOverview

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| totalPurchaseAmount | yes | allOf<Price> | 투자원금. 전체 보유 종목의 통화별 합산 |
| marketValue | yes | OverviewMarketValue |  |
| profitLoss | yes | OverviewProfitLoss |  |
| dailyProfitLoss | yes | OverviewDailyProfitLoss |  |
| items | yes | array<HoldingsItem> | 보유 종목 목록. 보유 종목이 없으면 빈 배열 |

### HoldingsItem

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| symbol | yes | string | 종목 심볼. KR: 6자리 숫자, US: 티커 |
| name | yes | string | 종목명 |
| marketCountry | yes | MarketCountry |  |
| currency | yes | Currency |  |
| quantity | yes | string:decimal | 보유 수량 |
| lastPrice | yes | string:decimal | 현재가. 거래 통화(currency) 기준 |
| averagePurchasePrice | yes | string:decimal | 매수 평균가. 거래 통화(currency) 기준 |
| marketValue | yes | MarketValue |  |
| profitLoss | yes | ProfitLoss |  |
| dailyProfitLoss | yes | DailyProfitLoss |  |
| cost | yes | Cost |  |

### Price

통화별 합산 금액. 각 통화 필드는 해당 통화로 거래된 종목의 합만 포함합니다 (환율 환산을 통한 통화 간 합산 미포함).

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| krw | yes | string:decimal | KRW로 거래되는 국내 종목의 합산 금액. 국내 종목이 없으면 0 |
| usd | no | string,null:decimal | USD로 거래되는 해외 종목의 합산 금액. 해외 종목이 없으면 null |

### OverviewMarketValue

시장 평가금액. 전체 보유 종목의 통화별 합산

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| amount | yes | allOf<Price> | 시장 평가금액 |
| amountAfterCost | yes | allOf<Price> | 세금/수수료 공제 후 평가금액 |

### OverviewProfitLoss

손익. 전체 보유 종목의 통화별 합산

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| amount | yes | allOf<Price> | 손익금액 |
| amountAfterCost | yes | allOf<Price> | 세금/수수료 공제 후 손익금액 |
| rate | yes | string:decimal | 손익률 (소수비율). 전체 자산을 현재 환율로 원화 환산한 기준. 0.1516 = 15.16% |
| rateAfterCost | yes | string:decimal | 세금/수수료 공제 후 손익률 (소수비율). 전체 자산을 현재 환율로 원화 환산한 기준. 0.1406 = 14.06% |

### OverviewDailyProfitLoss

일간 손익. 전체 보유 종목의 통화별 합산

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| amount | yes | allOf<Price> | 일간 손익금액 |
| rate | yes | string:decimal | 일간 손익률 (소수비율). 전체 자산을 현재 환율로 원화 환산한 기준. 0.0185 = 1.85% |

### MarketValue

시장 평가. 거래 통화(currency) 기준

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| purchaseAmount | yes | string:decimal | 매입금액 |
| amount | yes | string:decimal | 시장 평가금액 |
| amountAfterCost | yes | string:decimal | 세금/수수료 공제 후 평가금액 |

### ProfitLoss

손익. 거래 통화(currency) 기준

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| amount | yes | string:decimal | 손익금액 |
| amountAfterCost | yes | string:decimal | 세금/수수료 공제 후 손익금액 |
| rate | yes | string:decimal | 손익률. 소수비율 (0.1077 = 10.77%) |
| rateAfterCost | yes | string:decimal | 세금/수수료 공제 후 손익률. 소수비율 (0.0846 = 8.46%) |

### DailyProfitLoss

일간 손익. 거래 통화(currency) 기준

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| amount | yes | string:decimal | 일간 손익금액 |
| rate | yes | string:decimal | 일간 손익률. 소수비율 (0.0141 = 1.41%) |

### Cost

비용. 거래 통화(currency) 기준

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| commission | yes | string:decimal | 수수료 |
| tax | no | string,null:decimal | 세금. 세금이 없는 경우 null |

### OrderCreateRequest

### OrderModifyRequest

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| orderType | yes | enum<LIMIT \| MARKET> | 변경할 호가 유형. - `LIMIT`: 지정가 - `MARKET`: 시장가  |
| quantity | no | string:decimal | 변경할 수량. **KR 주식: 필수.** 양의 정수만 허용합니다 (미전달/0/음수/소수점은 `400 invalid-request`). US 주식: 전달 불가. 제공 시 `400 us-modify-quantity-not-supported` 에러.  |
| price | no | string:decimal | 변경할 가격. `orderType`이 `LIMIT` 일 때만 사용합니다. - `LIMIT`: 필수. 미전달 시 `400 invalid-request`. - `MARKET`: 전달 불가. 전달 시 `400 invalid-request`. KR: 정수 (원 단위). 호가 단위에 맞아야 합니다. 맞지 않으면 `400 invalid-request` 에러. US: 소수점 (달러 단위).   - $1 미만: 소수점 넷째 자리까지 (그 이하 자릿수는 절삭).   - $1 이상: 소수점 둘째 자리까지 (그 이하 자릿수는 절삭).  |
| confirmHighValueOrder | no | boolean | 착오주문 방지를 위한 주문 확인 플래그. 기본값 `false`. 1억원 이상의 주문 시 `true`가 아니면 `400 confirm-high-value-required` 에러를 반환합니다. 사용자가 해당 주문의 금액을 인지하고 있음을 표시하기 위한 필드입니다. 30억원 이상의 주문은 본 플래그와 무관하게 `422 max-order-amount-exceeded` 에러를 반환합니다.  |

### OrderResponse

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| orderId | yes | string | 서버 생성 주문 식별자. 정정/취소 시 사용 |
| clientOrderId | no | string,null | 요청 시 전달한 값 그대로 반환. 미전달 시 `null`. |

### OrderOperationResponse

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| orderId | yes | string | 정정/취소로 새로 발급된 주문 식별자. 원주문의 orderId 와 다릅니다.  |

### PaginatedOrderResponse

주문 목록 페이징 응답. - `status=OPEN`: 모든 대기 중 주문을 반환합니다. `nextCursor`는 항상 `null`, `hasNext`는 항상 `false`. - `status=CLOSED`: 현재 호출 시 `400 closed-not-supported` 를 반환합니다. 

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| orders | yes | array<Order> | 주문 목록 |
| nextCursor | yes | string,null | 다음 페이지 커서. 다음 페이지가 없으면 null |
| hasNext | yes | boolean | 다음 페이지 존재 여부 |

### Order

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| orderId | yes | string | 주문 식별자 |
| symbol | yes | string | 종목 심볼. KRX: 6자리 숫자, US: 영문 티커 |
| side | yes | enum<BUY \| SELL> | 주문 방향 |
| orderType | yes | enum<LIMIT \| MARKET> | 호가 유형. - `LIMIT`: 지정가 - `MARKET`: 시장가  클라이언트는 unknown code 를 허용하도록 구현해야 합니다.  |
| timeInForce | yes | enum<DAY \| CLS \| OPG> | 주문 유효 조건 (Time In Force). `orderType` 과 결합되어 주문 방식이 결정됩니다 (예: `LIMIT` + `CLS` = LOC). - `DAY`: 당일 유효 (Day) - `CLS`: 장 마감 주문 (At the Close) - `OPG`: 장 개시 주문 (At the Opening). 현재는 지원하지 않습니다.  클라이언트는 unknown code 를 허용하도록 구현해야 합니다.  |
| status | yes | OrderStatus |  |
| price | no | string,null:decimal | 주문 가격 (native currency). MARKET 주문 시 null |
| quantity | yes | string:decimal | 주문 수량 |
| orderAmount | no | string,null:decimal | 주문 금액 (USD). 금액 기반 US 시장가 매수 주문에만 해당. 그 외 null |
| currency | yes | Currency |  |
| orderedAt | yes | string:date-time | 주문 시간 (ISO 8601, KST) |
| canceledAt | no | string,null:date-time | 취소 시간 (ISO 8601, KST). 해당 없으면 null |
| execution | yes | allOf<OrderExecution> | 체결 결과. 체결 내역이 없으면 filledQuantity=0 |

### OrderExecution

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| filledQuantity | yes | string:decimal | 체결 수량 |
| averageFilledPrice | yes | string,null:decimal | 평균 체결 가격 (native currency). 부분 체결 시 체결된 건의 평균 |
| filledAmount | yes | string,null:decimal | 총 체결 금액 (native currency) |
| commission | yes | string,null:decimal | 총 체결 수수료 (native currency) |
| tax | yes | string,null:decimal | 총 체결 세금 (native currency) |
| filledAt | yes | string,null:date-time | 최종 체결 시간 (ISO 8601, KST) |
| settlementDate | yes | string,null:date | 결제 예정일 (YYYY-MM-DD, KST 기준). 미결제 시 null |

### OrderStatus

주문 상태. - `PENDING`: 체결 대기. 주문이 접수되어 체결을 대기 중인 상태 - `PENDING_CANCEL`: 취소 대기. 취소 요청이 접수되어 브로커 응답을 대기 중인 상태 - `PENDING_REPLACE`: 정정 대기. 정정 요청이 접수되어 브로커 응답을 대기 중인 상태 - `PARTIAL_FILLED`: 부분 체결. 주문 수량 중 일부만 체결된 상태 - `FILLED`: 체결 완료. 주문 수량이 전량 체결된 상태 - `CANCELED`: 취소 완료. execution.filledQuantity를 통해 부분 체결 여부를 확인할 수 있음 - `REJECTED`: 거부됨. 브로커가 주문을 거부한 상태. execution.filledQuantity를 통해 부분 체결 여부를 확인할 수 있음 - `CANCEL_REJECTED`: 취소 거부. 브로커가 취소 요청을 거부한 경우 별도 주문 레코드로 생성됨. 원주문은 이전 상태로 복귀함 - `REPLACE_REJECTED`: 정정 거부. 브로커가 정정 요청을 거부한 경우 별도 주문 레코드로 생성됨. 원주문은 이전 상태로 복귀함 - `REPLACED`: 정정됨. 정정 요청이 수락되어 원주문이 대체된 상태. execution.filledQuantity를 통해 부분 체결 여부를 확인할 수 있음  클라이언트는 unknown code 를 허용하도록 구현해야 합니다. 

Enum: PENDING, PENDING_CANCEL, PENDING_REPLACE, PARTIAL_FILLED, FILLED, CANCELED, REJECTED, CANCEL_REJECTED, REPLACE_REJECTED, REPLACED

### BuyingPowerResponse

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| currency | yes | Currency |  |
| cashBuyingPower | yes | string:decimal | 현금 기반 매수 가능 금액 (미수 미발생 기준). 순수 현금으로 매수할 수 있는 금액. KRW: 정수 (원 단위). USD: 소수점 포함 (달러 단위).  |

### SellableQuantityResponse

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| sellableQuantity | yes | string:decimal | 판매 가능 수량. KR: 정수 (주 단위). US: 소수점 포함 가능 (주 단위).  |

### Commission

| Property | Required | Schema | Description |
| --- | --- | --- | --- |
| marketCountry | yes | MarketCountry |  |
| commissionRate | yes | string:decimal | 수수료율 (%). 예: 0.015는 0.015% |
| startDate | no | string,null:date | 수수료 적용 시작일 (YYYY-MM-DD, KST 기준). 해외주식은 null |
| endDate | no | string,null:date | 수수료 적용 종료일 (YYYY-MM-DD, KST 기준). 무기한 적용 시 null |

