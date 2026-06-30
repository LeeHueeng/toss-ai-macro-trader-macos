import Foundation

private struct TossCLIRankingResponse: Decodable {
    let stocks: [TossCLIRankedStock]
}

private struct TossCLIRankedStock: Decodable {
    let rank: Int
    let productCode: String
    let symbol: String?
    let name: String?
    let market: String?

    enum CodingKeys: String, CodingKey {
        case rank
        case productCode = "product_code"
        case symbol
        case name
        case market
    }
}

private enum TossCLIIntegrationError: LocalizedError {
    case emptyCommand
    case executionFailed(Int32, String)

    var errorDescription: String? {
        switch self {
        case .emptyCommand:
            "tossctl 명령어가 비어 있습니다."
        case .executionFailed(let status, let output):
            "tossctl 종료 코드 \(status): \(output)"
        }
    }
}

private enum PublicDomesticRankingSource {
    case naver
    case nextrade
    case none
}

@MainActor
final class AppSession: ObservableObject {
    @Published var selectedSection: SidebarSection = .dashboard
    @Published var selectedSymbol = "005930"
    @Published var watchedSymbols = ["005930", "000660", "AAPL", "MSFT", "NVDA"]
    @Published var credentials = Credentials()
    @Published var connectionState: ConnectionState = .demo
    @Published var prices: [PriceResponse] = MockData.prices
    @Published var marketActivities: [MarketActivitySnapshot] = MockData.marketActivities
    @Published var marketActivitySourceText = "데모 예시 데이터입니다. 실제 시장 순위가 아닙니다."
    @Published var marketActivityQualityText = "데이터 검증 대기 중"
    @Published var marketActivityAllowsAutoSelection = false
    @Published var stockDirectory: [StockSearchItem] = MockData.stockDirectory
    @Published var chartTimeframe: ChartTimeframe = .oneMinuteExtended
    @Published var candles: [Candle] = MockData.candles
    @Published var orderbook: OrderbookResponse = MockData.orderbook
    @Published var accounts: [Account] = []
    @Published var selectedAccountSeq: Int64?
    @Published var holdings: [Holding] = MockData.holdings
    @Published var priceAlerts: [PriceAlert] = []
    @Published var strategies: [TradingStrategy] = MockData.strategies
    @Published var orderLogs: [OrderLogEntry] = MockData.orderLogs
    @Published var pendingOrders: [PendingOrderDraft] = []
    @Published var safetySettings: SafetySettings = .defaults
    @Published var autoRebalanceSettings: AutoRebalanceSettings = .defaults
    @Published var tossCLISettings: TossCLISettings = .defaults
    @Published var investorProfile: InvestorProfileSettings = .defaults
    @Published var tossCLIDiscoveryStatus = "tossctl 후보 보강 꺼짐"
    @Published var isAutoRebalancing = false
    @Published var lastAutoRebalanceMessage = "자동 리밸런싱 대기 중"
    @Published var aiEngines: [AIEngineConfig] = MockData.aiEngines
    @Published var aiResults: [AIAnalysisResult] = MockData.aiResults
    @Published var activeAIJobs: [ActiveAIJob] = []
    @Published var apiCooldownUntil: Date?
    @Published var isLiveOrderReadinessChecking = false
    @Published var liveOrderReadinessCheckStatus = "아직 점검하지 않았습니다."
    @Published var manualOrderStatus = "아직 주문 테스트를 만들지 않았습니다."
    @Published var automationEnabled = false {
        didSet {
            guard automationEnabled != oldValue else {
                return
            }
            updateAutomationMonitor()
        }
    }
    @Published var lastAutomationScanAt: Date?
    @Published var nextAutomationScanAt: Date?
    @Published var lastAutomationDecision = "자동 감시 전"

    private let keychain = KeychainStore(service: "com.tosschart.credentials")
    private let credentialsKeychainAccount = "tossAPI.credentials.v2"
    private let client = TossInvestClient()
    private let naverRankingClient = NaverMarketRankingClient()
    private let nextradeClient = NextradeMarketRankingClient()
    private let yahooFinanceClient = YahooFinanceClient()
    private let store = LocalJSONStore()
    private let aiRunner = AICommandRunner()
    private let notifications = NotificationService()
    private var token: TokenSnapshot?
    private var automationMonitorTask: Task<Void, Never>?
    private var isAutomationScanRunning = false
    private var isMarketRefreshRunning = false
    private var isMarketActivityRefreshRunning = false
    private var candleCacheKey: String?
    private var strategyCandleCache: [String: [Candle]] = [:]
    private var lastTossCLIRankingImportAt: Date?
    private var publicDomesticRankingCache: (updatedAt: Date, source: PublicDomesticRankingSource, rows: [MarketActivitySnapshot])?
    private var publicOverseasRankingCache: (updatedAt: Date, rows: [MarketActivitySnapshot])?
    private var latestPublicDomesticRankingSource: PublicDomesticRankingSource = .none
    private var sectionRefreshTimestamps: [String: Date] = [:]
    private var sectionRefreshesInFlight = Set<String>()
    private let automationScanIntervalSeconds: TimeInterval = 60

    init() {
        loadCredentials()
        loadAppState()
        normalizeAIEngineCommands()
        Task { await notifications.requestAuthorization() }
    }

    var activeStrategyCount: Int {
        strategies.filter(\.isEnabled).count
    }

    var activePriceAlertCount: Int {
        let now = Date()
        return priceAlerts.filter { $0.isEnabled && $0.expiresAt > now }.count
    }

    var latestAIStatus: String {
        aiResults.first.map { "\($0.engine.displayName) 위험도 \($0.riskScore)" } ?? "검토 없음"
    }

    var isAIRunning: Bool {
        !activeAIJobs.isEmpty
    }

    var isAPICoolingDown: Bool {
        guard let apiCooldownUntil else {
            return false
        }
        return apiCooldownUntil > Date()
    }

    var apiCooldownRemainingSeconds: Int {
        guard let apiCooldownUntil else {
            return 0
        }
        return max(0, Int(ceil(apiCooldownUntil.timeIntervalSinceNow)))
    }

    var pendingOrderCount: Int {
        pendingOrders.filter { $0.status == .pendingReview || $0.status == .blocked }.count
    }

    var riskWarnings: [String] {
        var warnings: [String] = []
        if safetySettings.allowLiveOrders {
            warnings.append("라이브 주문 허용 상태입니다. 주문 전 계좌와 한도를 재확인하세요.")
        } else {
            warnings.append("라이브 주문은 잠겨 있습니다. 조건 충족 시 로그/알림까지만 수행됩니다.")
        }
        if strategies.contains(where: { $0.mode == .autoOrder && $0.isEnabled }) {
            warnings.append("완전 자동 전략이 켜져 있습니다.")
        }
        if safetySettings.requireMarketOrderConfirmation {
            warnings.append("시장가 주문은 추가 확인이 필요합니다.")
        }
        if connectionState == .demo {
            warnings.append("현재 데모 데이터 상태입니다.")
        }
        return warnings
    }

    var liveOrderReadinessWarnings: [String] {
        var warnings: [String] = []
        if !automationEnabled {
            warnings.append("자동매매 스위치가 꺼져 있어 조건을 감시하지 않습니다.")
        }
        if activeStrategyCount == 0 {
            warnings.append("켜진 매크로가 없습니다.")
        }
        if !strategies.contains(where: { $0.isEnabled && $0.mode == .autoOrder }) {
            warnings.append("완전 자동 모드로 켜진 매크로가 없습니다. 승인 후 주문은 직접 제출해야 합니다.")
        }
        if !safetySettings.allowLiveOrders {
            warnings.append("설정의 라이브 주문 허용이 꺼져 있습니다.")
        }
        if !credentials.isComplete {
            warnings.append("토스 API 키가 저장되지 않았습니다.")
        }
        if selectedAccountSeq == nil {
            warnings.append("실주문에 사용할 계좌가 선택되지 않았습니다.")
        }
        if isAPICoolingDown {
            warnings.append("요청 한도 대기 중이라 주문/감시가 지연됩니다.")
        }
        if case .failed(let message) = connectionState {
            warnings.append("API 상태 확인 필요: \(message)")
        }
        return warnings
    }

    func stockSuggestions(for query: String, limit: Int = 8) -> [StockSearchItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let matches = stockDirectory
            .filter { $0.matches(trimmed) }
            .sorted { left, right in
                if left.symbol == trimmed.uppercased() { return true }
                if right.symbol == trimmed.uppercased() { return false }
                return left.name < right.name
            }
        return Array(matches.prefix(limit))
    }

    func onlineStockSuggestions(for query: String, limit: Int = 8) async -> [StockSearchItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2, !isAIRunning else {
            return []
        }

        do {
            let items = try await yahooFinanceClient.search(query: trimmed, limit: limit)
            mergeStockSearchItems(items)
            return items
        } catch {
            return []
        }
    }

    private func mergeStockSearchItems(_ items: [StockSearchItem]) {
        for item in items {
            if let index = stockDirectory.firstIndex(where: { $0.symbol.caseInsensitiveCompare(item.symbol) == .orderedSame }) {
                stockDirectory[index].name = item.name
                stockDirectory[index].englishName = item.englishName
                stockDirectory[index].market = item.market
                stockDirectory[index].currency = item.currency
                for alias in item.aliases where !stockDirectory[index].aliases.contains(alias) {
                    stockDirectory[index].aliases.append(alias)
                }
            } else {
                stockDirectory.append(item)
            }
        }
    }

    func stockName(for symbol: String) -> String? {
        stockDirectory.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }?.name
    }

    func stockDisplayText(for symbol: String) -> String {
        if let item = stockDirectory.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
            return item.displayText
        }
        return symbol
    }

    func resolveSymbol(from input: String) -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return selectedSymbol
        }

        if let exact = stockDirectory.first(where: { item in
            item.symbol.caseInsensitiveCompare(trimmed) == .orderedSame ||
                item.name.caseInsensitiveCompare(trimmed) == .orderedSame ||
                item.englishName.caseInsensitiveCompare(trimmed) == .orderedSame ||
                item.aliases.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame })
        }) {
            return exact.symbol
        }

        let lowerText = trimmed.lowercased()
        if let mentioned = stockDirectory.first(where: { item in
            ([item.symbol, item.name, item.englishName] + item.aliases)
                .filter { !$0.isEmpty }
                .contains { lowerText.contains($0.lowercased()) }
        }) {
            return mentioned.symbol
        }

        if let partial = stockSuggestions(for: trimmed, limit: 1).first {
            return partial.symbol
        }

        return trimmed.uppercased()
    }

    func selectSymbol(from input: String) {
        selectedSymbol = resolveSymbol(from: input)
    }

    func addWatchedSymbol(from input: String) {
        let symbol = resolveSymbol(from: input)
        guard !symbol.isEmpty else {
            return
        }
        if !watchedSymbols.contains(where: { $0.caseInsensitiveCompare(symbol) == .orderedSame }) {
            watchedSymbols.append(symbol)
            saveAppState()
        }
    }

    func removeWatchedSymbol(_ symbol: String) {
        watchedSymbols.removeAll { $0.caseInsensitiveCompare(symbol) == .orderedSame }
        saveAppState()
    }

    func isWatchedSymbol(_ symbol: String) -> Bool {
        watchedSymbols.contains { $0.caseInsensitiveCompare(symbol) == .orderedSame }
    }

    func toggleWatchedSymbol(_ symbol: String) {
        if isWatchedSymbol(symbol) {
            removeWatchedSymbol(symbol)
        } else {
            addWatchedSymbol(from: symbol)
        }
    }

    func createPriceAlert(symbolInput: String, targetPrice: Double, condition: PriceAlertCondition) {
        let symbol = resolveSymbol(from: symbolInput)
        guard !symbol.isEmpty, targetPrice > 0 else {
            return
        }
        addWatchedSymbol(from: symbol)
        let alert = PriceAlert(
            symbol: symbol.uppercased(),
            name: stockName(for: symbol) ?? symbol.uppercased(),
            targetPrice: targetPrice,
            condition: condition,
            isEnabled: true,
            createdAt: Date(),
            expiresAt: Calendar.current.date(byAdding: .day, value: 90, to: Date()) ?? Date().addingTimeInterval(90 * 24 * 60 * 60),
            lastTriggeredAt: nil
        )
        priceAlerts.insert(alert, at: 0)
        appendOrderLog(
            symbol: alert.symbol,
            strategyName: "가격 알림",
            mode: .alertOnly,
            event: "\(alert.name) \(alert.conditionText) 알림을 만들었습니다.",
            aiReview: "AI 검토 없음",
            orderRequest: "주문 없음",
            result: "자동 감시가 켜져 있으면 1분마다 현재가를 확인합니다.",
            isLiveOrder: false
        )
        notifications.post(title: "가격 알림 생성", body: "\(alert.name): \(alert.conditionText)")
        saveAppState()
    }

    func removePriceAlert(_ alert: PriceAlert) {
        priceAlerts.removeAll { $0.id == alert.id }
        saveAppState()
    }

    func togglePriceAlert(_ alert: PriceAlert) {
        guard let index = priceAlerts.firstIndex(where: { $0.id == alert.id }) else {
            return
        }
        priceAlerts[index].isEnabled.toggle()
        saveAppState()
    }

    func loadCredentials() {
        if let encoded = keychain.read(account: credentialsKeychainAccount),
           let data = encoded.data(using: .utf8),
           let decoded = try? JSONDecoder().decode(Credentials.self, from: data) {
            credentials = decoded
            return
        }

        let legacy = Credentials(
            clientID: keychain.read(account: "clientID") ?? "",
            clientSecret: keychain.read(account: "clientSecret") ?? ""
        )
        credentials = legacy
        if legacy.isComplete {
            try? saveCredentials()
        }
    }

    func saveCredentials() throws {
        let data = try JSONEncoder().encode(credentials)
        guard let encoded = String(data: data, encoding: .utf8) else {
            throw KeychainError.unhandledStatus(errSecParam)
        }
        try keychain.save(encoded, account: credentialsKeychainAccount)
        keychain.delete(account: "clientID")
        keychain.delete(account: "clientSecret")
        loadCredentials()
    }

    func loadAppState() {
        guard let snapshot = store.load() else {
            return
        }
        watchedSymbols = snapshot.watchedSymbols
        priceAlerts = snapshot.priceAlerts
        strategies = snapshot.strategies
        orderLogs = snapshot.orderLogs
        pendingOrders = snapshot.pendingOrders
        selectedAccountSeq = snapshot.selectedAccountSeq
        safetySettings = snapshot.safetySettings
        autoRebalanceSettings = snapshot.autoRebalanceSettings
        tossCLISettings = snapshot.tossCLISettings
        investorProfile = snapshot.investorProfile
        aiEngines = snapshot.aiEngines
        aiResults = snapshot.aiResults
    }

    func saveAppState() {
        let snapshot = AppStorageSnapshot(
            watchedSymbols: watchedSymbols,
            priceAlerts: Array(priceAlerts.prefix(300)),
            strategies: strategies,
            orderLogs: Array(orderLogs.prefix(500)),
            pendingOrders: Array(pendingOrders.prefix(200)),
            selectedAccountSeq: selectedAccountSeq,
            safetySettings: safetySettings,
            autoRebalanceSettings: autoRebalanceSettings,
            tossCLISettings: tossCLISettings,
            investorProfile: investorProfile,
            aiEngines: aiEngines,
            aiResults: Array(aiResults.prefix(100))
        )
        try? store.save(snapshot)
    }

    func normalizeAIEngineCommands() {
        let defaults = MockData.aiEngines
        for defaultEngine in defaults where !aiEngines.contains(where: { $0.engine == defaultEngine.engine }) {
            aiEngines.append(defaultEngine)
        }

        if let index = aiEngines.firstIndex(where: { $0.engine == .codex }) {
            let command = aiEngines[index].analysisCommand
            if command.contains("codex exec"),
               (!command.contains("--skip-git-repo-check") || !command.contains("--output-last-message") || command.contains("status=$?") || command.contains("$status")) {
                aiEngines[index].analysisCommand = MockData.aiEngines.first { $0.engine == .codex }?.analysisCommand ?? command
                aiEngines[index].lastStatus = "코덱스 출력 정리 설정을 자동 보정했습니다."
            }
        }
        if let index = aiEngines.firstIndex(where: { $0.engine == .claude }) {
            let analysisCommand = aiEngines[index].analysisCommand
            let versionCommand = aiEngines[index].versionCommand
            if analysisCommand.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("claud ") ||
                analysisCommand.trimmingCharacters(in: .whitespacesAndNewlines) == "claud" {
                aiEngines[index].analysisCommand = analysisCommand.replacingOccurrences(of: #"^\s*claud\b"#, with: "claude", options: .regularExpression)
                aiEngines[index].lastStatus = "클로드 명령어 오타를 claude로 자동 보정했습니다."
            }
            if versionCommand.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("claud ") ||
                versionCommand.trimmingCharacters(in: .whitespacesAndNewlines) == "claud" {
                aiEngines[index].versionCommand = versionCommand.replacingOccurrences(of: #"^\s*claud\b"#, with: "claude", options: .regularExpression)
            }
        }
        saveAppState()
    }

    func refreshSelectedSectionIfNeeded(force: Bool = false) async {
        await refreshSectionIfNeeded(selectedSection, force: force)
    }

    func refreshSectionIfNeeded(_ section: SidebarSection, force: Bool = false) async {
        let key = section.rawValue
        guard !sectionRefreshesInFlight.contains(key) else {
            return
        }
        if isAIRunning, !force {
            return
        }

        let now = Date()
        if !force,
           let last = sectionRefreshTimestamps[key],
           now.timeIntervalSince(last) < sectionRefreshInterval(for: section) {
            return
        }

        sectionRefreshesInFlight.insert(key)
        sectionRefreshTimestamps[key] = now
        defer {
            sectionRefreshesInFlight.remove(key)
        }

        switch section {
        case .dashboard:
            await refreshMarketData()
        case .strategyManager:
            await refreshMarketData()
        case .aiAnalysis:
            await refreshMarketData()
        case .market:
            await refreshMarketActivity()
        case .watchlist:
            await refreshMarketData()
        case .account:
            await refreshAccounts()
            await refreshHoldings()
            await refreshMarketData()
        case .orderLog, .settings:
            break
        }
    }

    private func sectionRefreshInterval(for section: SidebarSection) -> TimeInterval {
        switch section {
        case .dashboard:
            return 60
        case .strategyManager, .aiAnalysis:
            return 90
        case .market, .watchlist, .account:
            return 120
        case .orderLog, .settings:
            return 120
        }
    }

    func setAutomationEnabled(_ enabled: Bool) {
        automationEnabled = enabled
        lastAutomationDecision = enabled ? "감시 시작: 아직 조건을 평가하지 않았습니다." : "자동 감시가 꺼져 있습니다."
        notifications.post(
            title: enabled ? "자동매매 감시 시작" : "자동매매 감시 중지",
            body: enabled ? "1분마다 시세와 분봉을 확인해 조건 충족 여부를 감시합니다." : "자동 감시 루프를 멈췄습니다."
        )
        saveAppState()
    }

    func runAutomationScan() async {
        guard automationEnabled, !isAutomationScanRunning else {
            return
        }
        guard activeStrategyCount > 0 || activePriceAlertCount > 0 else {
            lastAutomationDecision = "켜진 매크로와 가격 알림이 없어 감시하지 않습니다."
            return
        }
        isAutomationScanRunning = true
        lastAutomationScanAt = Date()
        lastAutomationDecision = "감시 중: 활성 매크로 \(activeStrategyCount)개, 가격 알림 \(activePriceAlertCount)개를 확인합니다."
        defer {
            isAutomationScanRunning = false
            nextAutomationScanAt = automationEnabled ? Date().addingTimeInterval(automationScanIntervalSeconds) : nil
        }
        await runAutoRebalanceIfNeeded()
        await refreshAutomationMarketData()
    }

    func refreshMarketData() async {
        guard canUseAPI() else {
            return
        }
        guard !isMarketRefreshRunning else {
            return
        }
        isMarketRefreshRunning = true
        defer {
            isMarketRefreshRunning = false
        }

        guard credentials.isComplete else {
            connectionState = .demo
            for symbol in marketDataSymbols() {
                let demoPrice = MockData.demoPrice(for: symbol)
                if let index = prices.firstIndex(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
                    prices[index] = demoPrice
                } else {
                    prices.insert(demoPrice, at: 0)
                }
            }
            candles = MockData.demoCandles(for: selectedSymbol, timeframe: chartTimeframe)
            candleCacheKey = candleRequestKey(symbol: selectedSymbol, timeframe: chartTimeframe)
            let strategyCandles = chartTimeframe.isMinute ? [selectedSymbol.uppercased(): candles] : [:]
            evaluateStrategies(candlesBySymbol: strategyCandles)
            return
        }

        connectionState = .loading

        do {
            let accessToken = try await validAccessToken()
            let symbols = marketDataSymbols()
            let selectedSymbolSnapshot = selectedSymbol
            let timeframeSnapshot = chartTimeframe
            let cacheKey = candleRequestKey(symbol: selectedSymbolSnapshot, timeframe: timeframeSnapshot)
            let reusableCandles = candleCacheKey == cacheKey ? candles : []
            let fetchedPrices = try await client.prices(symbols: symbols, accessToken: accessToken)
            let unknownSymbols = symbols.filter { symbol in
                !stockDirectory.contains { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
            }
            if !unknownSymbols.isEmpty,
               let stocks = try? await client.stocks(symbols: unknownSymbols, accessToken: accessToken) {
                mergeStockInfos(stocks)
            }
            let fetchedCandles = try await fetchCandles(
                symbol: selectedSymbolSnapshot,
                interval: timeframeSnapshot.apiInterval,
                targetCount: timeframeSnapshot.candleCount,
                existingCandles: reusableCandles,
                accessToken: accessToken
            )
            let fetchedOrderbook = try await client.orderbook(symbol: selectedSymbolSnapshot, accessToken: accessToken)

            prices = fetchedPrices
            candles = fetchedCandles
            candleCacheKey = cacheKey
            orderbook = fetchedOrderbook
            if timeframeSnapshot.isMinute {
                strategyCandleCache[automationCandleCacheKey(symbol: selectedSymbolSnapshot)] = fetchedCandles
            }
            apiCooldownUntil = nil
            connectionState = .live(Date())
            let strategyCandles = timeframeSnapshot.isMinute ? [selectedSymbolSnapshot.uppercased(): fetchedCandles] : [:]
            evaluateStrategies(candlesBySymbol: strategyCandles)
        } catch {
            handleAPIError(error)
        }
    }

    private func refreshAutomationMarketData() async {
        guard canUseAPI() else {
            return
        }
        guard !isMarketRefreshRunning else {
            return
        }
        isMarketRefreshRunning = true
        defer {
            isMarketRefreshRunning = false
        }

        let symbols = marketDataSymbols()
        let mechanicalSymbols = mechanicalStrategySymbols()

        guard credentials.isComplete else {
            connectionState = .demo
            for symbol in symbols {
                let demoPrice = MockData.demoPrice(for: symbol)
                if let index = prices.firstIndex(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
                    prices[index] = demoPrice
                } else {
                    prices.insert(demoPrice, at: 0)
                }
            }

            var candlesBySymbol: [String: [Candle]] = [:]
            for symbol in mechanicalSymbols {
                let demoCandles = MockData.demoCandles(for: symbol, timeframe: .oneMinuteExtended)
                let normalized = symbol.uppercased()
                strategyCandleCache[automationCandleCacheKey(symbol: normalized)] = demoCandles
                candlesBySymbol[normalized] = demoCandles
            }
            evaluateStrategies(candlesBySymbol: candlesBySymbol)
            return
        }

        connectionState = .loading

        do {
            let accessToken = try await validAccessToken()
            prices = try await client.prices(symbols: symbols, accessToken: accessToken)

            var candlesBySymbol: [String: [Candle]] = [:]
            for symbol in mechanicalSymbols {
                let normalized = symbol.uppercased()
                let cacheKey = automationCandleCacheKey(symbol: normalized)
                let cachedCandles = strategyCandleCache[cacheKey] ?? []
                if !candlesBySymbol.isEmpty {
                    try await Task.sleep(nanoseconds: 400_000_000)
                }
                let fetchedCandles = try await fetchCandles(
                    symbol: normalized,
                    interval: ChartTimeframe.oneMinuteExtended.apiInterval,
                    targetCount: ChartTimeframe.oneMinuteExtended.candleCount,
                    existingCandles: cachedCandles,
                    accessToken: accessToken
                )
                strategyCandleCache[cacheKey] = fetchedCandles
                candlesBySymbol[normalized] = fetchedCandles
            }

            apiCooldownUntil = nil
            connectionState = .live(Date())
            evaluateStrategies(candlesBySymbol: candlesBySymbol)
        } catch {
            handleAPIError(error)
        }
    }

    private func candleRequestKey(symbol: String, timeframe: ChartTimeframe) -> String {
        "\(symbol.uppercased())|\(timeframe.rawValue)"
    }

    private func fetchCandles(
        symbol: String,
        interval: String,
        targetCount: Int,
        existingCandles: [Candle] = [],
        accessToken: String
    ) async throws -> [Candle] {
        let apiPageLimit = 200
        let maxPages = candlePageBudget(targetCount: targetCount, existingCount: existingCandles.count)
        var before: String?
        var merged: [Candle] = []
        var seen = Set<String>()
        var requestedPages = 0

        func appendUnique(_ newCandles: [Candle]) {
            for candle in newCandles where !seen.contains(candle.timestamp) {
                seen.insert(candle.timestamp)
                merged.append(candle)
            }
        }

        while merged.count < targetCount, requestedPages < maxPages {
            let remaining = targetCount - merged.count
            let pageCount = min(remaining, apiPageLimit)
            if requestedPages > 0 {
                try await Task.sleep(nanoseconds: 400_000_000)
            }
            let page = try await client.candles(
                symbol: symbol,
                interval: interval,
                count: pageCount,
                before: before,
                accessToken: accessToken
            )
            requestedPages += 1

            appendUnique(page.candles)

            if before == nil, !existingCandles.isEmpty {
                appendUnique(existingCandles)
                if merged.count >= targetCount {
                    break
                }
                if let earliest = existingCandles.min(by: { $0.date < $1.date }) {
                    before = earliest.timestamp
                    continue
                }
            }

            guard page.candles.count == pageCount,
                  let nextBefore = page.nextBefore,
                  nextBefore != before else {
                break
            }
            before = nextBefore
        }

        return Array(merged.sorted { $0.date < $1.date }.suffix(targetCount))
    }

    private func candlePageBudget(targetCount: Int, existingCount: Int) -> Int {
        if targetCount <= 200 {
            return 1
        }
        if existingCount <= 0 {
            return 1
        }
        if existingCount >= targetCount {
            return 1
        }
        return 2
    }

    private func canUseAPI() -> Bool {
        guard let apiCooldownUntil else {
            return true
        }

        if apiCooldownUntil <= Date() {
            self.apiCooldownUntil = nil
            return true
        }

        connectionState = .failed("요청 한도 대기 중입니다. \(apiCooldownRemainingSeconds)초 후 다시 시도하세요.")
        return false
    }

    private func handleAPIError(_ error: Error) {
        if let clientError = error as? TossInvestClientError,
           case let .rateLimited(_, retryAfterSeconds) = clientError {
            let seconds = max(10, retryAfterSeconds ?? 60)
            apiCooldownUntil = Date().addingTimeInterval(TimeInterval(seconds))
            connectionState = .failed("요청 한도를 초과했습니다. \(seconds)초 후 다시 시도하세요.")
            if automationEnabled {
                nextAutomationScanAt = apiCooldownUntil
            }
            return
        }

        connectionState = .failed(error.localizedDescription)
        if safetySettings.haltOnAPIError {
            automationEnabled = false
        }
    }

    func refreshMarketActivity() async {
        guard !isMarketActivityRefreshRunning else {
            return
        }
        isMarketActivityRefreshRunning = true
        defer {
            isMarketActivityRefreshRunning = false
        }

        let publicRankings = await fetchPublicDomesticRankings()
        let domesticRankings = publicRankings.rows
        let overseasRankings = await fetchPublicOverseasRankings()
        let externalRankings = mergedMarketActivities(primary: domesticRankings, secondary: overseasRankings)
        mergeMarketActivityStockInfos(externalRankings)

        let usesDemoFallback = externalRankings.isEmpty
        marketActivities = usesDemoFallback ? demoMarketActivitiesFromDirectory() : externalRankings
        marketActivitySourceText = marketActivitySourceDescription(
            source: publicRankings.source,
            externalCount: domesticRankings.count,
            overseasCount: overseasRankings.count,
            candidateCount: 0,
            usesOfficialCandidates: false,
            usesDemoFallback: usesDemoFallback
        )
        updateMarketActivityQuality(
            source: publicRankings.source,
            rows: domesticRankings,
            externalCount: domesticRankings.count,
            usesOfficialCandidates: false,
            usesDemoFallback: usesDemoFallback
        )
    }

    private func fetchPublicDomesticRankings() async -> (source: PublicDomesticRankingSource, rows: [MarketActivitySnapshot]) {
        if let cache = publicDomesticRankingCache,
           Date().timeIntervalSince(cache.updatedAt) < 300 {
            return (cache.source, cache.rows)
        }

        do {
            let rankings = try await naverRankingClient.tradeValueRanking(limit: 700, maxPagesPerCategory: 4)
            if !rankings.isEmpty {
                publicDomesticRankingCache = (Date(), .naver, rankings)
                return (.naver, rankings)
            }
        } catch {
            // Fall back to the smaller NXT public ranking below.
        }

        do {
            let rankings = try await nextradeClient.tradeValueRanking(stockDirectory: stockDirectory)
            let filtered = rankings.filter { !$0.symbol.hasPrefix("NXT-") }
            if !filtered.isEmpty {
                publicDomesticRankingCache = (Date(), .nextrade, filtered)
                return (.nextrade, filtered)
            }
        } catch {
            return (.none, [])
        }

        return (.none, [])
    }

    private func fetchPublicOverseasRankings() async -> [MarketActivitySnapshot] {
        if let cache = publicOverseasRankingCache,
           Date().timeIntervalSince(cache.updatedAt) < 300 {
            return cache.rows
        }

        do {
            let rankings = try await yahooFinanceClient.marketActivityRanking(limit: 180)
            if !rankings.isEmpty {
                publicOverseasRankingCache = (Date(), rankings)
                return rankings
            }
        } catch {
            return []
        }

        return []
    }

    private func mergeMarketActivityStockInfos(_ rows: [MarketActivitySnapshot]) {
        for row in rows {
            guard !row.symbol.hasPrefix("NXT-") else {
                continue
            }

            if let index = stockDirectory.firstIndex(where: { $0.symbol.caseInsensitiveCompare(row.symbol) == .orderedSame }) {
                stockDirectory[index].name = row.name
                stockDirectory[index].englishName = row.englishName
                stockDirectory[index].market = row.market
                stockDirectory[index].currency = row.currency
                if !stockDirectory[index].aliases.contains(row.name) {
                    stockDirectory[index].aliases.append(row.name)
                }
            } else {
                stockDirectory.append(
                    StockSearchItem(
                        symbol: row.symbol,
                        name: row.name,
                        englishName: row.englishName,
                        market: row.market,
                        currency: row.currency,
                        aliases: [row.name, row.englishName]
                    )
                )
            }
        }
    }

    private func mergedMarketActivities(
        primary: [MarketActivitySnapshot],
        secondary: [MarketActivitySnapshot]
    ) -> [MarketActivitySnapshot] {
        var seen = Set<String>()
        var merged: [MarketActivitySnapshot] = []

        for row in primary + secondary {
            let key = row.symbol.uppercased()
            guard !seen.contains(key) else {
                continue
            }
            seen.insert(key)
            merged.append(row)
        }

        return merged
    }

    private func marketActivitySourceDescription(
        source: PublicDomesticRankingSource,
        externalCount: Int,
        overseasCount: Int = 0,
        candidateCount: Int,
        usesOfficialCandidates: Bool,
        usesDemoFallback: Bool
    ) -> String {
        if externalCount > 0 {
            var parts: [String]
            switch source {
            case .naver:
                parts = [
                    "시세 탭은 토스 API를 사용하지 않습니다.",
                    "국내장은 네이버 모바일 공개 시세에서 KOSPI/KOSDAQ 주요 종목을 페이징 조회한 뒤 거래대금순 상위 \(externalCount)개를 사용합니다.",
                    "거래대금은 네이버 누적 거래대금 값을 원화로 환산합니다."
                ]
            case .nextrade:
                parts = [
                    "시세 탭은 토스 API를 사용하지 않습니다.",
                    "국내장은 넥스트레이드 공개 거래대금 상위 \(externalCount)개를 우선 사용합니다.",
                    "NXT 정규시장 체결 기준이며 약 20분 지연될 수 있습니다."
                ]
            case .none:
                parts = [
                    "시세 탭은 토스 API를 사용하지 않습니다.",
                    "국내 공개 거래대금 랭킹을 가져오지 못해 앱 후보 데이터를 사용합니다."
                ]
            }
            if usesOfficialCandidates {
                parts.append("그 밖의 후보 \(candidateCount)개는 공개 시세 후보의 현재가 x 거래량으로 계산합니다.")
            }
            if usesDemoFallback {
                parts.append("공개 데이터가 비어 있는 범위는 앱 기본 후보로만 채웁니다.")
            }
            if overseasCount > 0 {
                parts.append("해외장은 Yahoo Finance 공개 스크리너에서 거래활발/급등/급락 종목 \(overseasCount)개를 함께 가져옵니다.")
            }
            return parts.joined(separator: " ")
        }

        if overseasCount > 0 {
            var parts = [
                "시세 탭은 토스 API를 사용하지 않습니다.",
                "국내 공개 거래대금 랭킹은 가져오지 못했지만, 해외장은 Yahoo Finance 공개 스크리너에서 거래활발/급등/급락 종목 \(overseasCount)개를 가져옵니다."
            ]
            if usesDemoFallback {
                parts.append("공개 데이터가 비어 있는 범위는 앱 기본 후보로만 채웁니다.")
            }
            return parts.joined(separator: " ")
        }

        if usesOfficialCandidates {
            let base = "공개 거래대금 랭킹을 가져오지 못해 앱 후보 \(candidateCount)개를 현재가 x 거래량으로 계산합니다. 전체 시장 거래대금 Top100은 아닙니다."
            if tossCLISettings.isEnabled {
                return "\(base) tossctl은 토스 웹 인기순위 후보 보강용이며 거래대금 Top100 원본으로 쓰지 않습니다."
            }
            return base
        }

        return "시세 탭은 토스 API를 사용하지 않습니다. 공개 시장 데이터를 가져오지 못해 데모 예시 데이터를 표시합니다."
    }

    private func updateMarketActivityQuality(
        source: PublicDomesticRankingSource,
        rows: [MarketActivitySnapshot],
        externalCount: Int,
        usesOfficialCandidates: Bool,
        usesDemoFallback: Bool
    ) {
        latestPublicDomesticRankingSource = source
        let validation = tradeValueValidation(rows: rows)

        if source == .naver, externalCount >= 50, !usesDemoFallback, validation.passed {
            marketActivityAllowsAutoSelection = true
            let gapText = formattedDouble(validation.medianGapPercent, fractionDigits: 1)
            marketActivityQualityText = "데이터 검증 통과: 국내 자동선택은 네이버 KOSPI/KOSDAQ 전 종목 거래대금 기반입니다. 가격x거래량 검산 \(validation.sampleCount)개, 중앙오차 \(gapText)%."
            marketActivitySourceText = "\(marketActivitySourceText) \(marketActivityQualityText)"
            return
        }

        marketActivityAllowsAutoSelection = false
        let reason: String
        switch source {
        case .naver:
            if externalCount < 50 {
                reason = "네이버 거래대금 표본이 \(externalCount)개로 부족합니다."
            } else if !validation.passed {
                let gapText = formattedDouble(validation.medianGapPercent, fractionDigits: 1)
                reason = "거래대금 검산을 통과하지 못했습니다. 표본 \(validation.sampleCount)개, 중앙오차 \(gapText)%."
            } else {
                reason = "자동선택 데이터 조건을 모두 만족하지 못했습니다."
            }
        case .nextrade:
            reason = "NXT 공개 표는 상위 일부 종목만 제공되어 자동선택용 전체 랭킹으로 쓰지 않습니다."
        case .none:
            reason = usesOfficialCandidates
                ? "토스 후보군 계산은 전체 시장 거래대금 순위가 아니라 자동선택을 막았습니다."
                : "검증된 공개 거래대금 랭킹을 가져오지 못했습니다."
        }

        marketActivityQualityText = "국내 자동선택 차단: \(reason)"
        marketActivitySourceText = "\(marketActivitySourceText) \(marketActivityQualityText)"
    }

    private func tradeValueValidation(rows: [MarketActivitySnapshot]) -> (passed: Bool, sampleCount: Int, medianGapPercent: Double) {
        let gaps = rows
            .filter(\.isDomestic)
            .prefix(30)
            .compactMap { row -> Double? in
                guard let volume = row.tradeVolume,
                      let value = row.tradeValue else {
                    return nil
                }
                let lastPrice = NSDecimalNumber(decimal: row.lastPriceValue).doubleValue
                let tradeVolume = NSDecimalNumber(decimal: volume).doubleValue
                let reportedValue = NSDecimalNumber(decimal: value).doubleValue
                let impliedValue = lastPrice * tradeVolume
                guard lastPrice > 0,
                      tradeVolume > 0,
                      reportedValue > 0,
                      impliedValue > 0 else {
                    return nil
                }
                return abs(reportedValue - impliedValue) / max(reportedValue, 1) * 100
            }
            .sorted()

        guard !gaps.isEmpty else {
            return (false, 0, 100)
        }

        let median = gaps[gaps.count / 2]
        return (gaps.count >= 20 && median <= 25, gaps.count, median)
    }

    func marketActivityAutomationBlockReason(scope: MarketScope) -> String? {
        if scope == .overseas {
            let hasOverseasRanking = marketActivities.contains { row in
                !row.isDomestic &&
                    row.tradeValue != nil &&
                    row.tradeVolume != nil &&
                    row.changePercent != nil
            }
            return hasOverseasRanking
                ? nil
                : "해외장 공개 스크리너 데이터를 아직 가져오지 못했습니다. 시세 탭을 새로고침한 뒤 다시 시도하세요."
        }
        guard marketActivityAllowsAutoSelection else {
            return marketActivityQualityText
        }
        guard latestPublicDomesticRankingSource == .naver else {
            return "네이버 전 종목 거래대금 검증을 통과하지 못해 자동선택을 막았습니다."
        }
        return nil
    }

    private func importTossCLIRankingIfEnabled(force: Bool = false) async {
        guard tossCLISettings.isEnabled else {
            tossCLIDiscoveryStatus = "tossctl 후보 보강 꺼짐"
            return
        }
        if !force,
           let lastTossCLIRankingImportAt,
           Date().timeIntervalSince(lastTossCLIRankingImportAt) < 300 {
            return
        }

        lastTossCLIRankingImportAt = Date()
        let size = max(1, min(tossCLISettings.rankingSize, 100))
        do {
            let output = try await runTossCLI(arguments: [
                "--output", "json",
                "market", "ranking",
                "--size", "\(size)"
            ])
            guard let data = output.data(using: .utf8) else {
                tossCLIDiscoveryStatus = "tossctl 출력 인코딩을 읽지 못했습니다."
                return
            }
            let ranking = try JSONDecoder().decode(TossCLIRankingResponse.self, from: data)
            let imported = mergeTossCLIRankedStocks(ranking.stocks)
            tossCLIDiscoveryStatus = imported > 0
                ? "tossctl 인기순위 \(imported)개를 후보 풀에 반영했습니다. 거래대금 순위 원본은 아닙니다."
                : "tossctl 인기순위에서 반영할 종목이 없었습니다. 거래대금 순위 원본은 아닙니다."
        } catch {
            tossCLIDiscoveryStatus = "tossctl 후보 보강 실패: \(error.localizedDescription)"
        }
    }

    private func runTossCLI(arguments: [String]) async throws -> String {
        let command = tossCLISettings.commandPath.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !command.isEmpty else {
            throw TossCLIIntegrationError.emptyCommand
        }

        return try await Task.detached(priority: .utility) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [command] + arguments
            process.environment = commandEnvironmentWithCLIPaths()

            let output = Pipe()
            let error = Pipe()
            process.standardOutput = output
            process.standardError = error

            try process.run()
            process.waitUntilExit()

            let outputData = output.fileHandleForReading.readDataToEndOfFile()
            let errorData = error.fileHandleForReading.readDataToEndOfFile()
            let standardOutput = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let standardError = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            guard process.terminationStatus == 0 else {
                throw TossCLIIntegrationError.executionFailed(process.terminationStatus, standardError.isEmpty ? standardOutput : standardError)
            }
            return standardOutput
        }.value
    }

    @discardableResult
    private func mergeTossCLIRankedStocks(_ stocks: [TossCLIRankedStock]) -> Int {
        var imported = 0
        for stock in stocks {
            let symbol = normalizedTossCLISymbol(stock)
            guard !symbol.isEmpty else {
                continue
            }

            let name = stock.name?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? symbol
            let market = stock.market?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? inferredMarket(symbol: symbol, productCode: stock.productCode)
            let currency = inferredCurrency(symbol: symbol, market: market, productCode: stock.productCode)
            let aliases = [
                "tossctl",
                "토스 인기순위",
                "인기순위 \(stock.rank)"
            ]

            if let index = stockDirectory.firstIndex(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
                stockDirectory[index].name = name
                stockDirectory[index].market = market
                stockDirectory[index].currency = currency
                for alias in aliases where !stockDirectory[index].aliases.contains(alias) {
                    stockDirectory[index].aliases.append(alias)
                }
            } else {
                stockDirectory.append(
                    StockSearchItem(
                        symbol: symbol,
                        name: name,
                        englishName: name,
                        market: market,
                        currency: currency,
                        aliases: aliases
                    )
                )
            }
            imported += 1
        }
        return imported
    }

    private func normalizedTossCLISymbol(_ stock: TossCLIRankedStock) -> String {
        if let symbol = stock.symbol?.trimmingCharacters(in: .whitespacesAndNewlines),
           !symbol.isEmpty {
            return symbol.uppercased()
        }

        let code = stock.productCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if code.count == 7, code.hasPrefix("A") {
            return String(code.dropFirst())
        }
        if code.count == 6, code.allSatisfy(\.isNumber) {
            return code
        }
        return code
    }

    private func inferredCurrency(symbol: String, market: String, productCode: String) -> String {
        let upperMarket = market.uppercased()
        let upperCode = productCode.uppercased()
        if symbol.count == 6, symbol.allSatisfy(\.isNumber) {
            return "KRW"
        }
        if upperCode.hasPrefix("A"), upperCode.dropFirst().allSatisfy(\.isNumber) {
            return "KRW"
        }
        if upperMarket.contains("KOSPI") || upperMarket.contains("KOSDAQ") || upperMarket.contains("코스피") || upperMarket.contains("코스닥") {
            return "KRW"
        }
        return "USD"
    }

    private func inferredMarket(symbol: String, productCode: String) -> String {
        inferredCurrency(symbol: symbol, market: "", productCode: productCode) == "KRW" ? "KR" : "US"
    }

    private func demoMarketActivitiesFromDirectory() -> [MarketActivitySnapshot] {
        stockDirectory.enumerated().map { index, item in
            let price = MockData.demoPrice(for: item.symbol)
            let baseVolume = item.currency == "KRW"
                ? Decimal(max(700_000, 18_000_000 - index * 520_000))
                : Decimal(max(500_000, 52_000_000 - index * 1_250_000))
            let tradeValue = price.lastPriceValue * baseVolume
            return MarketActivitySnapshot(
                symbol: item.symbol,
                name: item.name,
                englishName: item.englishName,
                market: item.market,
                currency: item.currency,
                lastPrice: price.lastPrice,
                timestamp: nil,
                tradeVolume: baseVolume,
                tradeValue: tradeValue,
                tradeSampleCount: 0,
                updatedAt: Date()
            )
        }
    }

    func scanAutoAllocationCandidates(
        budgetPerPosition: Double,
        scope: MarketScope,
        maxSymbols: Int,
        maxResults: Int
    ) async -> [AutoAllocationCandidate] {
        let scanCount = max(1, min(maxSymbols, 20))
        let resultCount = max(1, min(maxResults, scanCount))

        if marketActivitiesNeedRefresh {
            await refreshMarketActivity()
        }

        guard marketActivityAutomationBlockReason(scope: scope) == nil else {
            return []
        }

        let rows = rankedAutoAllocationUniverse(scope: scope, limit: scanCount)
        guard !rows.isEmpty else {
            return []
        }

        guard credentials.isComplete else {
            return rows.compactMap { row in
                let candles = MockData.demoCandles(for: row.symbol, timeframe: .oneMinuteExtended)
                return autoAllocationCandidate(
                    row: row,
                    candles: candles,
                    budgetPerPosition: budgetPerPosition
                )
            }
            .sorted { $0.trendScore > $1.trendScore }
            .prefix(resultCount)
            .map { $0 }
        }

        do {
            let accessToken = try await validAccessToken()
            var results: [AutoAllocationCandidate] = []
            for row in rows {
                if !results.isEmpty {
                    try await Task.sleep(nanoseconds: 450_000_000)
                }
                let cacheKey = automationCandleCacheKey(symbol: row.symbol)
                let cachedCandles = strategyCandleCache[cacheKey] ?? []
                let candles = try await fetchCandles(
                    symbol: row.symbol,
                    interval: ChartTimeframe.oneMinuteExtended.apiInterval,
                    targetCount: 240,
                    existingCandles: cachedCandles,
                    accessToken: accessToken
                )
                strategyCandleCache[cacheKey] = candles
                if let candidate = autoAllocationCandidate(
                    row: row,
                    candles: candles,
                    budgetPerPosition: budgetPerPosition
                ) {
                    results.append(candidate)
                }
            }
            apiCooldownUntil = nil
            connectionState = .live(Date())
            return Array(results.sorted { $0.trendScore > $1.trendScore }.prefix(resultCount))
        } catch {
            handleAPIError(error)
            return []
        }
    }

    func runAutoRebalanceNow() async {
        await runAutoRebalance(force: true)
    }

    private func runAutoRebalanceIfNeeded() async {
        await runAutoRebalance(force: false)
    }

    private func runAutoRebalance(force: Bool) async {
        guard !isAutoRebalancing else {
            return
        }
        guard autoRebalanceSettings.isEnabled || force else {
            return
        }
        if !force, let last = autoRebalanceSettings.lastRebalancedAt {
            let interval = TimeInterval(max(1, autoRebalanceSettings.intervalMinutes) * 60)
            guard Date().timeIntervalSince(last) >= interval else {
                return
            }
        }

        isAutoRebalancing = true
        lastAutoRebalanceMessage = "자동 리밸런싱 중..."
        defer {
            isAutoRebalancing = false
        }

        if credentials.isComplete {
            if selectedAccountSeq == nil {
                await refreshAccounts()
            }
            if selectedAccountSeq != nil {
                await refreshHoldings()
            }
        }

        let picks = max(1, min(autoRebalanceSettings.pickCount, 8))
        let scanLimit = max(picks, min(autoRebalanceSettings.scanLimit, 20))
        let budgetPerPosition = max(0, autoRebalanceSettings.budget) / Double(picks)
        let candidates = await scanAutoAllocationCandidates(
            budgetPerPosition: budgetPerPosition,
            scope: autoRebalanceSettings.scope,
            maxSymbols: scanLimit,
            maxResults: picks
        )

        let selected = candidates
            .filter { $0.trendScore >= autoRebalanceSettings.minimumScore }
            .prefix(picks)
        guard !selected.isEmpty else {
            var updatedSettings = autoRebalanceSettings
            updatedSettings.lastRebalancedAt = Date()
            autoRebalanceSettings = updatedSettings
            lastAutoRebalanceMessage = "조건을 넘는 후보가 없어 기존 자동선택 매크로를 유지했습니다."
            appendOrderLog(
                symbol: "AUTO",
                strategyName: "자동 리밸런싱",
                mode: .alertOnly,
                event: "자동 후보 재검토",
                aiReview: "AI 검토 없음",
                orderRequest: "주문 제출 없음",
                result: lastAutoRebalanceMessage,
                isLiveOrder: false
            )
            saveAppState()
            return
        }

        applyAutoRebalance(candidates: Array(selected))
    }

    private func applyAutoRebalance(candidates: [AutoAllocationCandidate]) {
        let selectedSymbols = Set(candidates.map { $0.symbol.uppercased() })
        var created = 0
        var updated = 0
        var disabled = 0
        var exitDrafts = 0

        for candidate in candidates {
            let referencePrice = NSDecimalNumber(decimal: decimalValue(candidate.lastPrice)).doubleValue
            let stopTake = autoManagedStopTake(for: candidate.template)
            let strategy = autoManagedStrategy(
                candidate: candidate,
                referencePrice: referencePrice,
                stopLoss: stopTake.stopLoss,
                takeProfit: stopTake.takeProfit
            )

            if let index = strategies.firstIndex(where: {
                isAutoManagedStrategy($0) && $0.symbol.caseInsensitiveCompare(candidate.symbol) == .orderedSame
            }) {
                strategies[index].name = strategy.name
                strategies[index].isEnabled = true
                strategies[index].mode = strategy.mode
                strategies[index].referencePrice = strategy.referencePrice
                strategies[index].maxDailyAmount = strategy.maxDailyAmount
                strategies[index].stopLossPercent = strategy.stopLossPercent
                strategies[index].takeProfitPercent = strategy.takeProfitPercent
                strategies[index].cooldownMinutes = strategy.cooldownMinutes
                strategies[index].conditions = strategy.conditions
                strategies[index].updatedAt = Date()
                strategies[index].riskNotes = strategy.riskNotes
                updated += 1
            } else {
                strategies.insert(strategy, at: 0)
                created += 1
            }
        }

        for index in strategies.indices where isAutoManagedStrategy(strategies[index]) {
            guard !selectedSymbols.contains(strategies[index].symbol.uppercased()) else {
                continue
            }
            if strategies[index].isEnabled {
                strategies[index].isEnabled = false
                disabled += 1
                if createAutoRebalanceExitDraft(for: strategies[index]) {
                    exitDrafts += 1
                }
            }
            strategies[index].updatedAt = Date()
            strategies[index].riskNotes = "\(strategies[index].riskNotes)\n리밸런싱 제외: 더 높은 후보가 나와 자동 감시를 껐습니다."
        }

        var updatedSettings = autoRebalanceSettings
        updatedSettings.lastRebalancedAt = Date()
        autoRebalanceSettings = updatedSettings
        let downgradedCount = candidates.filter { !$0.allowsAutoOrder }.count
        lastAutoRebalanceMessage = "후보 \(candidates.count)개 반영: \(created)개 추가, \(updated)개 갱신, \(disabled)개 제외, 매도 후보 \(exitDrafts)개\(downgradedCount > 0 ? ", 승인필요 \(downgradedCount)개" : "")"
        appendOrderLog(
            symbol: "AUTO",
            strategyName: "자동 리밸런싱",
            mode: autoRebalanceSettings.operationMode,
            event: "자동선택 후보를 주기적으로 갱신했습니다.",
            aiReview: "AI 검토 없음",
            orderRequest: candidates.map { "\($0.symbol) \($0.template.title) 점수 \(formattedDouble($0.trendScore, fractionDigits: 0)) · \($0.berkshireVerdict)" }.joined(separator: " / "),
            result: lastAutoRebalanceMessage,
            isLiveOrder: false
        )
        notifications.post(title: "자동 리밸런싱 완료", body: lastAutoRebalanceMessage)
        saveAppState()
    }

    private func autoManagedStrategy(
        candidate: AutoAllocationCandidate,
        referencePrice: Double,
        stopLoss: Double,
        takeProfit: Double
    ) -> TradingStrategy {
        let orderAmount = autoManagedOrderAmount(candidate: candidate, referencePrice: referencePrice)
        let requestedMode = autoRebalanceSettings.operationMode
        let effectiveMode: OperationMode = requestedMode == .autoOrder && !candidate.allowsAutoOrder
            ? .confirmBeforeOrder
            : requestedMode
        return TradingStrategy(
            name: "\(candidate.name) 자동 선택 \(candidate.template.title)",
            symbol: candidate.symbol,
            isEnabled: true,
            mode: effectiveMode,
            referencePrice: referencePrice,
            maxDailyAmount: orderAmount,
            stopLossPercent: stopLoss,
            takeProfitPercent: takeProfit,
            cooldownMinutes: candidate.template == .koquantMinuteMomentum ? 1 : 5,
            conditions: orderAmount > 0 ? autoManagedConditions(
                template: candidate.template,
                amount: orderAmount,
                referencePrice: referencePrice
            ) : [],
            createdAt: Date(),
            updatedAt: Date(),
            riskNotes: """
            AUTO_PICK_MANAGED
            자동 리밸런싱 후보: 점수 \(formattedDouble(candidate.trendScore, fractionDigits: 0))점, \(candidate.reason)
            \(candidate.berkshireGuardText)
            계좌 반영 주문예산: \(formattedDouble(orderAmount, fractionDigits: 0)) \(candidate.currency == "KRW" ? "원" : "원화 예산")
            실행 모드: \(effectiveMode.title)\(effectiveMode != requestedMode ? " (Berkshire Guard 때문에 자동주문에서 낮춤)" : "")
            """
        )
    }

    private func autoManagedOrderAmount(candidate: AutoAllocationCandidate, referencePrice: Double) -> Double {
        var amount = candidate.suggestedAmount
        if candidate.currency.uppercased() == "KRW" {
            amount = max(0, amount - holdingValue(for: candidate.symbol))
            guard referencePrice > 0, amount >= referencePrice else {
                return 0
            }
            return floor(amount / referencePrice) * referencePrice
        }
        return amount
    }

    private func isAutoManagedStrategy(_ strategy: TradingStrategy) -> Bool {
        strategy.riskNotes.localizedStandardContains("AUTO_PICK_MANAGED") ||
            strategy.riskNotes.localizedStandardContains("자동 종목 선택") ||
            strategy.name.localizedStandardContains("자동 선택")
    }

    private func autoManagedStopTake(for template: MechanicalStrategyTemplate) -> (stopLoss: Double, takeProfit: Double) {
        if template == .koquantMinuteMomentum {
            return (-1, 1.5)
        }
        return (-5, 6)
    }

    private func autoManagedConditions(template: MechanicalStrategyTemplate, amount: Double, referencePrice: Double) -> [StrategyCondition] {
        if template.isTwoSided {
            return [
                StrategyCondition(metric: .priceAbove, threshold: 0, action: .buy, amount: amount, quantity: 0, orderType: .limit, note: autoManagedNote(template: template, side: .buy, referencePrice: referencePrice)),
                StrategyCondition(metric: .priceAbove, threshold: 0, action: .sell, amount: amount, quantity: 0, orderType: .limit, note: autoManagedNote(template: template, side: .sell, referencePrice: referencePrice))
            ]
        }
        return [
            StrategyCondition(metric: .priceAbove, threshold: 0, action: .buy, amount: amount, quantity: 0, orderType: .limit, note: autoManagedNote(template: template, side: .buy, referencePrice: referencePrice))
        ]
    }

    private func autoManagedNote(template: MechanicalStrategyTemplate, side: StrategyAction, referencePrice: Double) -> String {
        let sideText = side == .sell ? "SELL" : "BUY"
        switch template {
        case .fixedGridTrading:
            return "MECH:\(template.token):side=\(sideText):gap=2.00:anchor=\(formattedDouble(referencePrice, fractionDigits: 4))"
        case .movingAverageCross:
            return "MECH:\(template.token):short=5:long=20"
        case .rsiRebound:
            return "MECH:\(template.token):period=14:level=30.0"
        case .bollingerRebound:
            return "MECH:\(template.token):period=20:std=2.00"
        case .bollingerBandChannel:
            return "MECH:\(template.token):side=\(sideText):period=20:std=2.00"
        case .rsiBandChannel:
            return "MECH:\(template.token):side=\(sideText):period=14:oversold=30.0:overbought=70.0"
        case .breakout:
            return "MECH:\(template.token):lookback=20"
        case .macdCross:
            return "MECH:\(template.token):fast=12:slow=26:signal=9"
        case .surgeVolumeMomentum:
            return "MECH:\(template.token):move=2.0:volume=1.8:lookback=20"
        case .plungeRebound:
            return "MECH:\(template.token):move=2.0:volume=1.8:lookback=5"
        case .tradeValueFocus:
            return "MECH:\(template.token):value=1.8:lookback=20"
        case .meanReversionCombo:
            return "MECH:\(template.token):side=\(sideText):band=20:std=2.00:rsi=14:oversold=30.0:overbought=70.0"
        case .marketMakingLite:
            return "MECH:\(template.token):side=\(sideText):period=20:spread=0.80"
        case .koquantMinuteMomentum:
            return "MECH:\(template.token):lookback=20:value=2.00:vwap=rolling"
        case .rangeSwingRebound:
            return "MECH:\(template.token):swing=2.0:lookback=20"
        case .rangeUpperWarning:
            return "MECH:\(template.token):swing=2.0:lookback=20"
        case .semiconductorValueBreakout:
            return "MECH:\(template.token):lookback=20:volume=1.5"
        case .semiconductorDipStabilize:
            return "MECH:\(template.token):lookback=5"
        case .semiconductorTrendRestart:
            return "MECH:\(template.token):short=5:long=20:lookback=10"
        }
    }

    @discardableResult
    private func createAutoRebalanceExitDraft(for strategy: TradingStrategy) -> Bool {
        guard autoRebalanceSettings.operationMode != .alertOnly,
              let quantity = holdingQuantity(for: strategy.symbol),
              quantity > 0,
              !hasRecentOrderIntent(symbol: strategy.symbol, side: .sell, seconds: safetySettings.orderCooldownSeconds) else {
            return false
        }

        let currency = holdingCurrency(for: strategy.symbol) ?? priceCurrency(for: strategy.symbol) ?? "KRW"
        let currentPrice = currentPriceForOrder(symbol: strategy.symbol, fallback: strategy.referencePrice)
        guard currentPrice > 0 else {
            return false
        }

        var rebalanceStrategy = strategy
        rebalanceStrategy.name = "\(strategy.name) 리밸런싱 매도"
        rebalanceStrategy.mode = autoRebalanceSettings.operationMode
        rebalanceStrategy.referencePrice = currentPrice
        let condition = StrategyCondition(
            metric: .priceAbove,
            threshold: currentPrice,
            action: .sell,
            amount: 0,
            quantity: quantity,
            orderType: .limit,
            note: "자동 리밸런싱 제외 매도 후보"
        )
        let preflight = preflightWarnings(
            strategy: rebalanceStrategy,
            condition: condition,
            currentPrice: currentPrice,
            currency: currency
        )
        let draft = createPendingOrder(
            strategy: rebalanceStrategy,
            condition: condition,
            currentPrice: currentPrice,
            currency: currency,
            sourceEvent: "자동 리밸런싱에서 제외되어 매도 후보 생성",
            safetyWarnings: preflight,
            aiReview: "AI 검토 없음"
        )

        appendOrderLog(
            symbol: strategy.symbol,
            strategyName: rebalanceStrategy.name,
            mode: autoRebalanceSettings.operationMode,
            event: "자동 리밸런싱 매도 후보 생성",
            aiReview: "AI 검토 없음",
            orderRequest: draft.orderSummary,
            result: preflight.isEmpty ? "보유 수량 기준 매도 후보를 만들었습니다." : "안전장치 확인이 필요합니다. \(preflight.joined(separator: " "))",
            isLiveOrder: false
        )

        if autoRebalanceSettings.operationMode == .autoOrder,
           safetySettings.allowLiveOrders,
           preflight.isEmpty {
            Task {
                await submitPendingOrder(draft)
            }
        }
        return true
    }

    private func rankedAutoAllocationUniverse(scope: MarketScope, limit: Int) -> [MarketActivitySnapshot] {
        marketActivities
            .filter { row in
                switch scope {
                case .all:
                    row.isDomestic
                case .domestic:
                    row.isDomestic
                case .overseas:
                    row.currency.uppercased() != "KRW" && !row.market.localizedCaseInsensitiveContains("K")
                }
            }
            .sorted { left, right in
                let leftValue = NSDecimalNumber(decimal: left.tradeValue ?? 0).doubleValue
                let rightValue = NSDecimalNumber(decimal: right.tradeValue ?? 0).doubleValue
                if leftValue == rightValue {
                    return NSDecimalNumber(decimal: left.tradeVolume ?? 0).doubleValue > NSDecimalNumber(decimal: right.tradeVolume ?? 0).doubleValue
                }
                return leftValue > rightValue
            }
            .prefix(limit)
            .map { $0 }
    }

    private func autoAllocationCandidate(
        row: MarketActivitySnapshot,
        candles: [Candle],
        budgetPerPosition: Double
    ) -> AutoAllocationCandidate? {
        let sortedCandles = candles.sorted { $0.date < $1.date }
        guard sortedCandles.count >= 20 else {
            return nil
        }
        let lastPriceValue = NSDecimalNumber(decimal: row.lastPriceValue).doubleValue
        guard lastPriceValue > 0, budgetPerPosition > 0 else {
            return nil
        }

        let isDomestic = row.currency.uppercased() == "KRW"
        let expectedQuantity = isDomestic ? floor(budgetPerPosition / lastPriceValue) : 0
        guard !isDomestic || expectedQuantity >= 1 else {
            return nil
        }
        let effectiveTradeAmount = isDomestic ? expectedQuantity * lastPriceValue : budgetPerPosition
        let affordabilityText = isDomestic
            ? "예상 \(formattedDouble(expectedQuantity, fractionDigits: 0))주 · 약 \(formattedDouble(effectiveTradeAmount, fractionDigits: 0))원 사용"
            : "해외주식은 원화 예산을 달러 시장가 금액주문으로 바꿔 제출"

        let templates: [MechanicalStrategyTemplate] = [
            .koquantMinuteMomentum,
            .surgeVolumeMomentum,
            .breakout,
            .macdCross,
            .movingAverageCross,
            .tradeValueFocus,
            .semiconductorTrendRestart,
            .rangeSwingRebound,
            .bollingerBandChannel,
            .meanReversionCombo
        ]

        let evaluated = templates.map { template -> (template: MechanicalStrategyTemplate, summary: SimpleBacktestSummary) in
            let valueMultiplier = template == .koquantMinuteMomentum ? 2.0 : 1.8
            let stopLoss = template == .koquantMinuteMomentum ? -1.0 : -5.0
            let takeProfit = template == .koquantMinuteMomentum ? 1.5 : 6.0
            let buySignals = MechanicalSignalEngine.signalIndexes(
                candles: sortedCandles,
                template: template,
                shortPeriod: 5,
                longPeriod: 20,
                rsiPeriod: 14,
                rsiLevel: 30,
                bandPeriod: 20,
                bandStdDev: 2,
                breakoutLookback: 20,
                movePercent: 2,
                volumeMultiplier: valueMultiplier
            )
            let sellSignals = template.isTwoSided ? MechanicalSignalEngine.signalIndexes(
                candles: sortedCandles,
                template: template,
                shortPeriod: 5,
                longPeriod: 20,
                rsiPeriod: 14,
                rsiLevel: 30,
                bandPeriod: 20,
                bandStdDev: 2,
                breakoutLookback: 20,
                movePercent: 2,
                volumeMultiplier: valueMultiplier,
                side: .sell
            ) : []
            let summary = MechanicalSignalEngine.summary(
                candles: sortedCandles,
                signalIndexes: buySignals,
                tradeAmount: effectiveTradeAmount,
                exitSignalIndexes: sellSignals,
                stopLossPercent: stopLoss,
                takeProfitPercent: takeProfit
            )
            return (template, summary)
        }

        let best = evaluated.max { left, right in
            autoAllocationTemplateScore(left.summary) < autoAllocationTemplateScore(right.summary)
        } ?? (.movingAverageCross, SimpleBacktestSummary(signalCount: 0, winCount: 0, averageReturn: 0, worstReturn: 0, estimatedPnL: 0))

        let trendPercent = closeChangePercent(sortedCandles)
        let volatility = averageAbsoluteMovePercent(sortedCandles)
        let tradeValue = NSDecimalNumber(decimal: row.tradeValue ?? 0).doubleValue
        let liquidityScore = tradeValue > 0 ? min(12, log10(max(10, tradeValue)) * 1.2) : 0
        let backtestScore = autoAllocationTemplateScore(best.summary)
        let rawScore = 50 + trendPercent * 2.2 + backtestScore + liquidityScore - volatility * 1.4
        let trendScore = max(0, min(100, rawScore))
        let tradeValueText = row.tradeValue.map { compactDecimal($0, fractionDigits: 1) } ?? "-"
        let reason: String
        if best.summary.hasSignals {
            reason = "\(best.template.title)이 최근 분봉에서 거래 \(best.summary.signalCount)번, 평균 \(formattedDouble(best.summary.averageReturn, fractionDigits: 2))%로 가장 높게 나왔습니다."
        } else {
            reason = "최근 분봉 신호는 적지만 가격 변화율 \(formattedDouble(trendPercent, fractionDigits: 2))%와 거래대금 \(tradeValueText)을 기준으로 후보에 올렸습니다."
        }
        let guardResult = berkshireGuard(
            row: row,
            summary: best.summary,
            trendPercent: trendPercent,
            volatility: volatility,
            effectiveTradeAmount: effectiveTradeAmount
        )

        return AutoAllocationCandidate(
            symbol: row.symbol,
            name: row.name,
            market: row.market,
            currency: row.currency,
            lastPrice: row.lastPrice,
            template: best.template,
            summary: best.summary,
            trendScore: trendScore,
            trendPercent: trendPercent,
            tradeValueText: tradeValueText,
            suggestedAmount: effectiveTradeAmount,
            expectedQuantity: expectedQuantity,
            expectedPnL: best.summary.estimatedPnL,
            affordabilityText: affordabilityText,
            executionHint: "자동 감시가 켜져 있으면 1분마다 새 분봉을 보고, 공식 신호가 나온 순간 설정한 실행 방식대로 처리합니다.",
            reason: reason,
            berkshireVerdict: guardResult.verdict,
            berkshireGuardText: guardResult.text,
            allowsAutoOrder: guardResult.allowsAutoOrder
        )
    }

    private func berkshireGuard(
        row: MarketActivitySnapshot,
        summary: SimpleBacktestSummary,
        trendPercent: Double,
        volatility: Double,
        effectiveTradeAmount: Double
    ) -> (verdict: String, text: String, allowsAutoOrder: Bool) {
        let dataGrade = marketActivityAllowsAutoSelection ? "A" : "C"
        var concerns: [String] = []

        if !marketActivityAllowsAutoSelection {
            concerns.append("시장 랭킹 데이터 검증 미통과")
        }
        if row.tradeValue == nil || row.tradeVolume == nil {
            concerns.append("거래대금/거래량 누락")
        }
        if effectiveTradeAmount <= 0 {
            concerns.append("실매수 가능 예산 없음")
        }
        if !summary.hasSignals {
            concerns.append("최근 분봉 매수 신호 부족")
        }
        if summary.hasSignals, summary.winRate < 45 {
            concerns.append("최근 신호 승률 낮음")
        }
        if summary.worstReturn < -3 {
            concerns.append("최근 최악 손익 \(formattedDouble(summary.worstReturn, fractionDigits: 1))%")
        }
        if volatility > 3.5 {
            concerns.append("분봉 변동성 과다")
        }
        if trendPercent < -4 {
            concerns.append("단기 하락 추세 강함")
        }

        if concerns.isEmpty {
            return (
                "통과",
                "Berkshire Guard: 데이터 \(dataGrade) · 분봉 신호와 예산 검산 통과 · 완전 자동 가능",
                true
            )
        }

        let detail = concerns.prefix(3).joined(separator: " / ")
        if marketActivityAllowsAutoSelection, effectiveTradeAmount > 0, concerns.count <= 2 {
            return (
                "조건부",
                "Berkshire Guard: 데이터 \(dataGrade) · \(detail) · 승인 후 주문 권장",
                false
            )
        }

        return (
            "보류",
            "Berkshire Guard: 데이터 \(dataGrade) · \(detail) · 자동주문 차단",
            false
        )
    }

    private func autoAllocationTemplateScore(_ summary: SimpleBacktestSummary) -> Double {
        guard summary.hasSignals else {
            return -8
        }
        return summary.averageReturn * 4 + summary.winRate * 0.08 - abs(summary.worstReturn) * 0.8 + min(6, Double(summary.signalCount))
    }

    private var marketActivitiesNeedRefresh: Bool {
        guard !marketActivities.isEmpty else {
            return true
        }
        let newestUpdate = marketActivities.map(\.updatedAt).max() ?? .distantPast
        return Date().timeIntervalSince(newestUpdate) > 60
    }

    private func closeChangePercent(_ candles: [Candle]) -> Double {
        guard let first = candles.first, let last = candles.last else {
            return 0
        }
        let firstClose = NSDecimalNumber(decimal: first.closeValue).doubleValue
        let lastClose = NSDecimalNumber(decimal: last.closeValue).doubleValue
        guard firstClose > 0 else {
            return 0
        }
        return ((lastClose - firstClose) / firstClose) * 100
    }

    private func averageAbsoluteMovePercent(_ candles: [Candle]) -> Double {
        guard candles.count >= 2 else {
            return 0
        }
        var moves: [Double] = []
        for index in 1..<candles.count {
            let previous = NSDecimalNumber(decimal: candles[index - 1].closeValue).doubleValue
            let current = NSDecimalNumber(decimal: candles[index].closeValue).doubleValue
            guard previous > 0 else {
                continue
            }
            moves.append(abs((current - previous) / previous) * 100)
        }
        guard !moves.isEmpty else {
            return 0
        }
        return moves.reduce(0, +) / Double(moves.count)
    }

    func refreshAccounts() async {
        guard canUseAPI() else {
            return
        }
        guard credentials.isComplete else {
            connectionState = .demo
            return
        }

        connectionState = .loading

        do {
            let accessToken = try await validAccessToken()
            accounts = try await client.accounts(accessToken: accessToken)
            if selectedAccountSeq == nil {
                selectedAccountSeq = accounts.first?.accountSeq
            }
            apiCooldownUntil = nil
            connectionState = .live(Date())
        } catch {
            handleAPIError(error)
        }
    }

    func refreshHoldings() async {
        guard canUseAPI() else {
            return
        }
        guard credentials.isComplete, let selectedAccountSeq else {
            connectionState = .demo
            return
        }

        connectionState = .loading

        do {
            let accessToken = try await validAccessToken()
            let overview = try await client.holdings(accountSeq: selectedAccountSeq, accessToken: accessToken)
            holdings = overview.items.map { item in
                Holding(
                    symbol: item.symbol,
                    name: item.name,
                    quantity: item.quantity,
                    value: item.marketValue.amount,
                    currency: item.currency,
                    profitLoss: formatRate(item.profitLoss.rate)
                )
            }
            apiCooldownUntil = nil
            connectionState = .live(Date())
        } catch {
            handleAPIError(error)
        }
    }

    func addStrategy() {
        strategies.insert(
            TradingStrategy(
                name: "새 전략",
                symbol: selectedSymbol,
                isEnabled: false,
                mode: .alertOnly,
                referencePrice: NSDecimalNumber(decimal: prices.first(where: { $0.symbol == selectedSymbol })?.lastPriceValue ?? 0).doubleValue,
                maxDailyAmount: safetySettings.dailyBuyLimit,
                stopLossPercent: -8,
                takeProfitPercent: 12,
                cooldownMinutes: 30,
                conditions: [
                    StrategyCondition(metric: .priceBelow, threshold: 0, action: .notify, amount: 0, quantity: 0, orderType: .limit, note: "")
                ],
                createdAt: Date(),
                updatedAt: Date(),
                riskNotes: ""
            ),
            at: 0
        )
        saveAppState()
    }

    func removeStrategies(at offsets: IndexSet) {
        for index in offsets.sorted(by: >) {
            strategies.remove(at: index)
        }
        saveAppState()
    }

    func evaluateStrategies(candlesBySymbol: [String: [Candle]] = [:]) {
        guard automationEnabled else {
            return
        }

        let alertResult = evaluatePriceAlerts()
        var triggeredCount = alertResult.triggered
        var watchedCount = alertResult.watched
        for strategy in strategies where strategy.isEnabled {
            watchedCount += 1
            guard let price = prices.first(where: { $0.symbol.caseInsensitiveCompare(strategy.symbol) == .orderedSame }) else {
                continue
            }

            let currentPrice = NSDecimalNumber(decimal: price.lastPriceValue).doubleValue
            let strategyCandles = candlesForStrategy(strategy, override: candlesBySymbol)
            for condition in strategy.conditions where conditionTriggered(condition, strategy: strategy, currentPrice: currentPrice, candles: strategyCandles) {
                triggeredCount += 1
                handleTrigger(strategy: strategy, condition: condition, currentPrice: currentPrice, currency: price.currency)
            }
            evaluateStopTakeProfit(strategy: strategy, currentPrice: currentPrice, currency: price.currency)
        }
        if watchedCount == 0 {
            lastAutomationDecision = "켜진 매크로와 가격 알림이 없어 감시하지 않습니다."
        } else if triggeredCount == 0 {
            lastAutomationDecision = "신호 대기: 감시 항목 \(watchedCount)개를 확인했지만 이번 1분봉에서는 조건 충족이 없습니다."
        } else {
            lastAutomationDecision = "조건 충족: \(triggeredCount)개 신호가 발생해 주문 후보 또는 알림을 처리했습니다."
        }
        saveAppState()
    }

    private func evaluatePriceAlerts() -> (watched: Int, triggered: Int) {
        var watched = 0
        var triggered = 0
        let now = Date()

        for index in priceAlerts.indices {
            guard priceAlerts[index].isEnabled else {
                continue
            }
            if priceAlerts[index].expiresAt <= now {
                priceAlerts[index].isEnabled = false
                continue
            }
            watched += 1
            guard let price = prices.first(where: { $0.symbol.caseInsensitiveCompare(priceAlerts[index].symbol) == .orderedSame }) else {
                continue
            }
            let currentPrice = NSDecimalNumber(decimal: price.lastPriceValue).doubleValue
            let target = priceAlerts[index].targetPrice
            let isHit: Bool
            switch priceAlerts[index].condition {
            case .above:
                isHit = currentPrice >= target
            case .below:
                isHit = currentPrice <= target
            }
            guard isHit else {
                continue
            }
            if let last = priceAlerts[index].lastTriggeredAt,
               now.timeIntervalSince(last) < 15 * 60 {
                continue
            }

            priceAlerts[index].lastTriggeredAt = now
            triggered += 1
            let alert = priceAlerts[index]
            let message = "\(alert.name): 현재가 \(formattedDouble(currentPrice, fractionDigits: price.currency == "KRW" ? 0 : 2)) \(price.currency), 목표 \(alert.conditionText)"
            appendOrderLog(
                symbol: alert.symbol,
                strategyName: "가격 알림",
                mode: .alertOnly,
                event: "가격 알림 조건 충족",
                aiReview: "AI 검토 없음",
                orderRequest: "주문 없음",
                result: message,
                isLiveOrder: false
            )
            notifications.post(title: "가격 알림 도달", body: message)
        }

        return (watched, triggered)
    }

    func nextTriggerText(for strategy: TradingStrategy) -> String {
        guard strategy.isEnabled else {
            return "꺼짐: 이 매크로는 감시하지 않습니다."
        }
        guard automationEnabled else {
            return "자동감시 꺼짐: 감시 시작을 눌러야 조건을 봅니다."
        }
        guard let condition = strategy.conditions.first(where: { $0.action == .buy || $0.action == .sell }) else {
            return "주문 조건 없음: 예산이 1주 가격보다 작거나 조건이 비어 있습니다."
        }

        let action = condition.action == .sell ? "매도" : "매수"
        if condition.note.hasPrefix("MECH:") {
            return "다음 \(action): \(mechanicalTriggerDescription(condition.note))"
        }

        switch condition.metric {
        case .priceBelow:
            return "다음 \(action): 현재가가 \(formattedDouble(condition.threshold, fractionDigits: 2)) 이하"
        case .priceAbove:
            return "다음 \(action): 현재가가 \(formattedDouble(condition.threshold, fractionDigits: 2)) 이상"
        case .dropPercent:
            return "다음 \(action): 기준가 대비 \(formattedDouble(condition.threshold, fractionDigits: 1))% 하락"
        case .gainPercent:
            return "다음 \(action): 기준가 대비 \(formattedDouble(condition.threshold, fractionDigits: 1))% 상승"
        case .profitRateBelow:
            return "다음 \(action): 손익률 \(formattedDouble(condition.threshold, fractionDigits: 1))% 이하"
        case .profitRateAbove:
            return "다음 \(action): 손익률 \(formattedDouble(condition.threshold, fractionDigits: 1))% 이상"
        }
    }

    func executionReadinessText(for strategy: TradingStrategy) -> String {
        if !strategy.isEnabled {
            return "꺼짐: 자동감시 대상이 아닙니다."
        }
        if !automationEnabled {
            return "자동감시가 꺼져 있어 아직 사지 않습니다."
        }
        if strategy.conditions.isEmpty || strategy.maxDailyAmount <= 0 {
            return "주문 예산이 0원이거나 1주 가격보다 작아 실제 매수 후보를 만들 수 없습니다."
        }
        if strategy.mode == .autoOrder && !safetySettings.allowLiveOrders {
            return "완전 자동 모드지만 라이브 주문이 잠겨 있어 조건이 떠도 실주문은 차단됩니다."
        }
        if strategy.mode == .confirmBeforeOrder {
            return "조건이 뜨면 승인 대기 주문을 만들고, 사용자가 눌러야 제출됩니다."
        }
        if strategy.mode == .aiReviewMode {
            return "조건이 뜨면 AI 검토 대기 주문 후보를 만듭니다."
        }
        if strategy.mode == .alertOnly {
            return "조건이 떠도 주문하지 않고 알림만 보냅니다."
        }
        return "조건이 뜨고 안전검사를 통과하면 실주문 제출을 시도합니다."
    }

    private func mechanicalTriggerDescription(_ note: String) -> String {
        let parts = note.split(separator: ":").map(String.init)
        let token = parts.count > 1 ? parts[1] : ""
        let params = Dictionary(uniqueKeysWithValues: parts.dropFirst(2).compactMap { part -> (String, String)? in
            let pair = part.split(separator: "=", maxSplits: 1).map(String.init)
            guard pair.count == 2 else { return nil }
            return (pair[0], pair[1])
        })

        switch token {
        case "KOQUANT_MINUTE_MOMENTUM":
            return "최근 \(params["lookback"] ?? "20")분 평균 거래대금의 \(params["value"] ?? "2.00")배 이상 붙고 종가가 VWAP 위"
        case "SURGE_VOLUME_MOMENTUM":
            return "\(params["lookback"] ?? "20")분 기준 \(params["move"] ?? "2.0")% 이상 상승 + 거래량 \(params["volume"] ?? "1.8")배"
        case "BREAKOUT":
            return "최근 \(params["lookback"] ?? "20")봉 고점 돌파"
        case "MACD_CROSS":
            return "MACD가 신호선을 위로 돌파"
        case "SMA_CROSS":
            return "\(params["short"] ?? "5")분선이 \(params["long"] ?? "20")분선을 위로 돌파"
        case "TRADE_VALUE_FOCUS":
            return "최근 \(params["lookback"] ?? "20")봉 평균보다 거래대금 \(params["value"] ?? "1.8")배 이상 증가"
        case "BOLLINGER_CHANNEL":
            return "볼린저밴드 하단 매수 신호 또는 상단 매도 신호"
        case "RSI_CHANNEL":
            return "RSI 과매도/과매수 구간 진입"
        case "MEAN_REVERSION_COMBO":
            return "볼린저밴드와 RSI가 함께 과매도/과매수 신호"
        case "SEMI_TREND_RESTART":
            return "반도체 추세 재시작: 단기선 우위와 최근 고점 회복"
        case "SEMI_VALUE_BREAKOUT":
            return "반도체 거래대금 증가 + 최근 고점 돌파"
        case "RANGE_SWING_REBOUND":
            return "최근 박스권 하단 부근 반등"
        case "FIXED_GRID":
            return "기준가 대비 \(params["gap"] ?? "2.00")% 간격 도달"
        default:
            return "선택한 기계적 매매 공식의 최신 분봉 신호 발생"
        }
    }

    func buildStrategyFromNaturalLanguage(input: String, engine: AIEngineKind) async {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }

        let parsed = parseStrategyInput(trimmed)
        let strategy = TradingStrategy(
            name: parsed.name,
            symbol: parsed.symbol,
            isEnabled: false,
            mode: .confirmBeforeOrder,
            referencePrice: parsed.referencePrice,
            maxDailyAmount: parsed.maxDailyAmount,
            stopLossPercent: -8,
            takeProfitPercent: 12,
            cooldownMinutes: 30,
            conditions: parsed.conditions,
            createdAt: Date(),
            updatedAt: Date(),
            riskNotes: "자연어 전략에서 생성됨. 저장 전 조건과 금액을 확인하세요."
        )
        strategies.insert(strategy, at: 0)

        let prompt = """
        다음 자연어 매매 전략을 실행 가능한 조건식으로 검토해 주세요.
        반드시 JSON만 출력하지 말고, 사람이 검토할 수 있게 위험 요약과 조건 해석을 한국어로 정리해 주세요.

        자연어 전략:
        \(trimmed)

        앱이 임시 변환한 조건:
        \(parsed.conditions.map { "- \($0.metric.title) \($0.threshold), 행동=\($0.action.title), 금액=\($0.amount), 수량=\($0.quantity)" }.joined(separator: "\n"))
        """
        await runAIAnalysis(engine: engine, symbol: parsed.symbol, prompt: prompt)
        saveAppState()
    }

    func approvePendingOrderDryRun(_ draft: PendingOrderDraft) {
        guard let index = pendingOrders.firstIndex(where: { $0.id == draft.id }) else {
            return
        }
        pendingOrders[index].status = .approvedDryRun
        appendOrderLog(
            symbol: draft.symbol,
            strategyName: draft.strategyName,
            mode: draft.mode,
            event: "사용자가 주문 드래프트를 모의 승인했습니다.",
            aiReview: draft.aiReview,
            orderRequest: draft.orderSummary,
            result: "실제 주문은 제출하지 않았습니다.",
            isLiveOrder: false
        )
        saveAppState()
    }

    func cancelPendingOrder(_ draft: PendingOrderDraft) {
        guard let index = pendingOrders.firstIndex(where: { $0.id == draft.id }) else {
            return
        }
        pendingOrders[index].status = .canceled
        appendOrderLog(
            symbol: draft.symbol,
            strategyName: draft.strategyName,
            mode: draft.mode,
            event: "사용자가 주문 드래프트를 취소했습니다.",
            aiReview: draft.aiReview,
            orderRequest: draft.orderSummary,
            result: "취소 완료",
            isLiveOrder: false
        )
        saveAppState()
    }

    @discardableResult
    func createManualOrderDraft(
        symbolInput: String,
        side: StrategyAction,
        orderType: DraftOrderType,
        amount: Double,
        quantity: Double,
        limitPrice: Double
    ) async -> PendingOrderDraft? {
        guard side == .buy || side == .sell else {
            manualOrderStatus = "매수 또는 매도만 선택할 수 있습니다."
            return nil
        }

        let symbol = resolveSymbol(from: symbolInput)
        guard !symbol.isEmpty else {
            manualOrderStatus = "종목을 입력해 주세요."
            return nil
        }

        if selectedSymbol.caseInsensitiveCompare(symbol) != .orderedSame {
            selectedSymbol = symbol
            await refreshMarketData()
        }

        let price = prices.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame } ?? MockData.demoPrice(for: symbol)
        var referencePrice = limitPrice > 0 ? limitPrice : NSDecimalNumber(decimal: price.lastPriceValue).doubleValue
        let currency = price.currency
        let orderAmount = max(0, amount)
        var orderQuantity = max(0, quantity)

        if side == .sell, orderQuantity <= 0 {
            orderQuantity = await sellableQuantityForManualOrder(symbol: symbol) ?? holdingQuantity(for: symbol) ?? 0
        }

        if side == .buy, orderQuantity <= 0, orderAmount <= 0 {
            manualOrderStatus = "매수는 금액 또는 수량 중 하나를 입력해야 합니다."
            return nil
        }

        if side == .sell, orderQuantity <= 0 {
            manualOrderStatus = "매도 가능 수량을 찾지 못했습니다. 보유 수량을 확인해 주세요."
            return nil
        }

        if orderQuantity > 0, referencePrice <= 0 {
            referencePrice = NSDecimalNumber(decimal: price.lastPriceValue).doubleValue
        }

        let condition = StrategyCondition(
            metric: orderType == .limit ? .priceAbove : .priceAbove,
            threshold: referencePrice,
            action: side,
            amount: side == .sell ? 0 : orderAmount,
            quantity: orderQuantity,
            orderType: orderType,
            note: "계좌 탭 단일종목 주문 테스트"
        )
        let strategy = TradingStrategy(
            name: "\(stockName(for: symbol) ?? symbol) 단일종목 주문 테스트",
            symbol: symbol,
            isEnabled: false,
            mode: .confirmBeforeOrder,
            referencePrice: referencePrice,
            maxDailyAmount: max(orderAmount, orderQuantity * max(referencePrice, 0)),
            stopLossPercent: 0,
            takeProfitPercent: 0,
            cooldownMinutes: 1,
            conditions: [condition],
            createdAt: Date(),
            updatedAt: Date(),
            riskNotes: "계좌 탭에서 사용자가 직접 만든 주문 테스트입니다."
        )
        let warnings = preflightWarnings(
            strategy: strategy,
            condition: condition,
            currentPrice: referencePrice,
            currency: currency
        )
        let draft = createPendingOrder(
            strategy: strategy,
            condition: condition,
            currentPrice: referencePrice,
            currency: currency,
            sourceEvent: "계좌 탭 단일종목 주문 테스트",
            safetyWarnings: warnings,
            aiReview: "AI 검토 없음"
        )
        manualOrderStatus = warnings.isEmpty
            ? "\(draft.orderSummary) 후보를 만들었습니다. 아래 승인 대기에서 실주문 제출을 눌러 테스트하세요."
            : "\(draft.orderSummary) 후보를 만들었지만 안전 확인이 필요합니다. \(warnings.joined(separator: " "))"
        saveAppState()
        return draft
    }

    private func sellableQuantityForManualOrder(symbol: String) async -> Double? {
        guard credentials.isComplete, let selectedAccountSeq else {
            return nil
        }
        do {
            let accessToken = try await validAccessToken()
            let response = try await client.sellableQuantity(
                accountSeq: selectedAccountSeq,
                symbol: symbol,
                accessToken: accessToken
            )
            return NSDecimalNumber(decimal: response.sellableQuantityValue).doubleValue
        } catch {
            return nil
        }
    }

    func submitPendingOrder(_ draft: PendingOrderDraft) async {
        guard let index = pendingOrders.firstIndex(where: { $0.id == draft.id }) else {
            return
        }
        guard safetySettings.allowLiveOrders else {
            pendingOrders[index].status = .blocked
            appendOrderLog(
                symbol: draft.symbol,
                strategyName: draft.strategyName,
                mode: draft.mode,
                event: "실주문 제출 시도",
                aiReview: draft.aiReview,
                orderRequest: draft.orderSummary,
                result: "라이브 주문 허용이 꺼져 있어 차단했습니다.",
                isLiveOrder: false
            )
            saveAppState()
            return
        }
        guard credentials.isComplete, let selectedAccountSeq else {
            pendingOrders[index].status = .blocked
            appendOrderLog(
                symbol: draft.symbol,
                strategyName: draft.strategyName,
                mode: draft.mode,
                event: "실주문 제출 시도",
                aiReview: draft.aiReview,
                orderRequest: draft.orderSummary,
                result: "계좌 또는 API 인증 정보가 없어 차단했습니다.",
                isLiveOrder: false
            )
            saveAppState()
            return
        }
        guard let side = draft.side.apiSide else {
            pendingOrders[index].status = .blocked
            appendOrderLog(
                symbol: draft.symbol,
                strategyName: draft.strategyName,
                mode: draft.mode,
                event: "실주문 제출 시도",
                aiReview: draft.aiReview,
                orderRequest: draft.orderSummary,
                result: "알림 조건은 주문 방향이 없어 제출할 수 없습니다.",
                isLiveOrder: false
            )
            saveAppState()
            return
        }

        do {
            let accessToken = try await validAccessToken()
            let preparedDraft = try await prepareDraftForSubmission(draft, accessToken: accessToken)
            pendingOrders[index] = preparedDraft

            guard let payload = orderPayload(for: preparedDraft, side: side) else {
                pendingOrders[index].status = .blocked
                appendOrderLog(
                    symbol: preparedDraft.symbol,
                    strategyName: preparedDraft.strategyName,
                    mode: preparedDraft.mode,
                    event: "실주문 제출 시도",
                    aiReview: preparedDraft.aiReview,
                    orderRequest: preparedDraft.orderSummary,
                    result: orderPayloadFailureReason(for: preparedDraft),
                    isLiveOrder: false
                )
                saveAppState()
                return
            }

            let response = try await client.createOrder(
                accountSeq: selectedAccountSeq,
                payload: payload,
                accessToken: accessToken
            )
            pendingOrders[index].status = .submitted
            pendingOrders[index].submittedOrderId = response.orderId
            appendOrderLog(
                symbol: preparedDraft.symbol,
                strategyName: preparedDraft.strategyName,
                mode: preparedDraft.mode,
                event: "실주문 제출 완료",
                aiReview: preparedDraft.aiReview,
                orderRequest: preparedDraft.orderSummary,
                result: "주문 ID: \(response.orderId)",
                isLiveOrder: true
            )
        } catch {
            pendingOrders[index].status = .blocked
            appendOrderLog(
                symbol: draft.symbol,
                strategyName: draft.strategyName,
                mode: draft.mode,
                event: "실주문 제출 시도",
                aiReview: draft.aiReview,
                orderRequest: draft.orderSummary,
                result: error.localizedDescription,
                isLiveOrder: false
            )
        }
        saveAppState()
    }

    private func prepareDraftForSubmission(_ draft: PendingOrderDraft, accessToken: String) async throws -> PendingOrderDraft {
        var prepared = draft
        let sourceAmountCurrency = prepared.amountCurrency?.uppercased() ?? (prepared.currency.uppercased() == "USD" ? "KRW" : prepared.currency.uppercased())
        if prepared.currency.uppercased() == "USD",
           sourceAmountCurrency == "KRW",
           prepared.side == .buy,
           prepared.quantity <= 0,
           prepared.amount > 0 {
            let rate = try await client.exchangeRate(
                baseCurrency: "USD",
                quoteCurrency: "KRW",
                accessToken: accessToken
            )
            let rateValue = NSDecimalNumber(decimal: rate.rateValue).doubleValue
            guard rateValue > 0 else {
                throw TossInvestClientError.httpStatus(0, "환율 값이 없어 해외주식 금액 주문을 만들 수 없습니다.")
            }

            let usdAmount = floor((prepared.amount / rateValue) * 100) / 100
            guard usdAmount > 0 else {
                throw TossInvestClientError.httpStatus(0, "원화 예산이 너무 작아 달러 주문금액으로 변환할 수 없습니다.")
            }

            prepared.amount = usdAmount
            prepared.amountCurrency = "USD"
            prepared.orderType = .market
        }

        if prepared.side == .buy,
           prepared.amount > 0,
           prepared.quantity <= 0,
           let selectedAccountSeq {
            let buyingPower = try? await client.buyingPower(
                accountSeq: selectedAccountSeq,
                currency: prepared.amountCurrency ?? prepared.currency,
                accessToken: accessToken
            )
            if let buyingPower {
                let available = NSDecimalNumber(decimal: buyingPower.cashBuyingPowerValue).doubleValue
                if available > 0, prepared.amount > available {
                    throw TossInvestClientError.httpStatus(
                        0,
                        "매수 가능 금액이 부족합니다. 가능 금액 \(formattedDouble(available, fractionDigits: buyingPower.currency == "KRW" ? 0 : 2)) \(buyingPower.currency)"
                    )
                }
            }
        }

        if prepared.side == .sell,
           prepared.quantity > 0,
           let selectedAccountSeq {
            let sellable = try? await client.sellableQuantity(
                accountSeq: selectedAccountSeq,
                symbol: prepared.symbol,
                accessToken: accessToken
            )
            if let sellable {
                let available = NSDecimalNumber(decimal: sellable.sellableQuantityValue).doubleValue
                if prepared.quantity > available {
                    throw TossInvestClientError.httpStatus(
                        0,
                        "매도 가능 수량이 부족합니다. 가능 수량 \(formattedDouble(available, fractionDigits: 4))주"
                    )
                }
            }
        }

        return prepared
    }

    private func orderPayload(for draft: PendingOrderDraft, side: String) -> OrderCreatePayload? {
        if draft.quantity > 0 {
            let quantity = floor(draft.quantity)
            guard quantity >= 1 else {
                return nil
            }
            return OrderCreatePayload(
                clientOrderId: clientOrderId(for: draft),
                symbol: draft.symbol,
                side: side,
                orderType: draft.orderType.apiValue,
                timeInForce: "DAY",
                quantity: formattedOrderQuantity(quantity),
                price: draft.orderType == .limit ? formattedOrderPrice(draft.referencePrice, currency: draft.currency) : nil,
                orderAmount: nil,
                confirmHighValueOrder: false
            )
        }

        if draft.currency.uppercased() == "KRW", draft.amount > 0, draft.referencePrice > 0 {
            let quantity = floor(draft.amount / draft.referencePrice)
            guard quantity >= 1 else {
                return nil
            }
            return OrderCreatePayload(
                clientOrderId: clientOrderId(for: draft),
                symbol: draft.symbol,
                side: side,
                orderType: draft.orderType.apiValue,
                timeInForce: "DAY",
                quantity: formattedOrderQuantity(quantity),
                price: draft.orderType == .limit ? formattedOrderPrice(draft.referencePrice, currency: draft.currency) : nil,
                orderAmount: nil,
                confirmHighValueOrder: false
            )
        }

        if draft.currency.uppercased() == "USD",
           (draft.amountCurrency ?? draft.currency).uppercased() == "USD",
           draft.side == .buy,
           draft.orderType == .market,
           draft.amount > 0 {
            return OrderCreatePayload(
                clientOrderId: clientOrderId(for: draft),
                symbol: draft.symbol,
                side: side,
                orderType: draft.orderType.apiValue,
                timeInForce: nil,
                quantity: nil,
                price: nil,
                orderAmount: formattedOrderAmount(draft.amount),
                confirmHighValueOrder: false
            )
        }

        return nil
    }

    private func orderPayloadFailureReason(for draft: PendingOrderDraft) -> String {
        if draft.quantity <= 0, draft.amount <= 0 {
            return "주문 수량 또는 금액이 없어 차단했습니다."
        }
        if draft.currency.uppercased() == "USD",
           (draft.amountCurrency ?? draft.currency).uppercased() == "KRW" {
            return "해외주식 원화 예산을 달러 주문금액으로 바꾸지 못해 차단했습니다."
        }
        if draft.currency.uppercased() == "KRW", draft.amount > 0, draft.referencePrice > 0, floor(draft.amount / draft.referencePrice) < 1 {
            return "현재가 기준 주문 금액이 1주 미만이라 차단했습니다."
        }
        if draft.currency.uppercased() == "USD", draft.quantity <= 0 {
            return "해외주식 금액 자동주문은 USD 시장가 매수일 때만 가능합니다. 지정가/매도는 수량을 입력해야 합니다."
        }
        return "토스 주문 규칙에 맞는 수량 또는 금액으로 변환할 수 없어 차단했습니다."
    }

    private func clientOrderId(for draft: PendingOrderDraft) -> String {
        "tamt-\(draft.id.uuidString.prefix(31))"
    }

    private func formattedOrderQuantity(_ quantity: Double) -> String {
        String(format: "%.0f", quantity)
    }

    private func formattedOrderAmount(_ amount: Double) -> String {
        String(format: "%.2f", amount)
    }

    private func formattedOrderPrice(_ price: Double, currency: String) -> String {
        if currency.uppercased() == "KRW" {
            return String(format: "%.0f", price)
        }
        return String(format: "%.2f", price)
    }

    @discardableResult
    func runAIAnalysis(engine: AIEngineKind, symbol: String, prompt: String, wrapForReport: Bool = true) async -> AIAnalysisResult? {
        guard let index = aiEngines.firstIndex(where: { $0.engine == engine }) else {
            return nil
        }

        let jobID = beginAIJob(engine: engine, symbol: symbol, purpose: "분석")
        defer { finishAIJob(jobID) }

        let command = aiEngines[index].analysisCommand
        aiEngines[index].lastStatus = "실행 중"

        let context = wrapForReport ? analysisPrompt(symbol: symbol, userPrompt: prompt) : prompt
        do {
            let rawOutput = try await aiRunner.run(command: command, stdin: context)
            let output = AIOutputCleaner.clean(rawOutput)
            let result = AIAnalysisResult(
                engine: engine,
                symbol: symbol,
                prompt: prompt,
                output: output,
                riskScore: heuristicRiskScore(output),
                createdAt: Date()
            )
            aiResults.insert(result, at: 0)
            aiEngines[index].lastStatus = "정상"
            saveAppState()
            return result
        } catch {
            aiEngines[index].lastStatus = error.localizedDescription
            let output = AIOutputCleaner.clean(error.localizedDescription)
            let result = AIAnalysisResult(
                engine: engine,
                symbol: symbol,
                prompt: prompt,
                output: output,
                riskScore: 100,
                createdAt: Date()
            )
            aiResults.insert(result, at: 0)
            saveAppState()
            return result
        }
    }

    func deleteAIResult(_ id: UUID) {
        aiResults.removeAll { $0.id == id }
        saveAppState()
    }

    func clearAIResults(for symbol: String? = nil) {
        if let symbol {
            aiResults.removeAll { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
        } else {
            aiResults.removeAll()
        }
        saveAppState()
    }

    func latestAIResult(for symbol: String) -> AIAnalysisResult? {
        aiResults.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
    }

    var latestWatchlistBrief: AIAnalysisResult? {
        latestAIResult(for: "WATCHLIST")
    }

    func runWatchlistBrief() async -> AIAnalysisResult? {
        guard investorProfile.dailyBriefEnabled else {
            return nil
        }
        let preferredEngines: [AIEngineKind] = [.claude, .gemini, .codex]
        let engine = preferredEngines.first { preferred in
            aiEngines.contains { $0.engine == preferred && $0.isEnabled }
        } ?? .codex

        let result = await runAIAnalysis(
            engine: engine,
            symbol: "WATCHLIST",
            prompt: watchlistBriefPrompt(),
            wrapForReport: false
        )
        if let result {
            notifications.post(title: "관심종목 브리프 완료", body: result.output.components(separatedBy: .newlines).first ?? "AI 브리프가 생성되었습니다.")
        }
        return result
    }

    func testAIEngine(_ engine: AIEngineKind) async {
        guard let index = aiEngines.firstIndex(where: { $0.engine == engine }) else {
            return
        }

        let jobID = beginAIJob(engine: engine, symbol: "CLI", purpose: "연결 테스트")
        defer { finishAIJob(jobID) }

        aiEngines[index].lastStatus = "실행 중"
        do {
            let output = try await aiRunner.run(command: aiEngines[index].versionCommand, stdin: "")
            aiEngines[index].lastStatus = output
        } catch {
            aiEngines[index].lastStatus = error.localizedDescription
        }
        saveAppState()
    }

    func runLiveOrderReadinessCheck() async {
        guard !isLiveOrderReadinessChecking else {
            return
        }
        isLiveOrderReadinessChecking = true
        liveOrderReadinessCheckStatus = "점검 중입니다..."
        defer {
            isLiveOrderReadinessChecking = false
        }

        do {
            guard credentials.isComplete else {
                throw TossInvestClientError.emptyCredentials
            }

            let accessToken = try await validAccessToken()
            if accounts.isEmpty {
                accounts = try await client.accounts(accessToken: accessToken)
            }
            if selectedAccountSeq == nil {
                selectedAccountSeq = accounts.first?.accountSeq
            }
            guard let selectedAccountSeq else {
                throw TossInvestClientError.httpStatus(0, "계좌 목록을 불러오지 못했습니다.")
            }

            let selectedAccount = accounts.first { $0.accountSeq == selectedAccountSeq }
            let krwPower = try await client.buyingPower(
                accountSeq: selectedAccountSeq,
                currency: "KRW",
                accessToken: accessToken
            )
            let usdPower = try? await client.buyingPower(
                accountSeq: selectedAccountSeq,
                currency: "USD",
                accessToken: accessToken
            )
            let exchangeRate = try? await client.exchangeRate(
                baseCurrency: "USD",
                quoteCurrency: "KRW",
                accessToken: accessToken
            )

            var lines: [String] = []
            lines.append("토큰 발급 성공")
            lines.append("계좌 확인: \(selectedAccount?.accountNo ?? "\(selectedAccountSeq)") \(selectedAccount?.accountTypeTitle ?? "")")
            lines.append("KRW 매수 가능: \(formattedDouble(NSDecimalNumber(decimal: krwPower.cashBuyingPowerValue).doubleValue, fractionDigits: 0))원")
            if let usdPower {
                lines.append("USD 매수 가능: \(formattedDouble(NSDecimalNumber(decimal: usdPower.cashBuyingPowerValue).doubleValue, fractionDigits: 2))달러")
            } else {
                lines.append("USD 매수 가능 금액 조회는 실패했습니다. 해외주식 주문 전 다시 확인하세요.")
            }
            if let exchangeRate {
                lines.append("환율 확인: 1 USD = \(formattedDouble(NSDecimalNumber(decimal: exchangeRate.rateValue).doubleValue, fractionDigits: 2)) KRW")
            } else {
                lines.append("환율 조회는 실패했습니다. 해외주식 원화 예산 주문 전 다시 확인하세요.")
            }
            if safetySettings.allowLiveOrders {
                lines.append("라이브 주문 허용: 켜짐")
            } else {
                lines.append("라이브 주문 허용: 꺼짐. 실제 주문은 차단됩니다.")
            }
            if !liveOrderReadinessWarnings.isEmpty {
                lines.append("남은 확인: \(liveOrderReadinessWarnings.joined(separator: " / "))")
            }
            lines.append("이 점검은 실제 주문을 제출하지 않았습니다.")

            liveOrderReadinessCheckStatus = lines.joined(separator: "\n")
            appendOrderLog(
                symbol: selectedSymbol,
                strategyName: "실주문 연결 점검",
                mode: .alertOnly,
                event: "토큰, 계좌, 매수 가능 금액, 환율을 확인했습니다.",
                aiReview: "AI 검토 없음",
                orderRequest: "주문 제출 없음",
                result: liveOrderReadinessCheckStatus,
                isLiveOrder: false
            )
            saveAppState()
        } catch {
            if let clientError = error as? TossInvestClientError,
               case let .rateLimited(_, retryAfterSeconds) = clientError {
                let seconds = max(10, retryAfterSeconds ?? 60)
                apiCooldownUntil = Date().addingTimeInterval(TimeInterval(seconds))
            }
            liveOrderReadinessCheckStatus = "점검 실패: \(error.localizedDescription)"
            appendOrderLog(
                symbol: selectedSymbol,
                strategyName: "실주문 연결 점검",
                mode: .alertOnly,
                event: "실주문 연결 점검 실패",
                aiReview: "AI 검토 없음",
                orderRequest: "주문 제출 없음",
                result: liveOrderReadinessCheckStatus,
                isLiveOrder: false
            )
            saveAppState()
        }
    }

    private func beginAIJob(engine: AIEngineKind, symbol: String, purpose: String) -> ActiveAIJob.ID {
        let job = ActiveAIJob(engine: engine, symbol: symbol, purpose: purpose)
        activeAIJobs.append(job)
        return job.id
    }

    private func finishAIJob(_ id: ActiveAIJob.ID) {
        activeAIJobs.removeAll { $0.id == id }
    }

    private func validAccessToken() async throws -> String {
        if let token, token.isValid {
            return token.accessToken
        }

        let response = try await client.issueToken(credentials: credentials)
        let snapshot = TokenSnapshot(
            accessToken: response.accessToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(response.expiresIn))
        )
        token = snapshot
        return snapshot.accessToken
    }

    private func mergeStockInfos(_ stocks: [StockInfo]) {
        for stock in stocks {
            let item = StockSearchItem(
                symbol: stock.symbol,
                name: stock.name,
                englishName: stock.englishName,
                market: stock.market,
                currency: stock.currency,
                aliases: []
            )
            if let index = stockDirectory.firstIndex(where: { $0.symbol.caseInsensitiveCompare(stock.symbol) == .orderedSame }) {
                stockDirectory[index].name = stock.name
                stockDirectory[index].englishName = stock.englishName
                stockDirectory[index].market = stock.market
                stockDirectory[index].currency = stock.currency
            } else {
                stockDirectory.append(item)
            }
        }
    }

    private func marketActivitySymbols() -> [String] {
        var seen = Set<String>()
        let candidates = stockDirectory.map(\.symbol) + watchedSymbols + [selectedSymbol]
        let uniqueSymbols = candidates.compactMap { symbol -> String? in
            let normalized = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard !normalized.isEmpty, !seen.contains(normalized) else {
                return nil
            }
            seen.insert(normalized)
            return normalized
        }
        return Array(uniqueSymbols.prefix(200))
    }

    private func marketDataSymbols() -> [String] {
        var seen = Set<String>()
        let strategySymbols = strategies.filter(\.isEnabled).map(\.symbol)
        let alertSymbols = priceAlerts.filter(\.isEnabled).map(\.symbol)
        let candidates = watchedSymbols + [selectedSymbol] + strategySymbols + alertSymbols
        let uniqueSymbols = candidates.compactMap { symbol -> String? in
            let normalized = symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard !normalized.isEmpty, !seen.contains(normalized) else {
                return nil
            }
            seen.insert(normalized)
            return normalized
        }
        return uniqueSymbols.isEmpty ? [selectedSymbol] : uniqueSymbols
    }

    private func mechanicalStrategySymbols() -> [String] {
        var seen = Set<String>()
        return strategies.compactMap { strategy -> String? in
            guard strategy.isEnabled,
                  strategy.conditions.contains(where: { $0.note.hasPrefix("MECH:") }) else {
                return nil
            }
            let normalized = strategy.symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
            guard !normalized.isEmpty, !seen.contains(normalized) else {
                return nil
            }
            seen.insert(normalized)
            return normalized
        }
    }

    private func automationCandleCacheKey(symbol: String) -> String {
        "\(symbol.uppercased())|automation-1m"
    }

    private func candlesForStrategy(_ strategy: TradingStrategy, override candlesBySymbol: [String: [Candle]]) -> [Candle] {
        let normalized = strategy.symbol.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if let candles = candlesBySymbol[normalized] {
            return candles
        }
        if let candles = strategyCandleCache[automationCandleCacheKey(symbol: normalized)] {
            return candles
        }
        if selectedSymbol.caseInsensitiveCompare(strategy.symbol) == .orderedSame, chartTimeframe.isMinute {
            return candles
        }
        return []
    }

    private func updateAutomationMonitor() {
        automationMonitorTask?.cancel()
        automationMonitorTask = nil

        guard automationEnabled else {
            nextAutomationScanAt = nil
            return
        }

        nextAutomationScanAt = Date()
        automationMonitorTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.runAutomationScan()
                guard !Task.isCancelled else {
                    break
                }
                try? await Task.sleep(nanoseconds: 60_000_000_000)
            }
        }
    }

    private func marketTradeVolume(from trades: [Trade], fallback: Decimal?) -> Decimal? {
        guard !trades.isEmpty else {
            return fallback
        }
        return trades.reduce(Decimal(0)) { partialResult, trade in
            partialResult + trade.volumeValue
        }
    }

    private func marketTradeValue(from trades: [Trade], price: PriceResponse) -> Decimal? {
        if trades.isEmpty {
            guard let volume = price.volumeValue else {
                return nil
            }
            return price.lastPriceValue * volume
        }

        return trades.reduce(Decimal(0)) { partialResult, trade in
            partialResult + trade.tradeValue
        }
    }

    private func conditionTriggered(_ condition: StrategyCondition, strategy: TradingStrategy, currentPrice: Double, candles strategyCandles: [Candle]) -> Bool {
        if condition.note.hasPrefix("MECH:") {
            guard strategyCandles.count >= 3 else {
                return false
            }
            return MechanicalSignalEngine.latestSignal(candles: strategyCandles.sorted { $0.date < $1.date }, note: condition.note)
        }

        switch condition.metric {
        case .priceBelow:
            return currentPrice <= condition.threshold
        case .priceAbove:
            return currentPrice >= condition.threshold
        case .dropPercent:
            guard strategy.referencePrice > 0 else { return false }
            return ((strategy.referencePrice - currentPrice) / strategy.referencePrice) * 100 >= condition.threshold
        case .gainPercent:
            guard strategy.referencePrice > 0 else { return false }
            return ((currentPrice - strategy.referencePrice) / strategy.referencePrice) * 100 >= condition.threshold
        case .profitRateBelow:
            guard strategy.referencePrice > 0 else { return false }
            return ((currentPrice - strategy.referencePrice) / strategy.referencePrice) * 100 <= condition.threshold
        case .profitRateAbove:
            guard strategy.referencePrice > 0 else { return false }
            return ((currentPrice - strategy.referencePrice) / strategy.referencePrice) * 100 >= condition.threshold
        }
    }

    private func evaluateStopTakeProfit(strategy: TradingStrategy, currentPrice: Double, currency: String) {
        guard strategy.referencePrice > 0 else {
            return
        }
        let rate = ((currentPrice - strategy.referencePrice) / strategy.referencePrice) * 100
        if rate <= strategy.stopLossPercent {
            handleRiskThreshold(
                strategy: strategy,
                title: "손절 조건 접근",
                rate: rate,
                currentPrice: currentPrice,
                currency: currency,
                metric: .profitRateBelow
            )
        }
        if rate >= strategy.takeProfitPercent {
            handleRiskThreshold(
                strategy: strategy,
                title: "익절 조건 접근",
                rate: rate,
                currentPrice: currentPrice,
                currency: currency,
                metric: .profitRateAbove
            )
        }
    }

    private func handleRiskThreshold(
        strategy: TradingStrategy,
        title: String,
        rate: Double,
        currentPrice: Double,
        currency: String,
        metric: TriggerMetric
    ) {
        guard !recentlyLogged(strategyName: "\(strategy.name)-\(title)", symbol: strategy.symbol, cooldownMinutes: strategy.cooldownMinutes) else {
            return
        }
        let availableQuantity = holdingQuantity(for: strategy.symbol) ?? 0
        let createsSellDraft = availableQuantity > 0 && strategy.mode != .alertOnly
        let condition = StrategyCondition(
            metric: metric,
            threshold: rate,
            action: createsSellDraft ? .sell : .notify,
            amount: 0,
            quantity: createsSellDraft ? availableQuantity : 0,
            orderType: .limit,
            note: title
        )
        let preflight = createsSellDraft ? preflightWarnings(
            strategy: strategy,
            condition: condition,
            currentPrice: currentPrice,
            currency: currency
        ) : []
        let aiReview = strategy.mode == .aiReviewMode ? "손절/익절 전 AI 검토가 필요합니다." : "손절/익절 자동 점검"
        var autoSubmitDraft: PendingOrderDraft?
        let result: String

        switch strategy.mode {
        case .alertOnly:
            result = "알림 모드입니다. 매도 주문 후보는 만들지 않았습니다."
        case .confirmBeforeOrder:
            result = createsSellDraft ? "보유 수량 \(formattedDouble(availableQuantity, fractionDigits: 4))주 매도 후보를 만들고 사용자 승인을 기다립니다. \(preflight.joined(separator: " "))" : "보유 수량이 없어 알림만 남겼습니다."
        case .aiReviewMode:
            result = createsSellDraft ? "AI 검토 후 제출할 매도 후보를 만들었습니다. \(preflight.joined(separator: " "))" : "보유 수량이 없어 알림만 남겼습니다."
        case .autoOrder:
            if createsSellDraft, safetySettings.allowLiveOrders, preflight.isEmpty {
                result = "손절/익절 매도 후보가 안전 관문을 통과해 실주문 제출을 시도합니다."
            } else if createsSellDraft {
                result = "손절/익절 매도 후보가 안전장치에 의해 차단되었습니다. \(preflight.joined(separator: " "))"
            } else {
                result = "보유 수량이 없어 알림만 남겼습니다."
            }
        }

        if createsSellDraft {
            let draft = createPendingOrder(
                strategy: strategy,
                condition: condition,
                currentPrice: currentPrice,
                currency: currency,
                sourceEvent: title,
                safetyWarnings: preflight,
                aiReview: aiReview
            )
            if strategy.mode == .autoOrder, safetySettings.allowLiveOrders, preflight.isEmpty {
                autoSubmitDraft = draft
            }
        }

        appendOrderLog(
            symbol: strategy.symbol,
            strategyName: "\(strategy.name)-\(title)",
            mode: strategy.mode,
            event: "\(title): 현재 수익률 \(String(format: "%+.2f%%", rate)), 가격 \(formattedDouble(currentPrice, fractionDigits: 2)) \(currency)",
            aiReview: aiReview,
            orderRequest: createsSellDraft ? draftOrderDescription(strategy: strategy, condition: condition, currentPrice: currentPrice, currency: currency) : "주문 없음",
            result: result.trimmingCharacters(in: .whitespacesAndNewlines),
            isLiveOrder: false
        )
        notifications.post(title: title, body: "\(strategy.name): \(String(format: "%+.2f%%", rate))")
        if let autoSubmitDraft {
            Task {
                await submitPendingOrder(autoSubmitDraft)
            }
        }
    }

    private func handleTrigger(strategy: TradingStrategy, condition: StrategyCondition, currentPrice: Double, currency: String) {
        guard !recentlyLogged(strategyName: strategy.name, symbol: strategy.symbol, cooldownMinutes: strategy.cooldownMinutes, includeBlocked: false) else {
            return
        }

        let orderRequest = draftOrderDescription(
            strategy: strategy,
            condition: condition,
            currentPrice: currentPrice,
            currency: currency
        )
        let preflight = preflightWarnings(
            strategy: strategy,
            condition: condition,
            currentPrice: currentPrice,
            currency: currency
        )
        let aiReview = strategy.mode == .aiReviewMode ? "주문 실행 전 AI 검토가 필요합니다." : "AI 검토 없음"
        let result: String
        let isLiveOrder: Bool
        var autoSubmitDraft: PendingOrderDraft?

        switch strategy.mode {
        case .alertOnly:
            result = "알림 모드입니다. 주문은 생성하지 않았습니다."
            isLiveOrder = false
        case .confirmBeforeOrder:
            result = "사용자 승인을 기다립니다. \(preflight.joined(separator: " "))"
            isLiveOrder = false
        case .aiReviewMode:
            result = "AI 검토 대기 상태입니다. \(preflight.joined(separator: " "))"
            isLiveOrder = false
        case .autoOrder:
            if safetySettings.allowLiveOrders && preflight.isEmpty {
                result = "라이브 주문 안전 관문을 통과했습니다. 실주문 제출을 시도합니다."
                isLiveOrder = false
            } else {
                result = "안전장치에 의해 차단되었습니다. \(preflight.joined(separator: " "))"
                isLiveOrder = false
            }
        }

        if condition.action != .notify, strategy.mode != .alertOnly {
            let draft = createPendingOrder(
                strategy: strategy,
                condition: condition,
                currentPrice: currentPrice,
                currency: currency,
                sourceEvent: "\(condition.metric.title) 조건 충족",
                safetyWarnings: preflight,
                aiReview: aiReview
            )
            if strategy.mode == .autoOrder, safetySettings.allowLiveOrders, preflight.isEmpty {
                autoSubmitDraft = draft
            }
        }

        appendOrderLog(
            symbol: strategy.symbol,
            strategyName: strategy.name,
            mode: strategy.mode,
            event: "\(condition.metric.title) 조건 충족: \(formattedDouble(currentPrice, fractionDigits: 2))",
            aiReview: aiReview,
            orderRequest: orderRequest,
            result: result.trimmingCharacters(in: .whitespacesAndNewlines),
            isLiveOrder: isLiveOrder
        )
        notifications.post(title: "전략 조건 충족", body: "\(strategy.name): \(condition.metric.title)")
        if let autoSubmitDraft {
            Task {
                await submitPendingOrder(autoSubmitDraft)
            }
        }
    }

    @discardableResult
    private func createPendingOrder(
        strategy: TradingStrategy,
        condition: StrategyCondition,
        currentPrice: Double,
        currency: String,
        sourceEvent: String,
        safetyWarnings: [String],
        aiReview: String
    ) -> PendingOrderDraft {
        let draft = PendingOrderDraft(
            strategyName: strategy.name,
            symbol: strategy.symbol,
            side: condition.action,
            orderType: normalizedOrderType(for: condition, currency: currency),
            amount: condition.amount,
            amountCurrency: condition.amount > 0 ? inputAmountCurrency(for: currency) : nil,
            quantity: condition.quantity,
            referencePrice: currentPrice,
            currency: currency,
            mode: strategy.mode,
            sourceEvent: sourceEvent,
            safetyWarnings: safetyWarnings,
            aiReview: aiReview,
            status: safetyWarnings.isEmpty ? .pendingReview : .blocked,
            submittedOrderId: nil
        )
        pendingOrders.insert(draft, at: 0)
        let title = draft.status == .blocked ? "주문 후보가 차단되었습니다" : "승인 대기 주문이 생겼습니다"
        notifications.post(title: title, body: draft.orderSummary)
        return draft
    }

    private func appendOrderLog(
        symbol: String,
        strategyName: String,
        mode: OperationMode,
        event: String,
        aiReview: String,
        orderRequest: String,
        result: String,
        isLiveOrder: Bool
    ) {
        orderLogs.insert(
            OrderLogEntry(
                symbol: symbol,
                strategyName: strategyName,
                mode: mode,
                event: cleanedLogText(event),
                aiReview: aiReview,
                orderRequest: cleanedLogText(orderRequest),
                result: cleanedLogText(result.trimmingCharacters(in: .whitespacesAndNewlines)),
                isLiveOrder: isLiveOrder
            ),
            at: 0
        )
    }

    private func preflightWarnings(strategy: TradingStrategy, condition: StrategyCondition, currentPrice: Double, currency: String) -> [String] {
        var warnings: [String] = []
        let effectiveOrderType = normalizedOrderType(for: condition, currency: currency)
        if condition.action == .buy, condition.amount > safetySettings.dailyBuyLimit {
            warnings.append("일일 매수 한도를 초과했습니다.")
        }
        if condition.action == .buy, strategy.maxDailyAmount > safetySettings.dailyBuyLimit {
            warnings.append("전략 일일 한도가 전체 한도를 초과합니다.")
        }
        if condition.action == .buy,
           condition.amount > 0,
           condition.amount + pendingBuyAmountToday(strategyName: strategy.name, symbol: strategy.symbol) > strategy.maxDailyAmount {
            warnings.append("이 주문을 더하면 전략의 하루 매수 한도를 넘습니다.")
        }
        if condition.action == .buy,
           currency.uppercased() == "KRW",
           condition.quantity <= 0,
           condition.amount > 0,
           currentPrice > 0,
           floor(condition.amount / currentPrice) < 1 {
            warnings.append("예산이 현재가보다 작아 1주도 살 수 없습니다.")
        }
        if condition.action == .sell,
           condition.quantity > 0,
           let availableQuantity = holdingQuantity(for: strategy.symbol),
           condition.quantity > availableQuantity {
            warnings.append("매도 수량이 보유 수량 \(formattedDouble(availableQuantity, fractionDigits: 4))주보다 큽니다.")
        }
        if condition.action == .sell,
           condition.quantity <= 0,
           condition.amount > 0 {
            warnings.append("매도 주문은 금액이 아니라 보유 수량 기준으로 제출해야 합니다.")
        }
        if condition.action == .buy,
           let projectedPercent = projectedPositionPercent(symbol: strategy.symbol, currency: currency, condition: condition, currentPrice: currentPrice),
           projectedPercent > safetySettings.maxPositionPercent {
            warnings.append("주문 후 해당 종목 비중이 약 \(formattedDouble(projectedPercent, fractionDigits: 1))%로 설정 한도를 넘을 수 있습니다.")
        }
        if safetySettings.warnLeveragedProducts,
           isLeveragedOrInverseProduct(symbol: strategy.symbol) {
            warnings.append("레버리지/인버스 가능성이 있는 종목입니다. 자동 주문 전 확인하세요.")
        }
        if effectiveOrderType == .market && safetySettings.requireMarketOrderConfirmation && strategy.mode == .autoOrder {
            warnings.append("시장가 자동주문은 추가 확인 설정 때문에 차단됩니다. 자동 제출하려면 설정에서 시장가 주문 추가 확인을 끄거나 승인 후 주문을 사용하세요.")
        }
        if condition.action != .notify,
           safetySettings.blockDuplicateOrders,
           hasRecentOrderIntent(symbol: strategy.symbol, side: condition.action, seconds: safetySettings.orderCooldownSeconds) {
            warnings.append("최근 같은 종목·방향 주문 후보가 있어 중복 주문을 차단합니다.")
        }
        if safetySettings.blockOnNetworkFailure, case .failed = connectionState {
            warnings.append("네트워크/API 오류 상태에서는 주문을 차단합니다.")
        }
        if strategy.mode == .autoOrder, !safetySettings.allowLiveOrders {
            warnings.append("라이브 주문 스위치가 꺼져 있습니다.")
        }
        if strategy.mode == .autoOrder,
           strategy.riskNotes.localizedStandardContains("Berkshire Guard"),
           !strategy.riskNotes.localizedStandardContains("완전 자동 가능") {
            warnings.append("Berkshire Guard가 완전 자동을 허용하지 않은 전략입니다. 승인 후 주문으로 확인하세요.")
        }
        if strategy.mode == .autoOrder, safetySettings.allowLiveOrders {
            if !credentials.isComplete || selectedAccountSeq == nil {
                warnings.append("API 인증 정보 또는 선택 계좌가 없어 실주문을 차단합니다.")
            }
            if condition.action != .notify, condition.quantity <= 0, condition.amount <= 0 {
                warnings.append("주문 수량 또는 금액이 없습니다.")
            }
            if currency.uppercased() == "USD",
               condition.quantity <= 0,
               !(condition.action == .buy && effectiveOrderType == .market) {
                warnings.append("해외주식 금액 자동주문은 시장가 매수만 허용됩니다. 지정가/매도는 수량을 입력하세요.")
            }
        }
        return warnings
    }

    private func recentlyLogged(strategyName: String, symbol: String, cooldownMinutes: Int, includeBlocked: Bool = true) -> Bool {
        guard let recent = orderLogs.first(where: { $0.strategyName == strategyName && $0.symbol == symbol }) else {
            return false
        }
        if !includeBlocked, recent.result.localizedStandardContains("차단") {
            return false
        }
        return Date().timeIntervalSince(recent.date) < TimeInterval(cooldownMinutes * 60)
    }

    private func hasRecentOrderIntent(symbol: String, side: StrategyAction, seconds: Int) -> Bool {
        let cutoff = Date().addingTimeInterval(-TimeInterval(max(1, seconds)))
        let activeStatuses: Set<PendingOrderStatus> = [.pendingReview, .submitted]
        if pendingOrders.contains(where: { draft in
            draft.symbol.caseInsensitiveCompare(symbol) == .orderedSame &&
                draft.side == side &&
                activeStatuses.contains(draft.status) &&
                draft.createdAt >= cutoff
        }) {
            return true
        }

        return orderLogs.contains { log in
            log.symbol.caseInsensitiveCompare(symbol) == .orderedSame &&
                log.date >= cutoff &&
                log.orderRequest.contains(side.title) &&
                !log.result.contains("알림 모드")
        }
    }

    private func pendingBuyAmountToday(strategyName: String, symbol: String) -> Double {
        let calendar = Calendar.current
        return pendingOrders.reduce(0) { total, draft in
            guard draft.strategyName == strategyName,
                  draft.symbol.caseInsensitiveCompare(symbol) == .orderedSame,
                  draft.side == .buy,
                  draft.status != .canceled,
                  calendar.isDate(draft.createdAt, inSameDayAs: Date()) else {
                return total
            }
            return total + draft.amount
        }
    }

    private func holdingQuantity(for symbol: String) -> Double? {
        holdings.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
            .map { NSDecimalNumber(decimal: decimalValue($0.quantity)).doubleValue }
    }

    private func holdingCurrency(for symbol: String) -> String? {
        holdings.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }?.currency
    }

    private func holdingValue(for symbol: String) -> Double {
        holdings
            .filter { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
            .reduce(0.0) { total, holding in
                total + NSDecimalNumber(decimal: decimalValue(holding.value)).doubleValue
            }
    }

    private func priceCurrency(for symbol: String) -> String? {
        prices.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }?.currency
    }

    private func currentPriceForOrder(symbol: String, fallback: Double) -> Double {
        if let price = prices.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
            let value = NSDecimalNumber(decimal: price.lastPriceValue).doubleValue
            if value > 0 {
                return value
            }
        }

        if let quantity = holdingQuantity(for: symbol), quantity > 0 {
            let value = holdingValue(for: symbol)
            if value > 0 {
                return value / quantity
            }
        }

        return fallback
    }

    private func projectedPositionPercent(symbol: String, currency: String, condition: StrategyCondition, currentPrice: Double) -> Double? {
        let orderValue: Double
        if condition.amount > 0 {
            orderValue = condition.amount
        } else if condition.quantity > 0, currentPrice > 0 {
            orderValue = condition.quantity * currentPrice
        } else {
            return nil
        }

        let sameCurrencyHoldings = holdings.filter {
            $0.currency.caseInsensitiveCompare(currency) == .orderedSame
        }
        let totalValue = sameCurrencyHoldings.reduce(0.0) { total, holding in
            total + NSDecimalNumber(decimal: decimalValue(holding.value)).doubleValue
        }
        let currentValue = sameCurrencyHoldings
            .filter { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
            .reduce(0.0) { total, holding in
                total + NSDecimalNumber(decimal: decimalValue(holding.value)).doubleValue
            }
        let projectedTotal = totalValue + orderValue
        guard projectedTotal > 0 else {
            return nil
        }
        return ((currentValue + orderValue) / projectedTotal) * 100
    }

    private func isLeveragedOrInverseProduct(symbol: String) -> Bool {
        let searchable = "\(symbol) \(stockName(for: symbol) ?? "")".lowercased()
        let keywords = [
            "레버리지",
            "인버스",
            "2x",
            "3x",
            "inverse",
            "leveraged",
            "ultra",
            "bull",
            "bear"
        ]
        return keywords.contains { searchable.contains($0) }
    }

    private func draftOrderDescription(strategy: TradingStrategy, condition: StrategyCondition, currentPrice: Double, currency: String) -> String {
        switch condition.action {
        case .notify:
            return "\(strategy.symbol) \(formattedDouble(currentPrice, fractionDigits: 2)) \(currency) 알림만 생성"
        case .buy, .sell:
            let side = condition.action == .buy ? "매수" : "매도"
            let effectiveOrderType = normalizedOrderType(for: condition, currency: currency)
            let amountCurrency = inputAmountCurrency(for: currency)
            let quantity = condition.quantity > 0 ? "수량 \(formattedDouble(condition.quantity, fractionDigits: 4))" : "금액 \(formattedDouble(condition.amount, fractionDigits: amountCurrency == "KRW" ? 0 : 2)) \(amountCurrency)"
            return "\(side) \(strategy.symbol) \(effectiveOrderType.title) \(quantity), 기준가 \(formattedDouble(currentPrice, fractionDigits: 2)) \(currency)"
        }
    }

    private func normalizedOrderType(for condition: StrategyCondition, currency: String) -> DraftOrderType {
        if currency.uppercased() == "USD",
           condition.action == .buy,
           condition.quantity <= 0,
           condition.amount > 0 {
            return .market
        }
        return condition.orderType
    }

    private func inputAmountCurrency(for currency: String) -> String {
        currency.uppercased() == "KRW" ? "KRW" : "KRW"
    }

    private func watchlistBriefPrompt() -> String {
        let watchedLines = watchedSymbols.map { symbol -> String in
            let name = stockName(for: symbol) ?? symbol
            let price = prices.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
            let priceText = price.map { "\($0.lastPrice) \($0.currency)" } ?? "현재가 없음"
            let strategyCount = strategies.filter { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }.count
            let holding = holdings.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
            let holdingText = holding.map { "보유 \($0.quantity)주, 평가 \($0.value) \($0.currency), 손익 \($0.profitLoss)" } ?? "보유 없음"
            return "- \(name) (\(symbol)): \(priceText), 전략 \(strategyCount)개, \(holdingText)"
        }.joined(separator: "\n")

        let marketLines = marketActivities.prefix(8).map { row in
            let value = row.tradeValue.map { compactDecimal($0, fractionDigits: 1) } ?? "-"
            return "- \(row.name) (\(row.symbol)): 현재가 \(row.lastPrice) \(row.currency), 거래대금 \(value)"
        }.joined(separator: "\n")

        let holdingLines = holdings.prefix(8).map { holding in
            "- \(holding.name) (\(holding.symbol)): 수량 \(holding.quantity), 평가 \(holding.value) \(holding.currency), 손익 \(holding.profitLoss)"
        }.joined(separator: "\n")

        let alertLines = priceAlerts.prefix(10).map { alert in
            "- \(alert.name) (\(alert.symbol)): \(alert.conditionText), 상태=\(alert.isEnabled ? "켜짐" : "꺼짐")"
        }.joined(separator: "\n")

        return """
        당신은 초보 투자자를 돕는 주식 자동매매 보조 분석가입니다. 투자 수익을 보장하거나 확정적인 매수·매도 지시를 하지 마세요.

        사용자 성향:
        국가=\(investorProfile.country)
        목표=\(investorProfile.primaryGoal)
        위험성향=\(investorProfile.riskTolerance.title) - \(investorProfile.riskTolerance.detail)
        선호 업종=\(investorProfile.preferredIndustries)

        관심종목:
        \(watchedLines.isEmpty ? "- 없음" : watchedLines)

        보유종목:
        \(holdingLines.isEmpty ? "- 없음" : holdingLines)

        가격 알림:
        \(alertLines.isEmpty ? "- 없음" : alertLines)

        거래대금 상위 참고:
        \(marketLines.isEmpty ? "- 없음" : marketLines)

        자동매매 상태:
        자동감시=\(automationEnabled)
        라이브주문허용=\(safetySettings.allowLiveOrders)
        활성전략=\(activeStrategyCount)개
        승인대기=\(pendingOrderCount)건
        데이터검증=\(marketActivityQualityText)

        출력 규칙:
        - 한국어 일반 텍스트로만 작성하세요.
        - 웹 검색, 외부 링크, 실행 로그, 모델명, 토큰 사용량을 쓰지 마세요.
        - 초보자가 바로 이해하도록 짧은 문장으로 씁니다.
        - 아래 제목 5개를 정확히 쓰세요.

        오늘 한 줄
        먼저 볼 종목
        조심할 점
        자동매매 확인
        다음 행동
        """
    }

    private func analysisPrompt(symbol: String, userPrompt: String) -> String {
        let price = prices.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame })
        let strategiesForSymbol = strategies.filter { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
        return """
        당신은 주식 자동매매 전략을 검토하는 보조 분석가입니다. 투자 수익을 보장하거나 확정적인 매수/매도 지시를 하지 마세요.

        종목: \(symbol)
        최근가: \(price?.lastPrice ?? "알 수 없음") \(price?.currency ?? "")
        활성 전략:
        \(strategiesForSymbol.map { "- \($0.name), 모드=\($0.mode.title), 상태=\($0.enabledLabel), 손절=\($0.stopLossPercent), 익절=\($0.takeProfitPercent)" }.joined(separator: "\n"))

        안전 설정:
        일일매수한도=\(safetySettings.dailyBuyLimit)
        일일손실한도=\(safetySettings.dailyLossLimit)
        종목최대비중=\(safetySettings.maxPositionPercent)
        라이브주문허용=\(safetySettings.allowLiveOrders)
        사용자 성향=\(investorProfile.riskTolerance.title), 목표=\(investorProfile.primaryGoal), 선호 업종=\(investorProfile.preferredIndustries)

        사용자 요청:
        \(userPrompt)

        작성 규칙:
        - 초보 투자자가 읽는다고 생각하고 쉬운 한국어로 설명하세요.
        - 앱이 제공한 값만 기준으로 판단하세요. 웹 검색, 외부 기사 링크, 내부 실행 로그는 쓰지 마세요.
        - 토큰 사용량, workdir, model, provider, prompt 원문, 명령어 실행 기록은 절대 출력하지 마세요.
        - 확정적인 매수·매도 지시 대신 확인할 조건과 위험을 말하세요.
        - AI Berkshire 방식처럼 먼저 결론을 통과/조건부/보류/제외 중 하나로 분명히 말하세요.
        - 데이터 신뢰도를 A/B/C로 표시하고, 숫자가 부족하면 추측하지 말고 부족하다고 쓰세요.
        - 반대 논리와 빠른 제외 사유가 있는지 꼭 점검하세요.
        - 자동매매 허용 여부를 허용/승인필요/차단 중 하나로 적으세요.
        - 마크다운 표는 쓰지 마세요.
        - 아래 제목 4개를 정확히 쓰고, 제목마다 2~4개의 짧은 문장으로 작성하세요.

        요약
        주요 위험
        손절/익절 점검
        더 안전한 조건 제안
        """
    }

    private func parseStrategyInput(_ input: String) -> (name: String, symbol: String, referencePrice: Double, maxDailyAmount: Double, conditions: [StrategyCondition]) {
        let symbol = resolveSymbol(from: input)
        let percentages = extractNumbers(before: "%", in: input)
        let amounts = extractKoreanAmounts(in: input)
        let referencePrice = NSDecimalNumber(decimal: prices.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame })?.lastPriceValue ?? 0).doubleValue

        var conditions: [StrategyCondition] = []
        let count = max(percentages.count, amounts.count, 1)
        for index in 0..<count {
            let threshold = percentages.indices.contains(index) ? percentages[index] : Double(index + 1) * 3
            let amount = amounts.indices.contains(index) ? amounts[index] : 0
            conditions.append(
                StrategyCondition(
                    metric: .dropPercent,
                    threshold: threshold,
                    action: .buy,
                    amount: amount,
                    quantity: 0,
                    orderType: .limit,
                    note: "\(index + 1)차 조건"
                )
            )
        }

        let parsedTotalAmount = amounts.reduce(0, +)
        let totalAmount = parsedTotalAmount > 0 ? parsedTotalAmount : safetySettings.dailyBuyLimit
        return (
            name: "\(stockName(for: symbol) ?? symbol) 자연어 전략",
            symbol: symbol,
            referencePrice: referencePrice,
            maxDailyAmount: totalAmount,
            conditions: conditions
        )
    }

    private func extractNumbers(before marker: String, in text: String) -> [Double] {
        let pattern = #"([0-9]+(?:\.[0-9]+)?)\s*\#(marker)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let valueRange = Range(match.range(at: 1), in: text) else {
                return nil
            }
            return Double(text[valueRange])
        }
    }

    private func extractKoreanAmounts(in text: String) -> [Double] {
        let pattern = #"([0-9]+(?:\.[0-9]+)?)\s*(만|만원|억|억원|달러|원)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard
                let valueRange = Range(match.range(at: 1), in: text),
                let unitRange = Range(match.range(at: 2), in: text),
                let value = Double(text[valueRange])
            else {
                return nil
            }
            let unit = String(text[unitRange])
            switch unit {
            case "억", "억원":
                return value * 100_000_000
            case "만", "만원":
                return value * 10_000
            default:
                return value
            }
        }
    }

    private func heuristicRiskScore(_ text: String) -> Int {
        let lower = text.lowercased()
        let keywords = ["risk", "위험", "손실", "volatile", "변동", "market order", "시장가", "leverage", "레버리지"]
        let hits = keywords.reduce(0) { count, keyword in
            count + (lower.contains(keyword.lowercased()) ? 1 : 0)
        }
        return min(100, 25 + hits * 10)
    }

    private func formatRate(_ decimalText: String) -> String {
        let rate = NSDecimalNumber(decimal: decimalValue(decimalText)).doubleValue * 100
        return String(format: "%+.2f%%", rate)
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

private func commandEnvironmentWithCLIPaths() -> [String: String] {
    var environment = ProcessInfo.processInfo.environment
    let fileManager = FileManager.default
    let home = fileManager.homeDirectoryForCurrentUser
    var paths = [
        home.appending(path: ".local/bin").path,
        home.appending(path: ".nvm/current/bin").path,
        "/opt/homebrew/bin",
        "/opt/homebrew/sbin",
        "/usr/local/bin",
        "/usr/local/sbin",
        "/usr/bin",
        "/bin",
        "/usr/sbin",
        "/sbin"
    ]

    let nvmVersions = home.appending(path: ".nvm/versions/node", directoryHint: .isDirectory)
    if let versions = try? fileManager.contentsOfDirectory(
        at: nvmVersions,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles]
    ) {
        let nodeBins = versions
            .filter { url in
                ((try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false)
            }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedDescending }
            .map { $0.appending(path: "bin").path }
        paths.insert(contentsOf: nodeBins, at: 0)
    }

    let existingPath = environment["PATH"] ?? ""
    let combined = (paths + existingPath.split(separator: ":").map(String.init))
        .filter { !$0.isEmpty }
        .reduce(into: [String]()) { result, path in
            if !result.contains(path) {
                result.append(path)
            }
        }
        .joined(separator: ":")
    environment["PATH"] = combined
    return environment
}
