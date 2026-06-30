import Foundation

enum SidebarSection: String, CaseIterable, Identifiable {
    case dashboard
    case strategyManager
    case aiAnalysis
    case orderLog
    case market
    case watchlist
    case account
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "대시보드"
        case .strategyManager: "전략 관리"
        case .aiAnalysis: "AI 분석"
        case .orderLog: "주문 로그"
        case .market: "시세"
        case .watchlist: "관심종목"
        case .account: "계좌"
        case .settings: "설정"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "chart.xyaxis.line"
        case .strategyManager: "slider.horizontal.3"
        case .aiAnalysis: "brain.head.profile"
        case .orderLog: "doc.text.magnifyingglass"
        case .market: "list.bullet.rectangle"
        case .watchlist: "star"
        case .account: "person.crop.circle"
        case .settings: "gearshape"
        }
    }
}

enum ConnectionState: Equatable {
    case demo
    case loading
    case live(Date)
    case failed(String)

    var label: String {
        switch self {
        case .demo:
            "데모 데이터"
        case .loading:
            "새로고침 중"
        case .live(let date):
            "실시간 \(date.formatted(date: .omitted, time: .shortened))"
        case .failed(let message):
            message
        }
    }
}

struct Credentials: Equatable {
    var clientID: String = ""
    var clientSecret: String = ""

    var isComplete: Bool {
        !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !clientSecret.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct TokenSnapshot {
    let accessToken: String
    let expiresAt: Date

    var isValid: Bool {
        Date().addingTimeInterval(60) < expiresAt
    }
}

struct APIEnvelope<Result: Decodable>: Decodable {
    let result: Result
}

struct ErrorEnvelope: Decodable {
    let error: APIErrorPayload
}

struct APIErrorPayload: Decodable, Error {
    let requestId: String?
    let code: String
    let message: String
    let data: APIErrorDataPayload?
}

struct APIErrorDataPayload: Decodable {
    let retryAfterSeconds: Int?
    let retryAfterAt: String?
}

struct OAuth2TokenResponse: Decodable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
    }
}

struct PriceResponse: Decodable, Identifiable {
    var id: String { symbol }

    let symbol: String
    let timestamp: String?
    let lastPrice: String
    let currency: String
    let volume: String?

    var lastPriceValue: Decimal {
        decimalValue(lastPrice)
    }

    var volumeValue: Decimal? {
        guard let volume else { return nil }
        return decimalValue(volume)
    }
}

struct Trade: Decodable, Identifiable {
    var id: String { "\(timestamp)-\(price)-\(volume)" }

    let price: String
    let volume: String
    let timestamp: String
    let currency: String

    var priceValue: Decimal {
        decimalValue(price)
    }

    var volumeValue: Decimal {
        decimalValue(volume)
    }

    var tradeValue: Decimal {
        priceValue * volumeValue
    }
}

enum MarketScope: String, CaseIterable, Identifiable, Codable {
    case all
    case domestic
    case overseas

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "전체"
        case .domestic: "국내"
        case .overseas: "해외"
        }
    }
}

struct AutoRebalanceSettings: Codable, Equatable {
    var isEnabled: Bool
    var budget: Double
    var pickCount: Int
    var scanLimit: Int
    var scope: MarketScope
    var intervalMinutes: Int
    var minimumScore: Double
    var operationMode: OperationMode
    var lastRebalancedAt: Date?

    static let defaults = AutoRebalanceSettings(
        isEnabled: false,
        budget: 1_000_000,
        pickCount: 3,
        scanLimit: 8,
        scope: .all,
        intervalMinutes: 15,
        minimumScore: 45,
        operationMode: .autoOrder,
        lastRebalancedAt: nil
    )
}

struct TossCLISettings: Codable, Equatable {
    var isEnabled: Bool
    var commandPath: String
    var rankingSize: Int

    static let defaults = TossCLISettings(
        isEnabled: false,
        commandPath: "tossctl",
        rankingSize: 30
    )
}

enum InvestorRiskTolerance: String, CaseIterable, Codable, Identifiable {
    case careful
    case balanced
    case active

    var id: String { rawValue }

    var title: String {
        switch self {
        case .careful: "조심형"
        case .balanced: "균형형"
        case .active: "공격형"
        }
    }

    var detail: String {
        switch self {
        case .careful:
            "손실을 작게 막고, 자동주문보다 승인 후 주문을 우선합니다."
        case .balanced:
            "수익 기회와 손실 제한을 함께 보고, 조건부 자동화를 사용합니다."
        case .active:
            "짧은 분봉 기회도 보지만, 하루 손실 한도와 중복 주문 차단은 유지합니다."
        }
    }
}

struct InvestorProfileSettings: Codable, Equatable {
    var country: String
    var primaryGoal: String
    var riskTolerance: InvestorRiskTolerance
    var preferredIndustries: String
    var dailyBriefEnabled: Bool

    static let defaults = InvestorProfileSettings(
        country: "대한민국",
        primaryGoal: "분봉 기반 자동매매 보조",
        riskTolerance: .careful,
        preferredIndustries: "반도체, AI, 미국 대형주",
        dailyBriefEnabled: true
    )
}

enum PriceAlertCondition: String, CaseIterable, Codable, Identifiable {
    case above
    case below

    var id: String { rawValue }

    var title: String {
        switch self {
        case .above: "이상"
        case .below: "이하"
        }
    }

    var symbol: String {
        switch self {
        case .above: ">="
        case .below: "<="
        }
    }
}

struct PriceAlert: Identifiable, Codable, Equatable {
    var id = UUID()
    var symbol: String
    var name: String
    var targetPrice: Double
    var condition: PriceAlertCondition
    var isEnabled: Bool
    var createdAt: Date
    var expiresAt: Date
    var lastTriggeredAt: Date?

    var conditionText: String {
        "현재가 \(condition.symbol) \(formattedDouble(targetPrice, fractionDigits: 2))"
    }
}

enum MarketRankingMetric: String, CaseIterable, Identifiable {
    case tradingValue
    case tradingVolume

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tradingValue: "거래대금"
        case .tradingVolume: "거래량"
        }
    }

    var systemImage: String {
        switch self {
        case .tradingValue: "banknote"
        case .tradingVolume: "chart.bar"
        }
    }
}

enum ChartTimeframe: String, CaseIterable, Identifiable {
    case oneMinuteRegular
    case oneMinuteExtended
    case daily
    case weekly
    case monthly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oneMinuteRegular: "정규분봉"
        case .oneMinuteExtended: "전체분봉"
        case .daily: "일봉"
        case .weekly: "주봉"
        case .monthly: "월봉"
        }
    }

    var apiInterval: String {
        switch self {
        case .oneMinuteRegular, .oneMinuteExtended: "1m"
        case .daily, .weekly, .monthly: "1d"
        }
    }

    var candleCount: Int {
        switch self {
        case .oneMinuteRegular: 390
        case .oneMinuteExtended: 1_440
        case .daily: 160
        case .weekly, .monthly: 200
        }
    }

    var isMinute: Bool {
        switch self {
        case .oneMinuteRegular, .oneMinuteExtended:
            true
        case .daily, .weekly, .monthly:
            false
        }
    }
}

struct MarketActivitySnapshot: Identifiable, Equatable {
    var id: String { symbol }

    let symbol: String
    let name: String
    let englishName: String
    let market: String
    let currency: String
    let lastPrice: String
    let timestamp: String?
    let tradeVolume: Decimal?
    let tradeValue: Decimal?
    let tradeSampleCount: Int
    let updatedAt: Date

    var lastPriceValue: Decimal {
        decimalValue(lastPrice)
    }

    var isDomestic: Bool {
        currency == "KRW" || ["KOSPI", "KOSDAQ", "KR_ETC"].contains(market)
    }

    var marketScopeTitle: String {
        isDomestic ? "국내" : "해외"
    }

    func matches(scope: MarketScope) -> Bool {
        switch scope {
        case .all:
            true
        case .domestic:
            isDomestic
        case .overseas:
            !isDomestic
        }
    }
}

struct StockInfo: Decodable {
    let symbol: String
    let name: String
    let englishName: String
    let isinCode: String
    let market: String
    let securityType: String
    let isCommonShare: Bool
    let status: String
    let currency: String
    let listDate: String?
    let delistDate: String?
    let sharesOutstanding: String
    let leverageFactor: String?
}

struct StockSearchItem: Identifiable, Codable, Equatable {
    var id: String { symbol }

    let symbol: String
    var name: String
    var englishName: String
    var market: String
    var currency: String
    var aliases: [String]

    var displayText: String {
        "\(name) · \(symbol)"
    }

    func matches(_ query: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else {
            return true
        }

        let candidates = [symbol, name, englishName, market, currency] + aliases
        return candidates.contains { candidate in
            candidate.lowercased().contains(normalized)
        }
    }
}

struct CandlePageResponse: Decodable {
    let candles: [Candle]
    let nextBefore: String?
}

struct Candle: Decodable, Identifiable {
    var id: String { timestamp }

    let timestamp: String
    let openPrice: String
    let highPrice: String
    let lowPrice: String
    let closePrice: String
    let volume: String
    let currency: String

    var date: Date {
        parseAPIDate(timestamp) ?? .distantPast
    }

    var closeValue: Decimal {
        decimalValue(closePrice)
    }

    var openValue: Decimal {
        decimalValue(openPrice)
    }

    var highValue: Decimal {
        decimalValue(highPrice)
    }

    var lowValue: Decimal {
        decimalValue(lowPrice)
    }

    var volumeValue: Decimal {
        decimalValue(volume)
    }

    var isRising: Bool {
        closeValue >= openValue
    }
}

struct OrderbookResponse: Decodable {
    let timestamp: String?
    let currency: String
    let asks: [OrderbookEntry]
    let bids: [OrderbookEntry]
}

struct OrderbookEntry: Decodable, Identifiable {
    var id: String { "\(price)-\(volume)" }

    let price: String
    let volume: String

    var priceValue: Decimal {
        decimalValue(price)
    }

    var volumeValue: Decimal {
        decimalValue(volume)
    }
}

struct Account: Decodable, Identifiable {
    var id: Int64 { accountSeq }

    let accountNo: String
    let accountSeq: Int64
    let accountType: String

    var accountTypeTitle: String {
        switch accountType {
        case "BROKERAGE":
            "종합매매"
        case "OVERSEAS_DERIVATIVES":
            "해외파생"
        case "PENSION_SAVINGS":
            "연금저축"
        case "RESHORING_INVESTMENT":
            "RIA"
        default:
            accountType
        }
    }

    var accountTypeDescription: String {
        switch accountType {
        case "BROKERAGE":
            "국내·해외 주식 통합 매매 계좌"
        case "OVERSEAS_DERIVATIVES":
            "해외 파생상품 거래 계좌"
        case "PENSION_SAVINGS":
            "세제혜택 연금저축 계좌"
        case "RESHORING_INVESTMENT":
            "RIA 계좌"
        default:
            "알 수 없는 계좌 유형"
        }
    }
}

struct CurrencyAmount: Decodable {
    let krw: String
    let usd: String?
}

struct OverviewMarketValue: Decodable {
    let amount: CurrencyAmount
    let amountAfterCost: CurrencyAmount
}

struct OverviewProfitLoss: Decodable {
    let amount: CurrencyAmount
    let amountAfterCost: CurrencyAmount
    let rate: String
    let rateAfterCost: String
}

struct OverviewDailyProfitLoss: Decodable {
    let amount: CurrencyAmount
    let rate: String
}

struct MarketValuePayload: Decodable {
    let purchaseAmount: String
    let amount: String
    let amountAfterCost: String
}

struct ProfitLossPayload: Decodable {
    let amount: String
    let amountAfterCost: String
    let rate: String
    let rateAfterCost: String
}

struct DailyProfitLossPayload: Decodable {
    let amount: String
    let rate: String
}

struct CostPayload: Decodable {
    let commission: String
    let tax: String?
}

struct HoldingItemResponse: Decodable {
    let symbol: String
    let name: String
    let marketCountry: String
    let currency: String
    let quantity: String
    let lastPrice: String
    let averagePurchasePrice: String
    let marketValue: MarketValuePayload
    let profitLoss: ProfitLossPayload
    let dailyProfitLoss: DailyProfitLossPayload
    let cost: CostPayload
}

struct HoldingsOverviewResponse: Decodable {
    let totalPurchaseAmount: CurrencyAmount
    let marketValue: OverviewMarketValue
    let profitLoss: OverviewProfitLoss
    let dailyProfitLoss: OverviewDailyProfitLoss
    let items: [HoldingItemResponse]
}

struct Holding: Identifiable {
    let id = UUID()
    let symbol: String
    let name: String
    let quantity: String
    let value: String
    let currency: String
    let profitLoss: String
}

enum OperationMode: String, CaseIterable, Codable, Identifiable {
    case alertOnly
    case confirmBeforeOrder
    case autoOrder
    case aiReviewMode

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alertOnly: "알림 모드"
        case .confirmBeforeOrder: "승인 후 주문"
        case .autoOrder: "완전 자동"
        case .aiReviewMode: "AI 검토"
        }
    }

    var detail: String {
        switch self {
        case .alertOnly: "조건 충족 시 알림과 로그만 남깁니다."
        case .confirmBeforeOrder: "사용자 승인이 있어야 주문 요청을 생성합니다."
        case .autoOrder: "사전 설정 안전장치 안에서만 주문을 시도합니다."
        case .aiReviewMode: "주문 전 AI CLI 분석 결과를 로그에 첨부합니다."
        }
    }
}

enum TriggerMetric: String, CaseIterable, Codable, Identifiable {
    case priceBelow
    case priceAbove
    case dropPercent
    case gainPercent
    case profitRateBelow
    case profitRateAbove

    var id: String { rawValue }

    var title: String {
        switch self {
        case .priceBelow: "가격 이하"
        case .priceAbove: "가격 이상"
        case .dropPercent: "기준가 대비 하락률"
        case .gainPercent: "기준가 대비 상승률"
        case .profitRateBelow: "손익률 이하"
        case .profitRateAbove: "손익률 이상"
        }
    }
}

enum StrategyAction: String, CaseIterable, Codable, Identifiable {
    case buy
    case sell
    case notify

    var id: String { rawValue }

    var title: String {
        switch self {
        case .buy: "매수"
        case .sell: "매도"
        case .notify: "알림"
        }
    }

    var apiSide: String? {
        switch self {
        case .buy: "BUY"
        case .sell: "SELL"
        case .notify: nil
        }
    }
}

enum DraftOrderType: String, CaseIterable, Codable, Identifiable {
    case limit
    case market

    var id: String { rawValue }

    var apiValue: String {
        switch self {
        case .limit: "LIMIT"
        case .market: "MARKET"
        }
    }

    var title: String {
        switch self {
        case .limit: "지정가"
        case .market: "시장가"
        }
    }
}

struct StrategyCondition: Identifiable, Codable, Equatable {
    var id = UUID()
    var metric: TriggerMetric = .priceBelow
    var threshold: Double = 0
    var action: StrategyAction = .notify
    var amount: Double = 0
    var quantity: Double = 0
    var orderType: DraftOrderType = .limit
    var note: String = ""
}

struct TradingStrategy: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    var symbol: String
    var isEnabled: Bool
    var mode: OperationMode
    var referencePrice: Double
    var maxDailyAmount: Double
    var stopLossPercent: Double
    var takeProfitPercent: Double
    var cooldownMinutes: Int
    var conditions: [StrategyCondition]
    var createdAt: Date
    var updatedAt: Date
    var riskNotes: String

    var enabledLabel: String {
        isEnabled ? "켜짐" : "꺼짐"
    }
}

struct SafetySettings: Codable, Equatable {
    var dailyBuyLimit: Double
    var dailyLossLimit: Double
    var maxPositionPercent: Double
    var orderCooldownSeconds: Int
    var requireMarketOrderConfirmation: Bool
    var warnLeveragedProducts: Bool
    var blockDuplicateOrders: Bool
    var haltOnAPIError: Bool
    var blockOnNetworkFailure: Bool
    var respectMarketCalendar: Bool
    var allowLiveOrders: Bool

    static let defaults = SafetySettings(
        dailyBuyLimit: 1_000_000,
        dailyLossLimit: 300_000,
        maxPositionPercent: 25,
        orderCooldownSeconds: 90,
        requireMarketOrderConfirmation: true,
        warnLeveragedProducts: true,
        blockDuplicateOrders: true,
        haltOnAPIError: true,
        blockOnNetworkFailure: true,
        respectMarketCalendar: true,
        allowLiveOrders: false
    )
}

enum AIEngineKind: String, CaseIterable, Codable, Identifiable {
    case codex
    case claude
    case gemini

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .codex: "코덱스 CLI"
        case .claude: "클로드 CLI"
        case .gemini: "제미나이 CLI"
        }
    }

    var role: String {
        switch self {
        case .codex: "전략 로직 검토, 조건 생성, 백테스트 코드 초안"
        case .claude: "뉴스 요약, 리스크 분석, 전략 문서화"
        case .gemini: "시장 이슈 요약, 종목 비교, 다중 관점 분석"
        }
    }
}

struct AIEngineConfig: Identifiable, Codable, Equatable {
    var id: AIEngineKind { engine }
    var engine: AIEngineKind
    var isEnabled: Bool
    var analysisCommand: String
    var versionCommand: String
    var lastStatus: String
}

struct AIAnalysisResult: Identifiable, Codable, Equatable {
    var id = UUID()
    var engine: AIEngineKind
    var symbol: String
    var prompt: String
    var output: String
    var riskScore: Int
    var createdAt: Date
}

struct ActiveAIJob: Identifiable, Equatable {
    var id = UUID()
    var engine: AIEngineKind
    var symbol: String
    var purpose: String
    var startedAt = Date()
}

struct OrderLogEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var date = Date()
    var symbol: String
    var strategyName: String
    var mode: OperationMode
    var event: String
    var aiReview: String
    var orderRequest: String
    var result: String
    var isLiveOrder: Bool
}

enum PendingOrderStatus: String, CaseIterable, Codable, Identifiable {
    case pendingReview
    case approvedDryRun
    case submitted
    case canceled
    case blocked

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pendingReview: "승인 대기"
        case .approvedDryRun: "모의 승인"
        case .submitted: "실주문 제출"
        case .canceled: "취소"
        case .blocked: "차단"
        }
    }
}

struct PendingOrderDraft: Identifiable, Codable, Equatable {
    var id = UUID()
    var createdAt = Date()
    var strategyName: String
    var symbol: String
    var side: StrategyAction
    var orderType: DraftOrderType
    var amount: Double
    var amountCurrency: String?
    var quantity: Double
    var referencePrice: Double
    var currency: String
    var mode: OperationMode
    var sourceEvent: String
    var safetyWarnings: [String]
    var aiReview: String
    var status: PendingOrderStatus
    var submittedOrderId: String?

    var orderSummary: String {
        let displayCurrency = amountCurrency ?? (currency.uppercased() == "USD" ? "KRW" : currency)
        let size = quantity > 0 ? "수량 \(formattedDouble(quantity, fractionDigits: 4))" : "금액 \(formattedDouble(amount, fractionDigits: displayCurrency == "KRW" ? 0 : 2)) \(displayCurrency)"
        return "\(side.title) \(symbol) · \(orderType.title) · \(size)"
    }
}

struct ExchangeRateResponse: Decodable {
    let baseCurrency: String
    let quoteCurrency: String
    let rate: String
    let midRate: String?
    let validFrom: String
    let validUntil: String

    var rateValue: Decimal {
        decimalValue(rate)
    }
}

struct BuyingPowerResponse: Decodable {
    let currency: String
    let cashBuyingPower: String

    var cashBuyingPowerValue: Decimal {
        decimalValue(cashBuyingPower)
    }
}

struct SellableQuantityResponse: Decodable {
    let sellableQuantity: String

    var sellableQuantityValue: Decimal {
        decimalValue(sellableQuantity)
    }
}

struct OrderCreatePayload: Encodable {
    var clientOrderId: String?
    var symbol: String
    var side: String
    var orderType: String
    var timeInForce: String?
    var quantity: String?
    var price: String?
    var orderAmount: String?
    var confirmHighValueOrder: Bool?
}

struct OrderResponse: Decodable {
    let orderId: String
    let clientOrderId: String?
}

func decimalValue(_ text: String) -> Decimal {
    let normalized = text
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: ",", with: "")
        .replacingOccurrences(of: "_", with: "")
        .replacingOccurrences(of: " ", with: "")
    return Decimal(string: normalized, locale: Locale(identifier: "en_US_POSIX")) ?? 0
}

func formattedDecimal(_ value: Decimal, fractionDigits: Int = 0) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = fractionDigits
    return formatter.string(from: value as NSDecimalNumber) ?? "\(value)"
}

func formattedDouble(_ value: Double, fractionDigits: Int = 2) -> String {
    formattedDecimal(Decimal(value), fractionDigits: fractionDigits)
}

func cleanedLogText(_ text: String) -> String {
    text.replacingOccurrences(
        of: #"(?<=\d)\.0(?!\d)"#,
        with: "",
        options: .regularExpression
    )
}

func compactDecimal(_ value: Decimal, fractionDigits: Int = 1) -> String {
    let number = NSDecimalNumber(decimal: value).doubleValue
    let absolute = abs(number)

    if absolute >= 1_000_000_000_000 {
        return "\(formattedDecimal(Decimal(number / 1_000_000_000_000), fractionDigits: fractionDigits))조"
    }

    if absolute >= 100_000_000 {
        return "\(formattedDecimal(Decimal(number / 100_000_000), fractionDigits: fractionDigits))억"
    }

    if absolute >= 10_000 {
        return "\(formattedDecimal(Decimal(number / 10_000), fractionDigits: fractionDigits))만"
    }

    return formattedDecimal(value, fractionDigits: fractionDigits)
}

func parseAPIDate(_ value: String) -> Date? {
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = fractional.date(from: value) {
        return date
    }

    let standard = ISO8601DateFormatter()
    standard.formatOptions = [.withInternetDateTime]
    return standard.date(from: value)
}
