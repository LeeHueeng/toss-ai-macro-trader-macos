import Charts
import SwiftUI

struct AppShell: View {
    @EnvironmentObject private var session: AppSession
    @State private var showsCommandPalette = false

    var body: some View {
        NavigationSplitView {
            List(SidebarSection.allCases, selection: $session.selectedSection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
        }
        .navigationSplitViewColumnWidth(min: 190, ideal: 220)
        } detail: {
            VStack(spacing: 0) {
                if session.automationEnabled || session.pendingOrderCount > 0 || session.isAutoRebalancing {
                    GlobalAutomationStatusBar()
                        .environmentObject(session)
                    Divider()
                }

                if session.isAIRunning {
                    GlobalAIActivityBar(jobs: session.activeAIJobs)
                    Divider()
                }

                Group {
                    switch session.selectedSection {
                    case .dashboard:
                        DashboardView()
                    case .strategyManager:
                        StrategyManagerView()
                    case .aiAnalysis:
                        AIAnalysisView()
                    case .orderLog:
                        OrderLogView()
                    case .market:
                        MarketView()
                    case .watchlist:
                        WatchlistView()
                    case .account:
                        AccountView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .environmentObject(session)
            .task {
                let section = session.selectedSection
                try? await Task.sleep(nanoseconds: 350_000_000)
                if !Task.isCancelled {
                    await session.refreshSectionIfNeeded(section)
                }
            }
            .onChange(of: session.selectedSection) { _, _ in
                let section = session.selectedSection
                Task {
                    try? await Task.sleep(nanoseconds: 350_000_000)
                    if !Task.isCancelled {
                        await session.refreshSectionIfNeeded(section)
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    showsCommandPalette = true
                } label: {
                    EmptyView()
                }
                .keyboardShortcut("k", modifiers: [.command])
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .accessibilityHidden(true)
            }
            .sheet(isPresented: $showsCommandPalette) {
                CommandPaletteView(isPresented: $showsCommandPalette)
                    .environmentObject(session)
                    .frame(width: 660, height: 560)
            }
        }
    }
}

struct GlobalAutomationStatusBar: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            HStack(spacing: 12) {
                Image(systemName: session.automationEnabled ? "dot.radiowaves.left.and.right" : "clock.badge.exclamationmark")
                    .foregroundStyle(session.automationEnabled ? .green : .orange)
                    .font(.headline)

                VStack(alignment: .leading, spacing: 2) {
                    Text(primaryText)
                        .font(.callout.weight(.semibold))
                    Text(detailText(now: timeline.date))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 12)

                if session.pendingOrderCount > 0 {
                    Button {
                        session.selectedSection = .orderLog
                    } label: {
                        Label("승인 \(session.pendingOrderCount)건", systemImage: "checklist")
                    }
                    .buttonStyle(.borderedProminent)
                }

                if session.automationEnabled {
                    Button {
                        session.setAutomationEnabled(false)
                    } label: {
                        Label("감시 중지", systemImage: "pause.circle")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
            .background(Color.green.opacity(0.10))
        }
    }

    private var primaryText: String {
        if session.isAutoRebalancing {
            return "자동 리밸런싱 진행 중"
        }
        if session.automationEnabled {
            return session.autoRebalanceSettings.isEnabled ? "자동 감시 + 자동 리밸런싱 켜짐" : "자동 감시 켜짐"
        }
        return "승인 대기 주문이 있습니다"
    }

    private func detailText(now: Date) -> String {
        var parts: [String] = []
        if session.automationEnabled {
            if let next = session.nextAutomationScanAt {
                let seconds = max(0, Int(next.timeIntervalSince(now)))
                parts.append("다음 감시 약 \(seconds)초 후")
            } else {
                parts.append("다음 감시 준비 중")
            }
            parts.append("활성 매크로 \(session.activeStrategyCount)개")
            if session.activePriceAlertCount > 0 {
                parts.append("가격 알림 \(session.activePriceAlertCount)개")
            }
            parts.append(session.lastAutomationDecision)
        }
        if session.autoRebalanceSettings.isEnabled {
            parts.append(session.lastAutoRebalanceMessage)
        }
        parts.append(session.safetySettings.allowLiveOrders ? "라이브 주문 허용" : "라이브 주문 잠김")
        return parts.joined(separator: " · ")
    }
}

struct GlobalAIActivityBar: View {
    let jobs: [ActiveAIJob]

    private var primaryJob: ActiveAIJob? {
        jobs.first
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            HStack(spacing: 10) {
                ProgressView()
                    .controlSize(.small)

                Label("AI 실행 중", systemImage: "brain.head.profile")
                    .font(.callout.weight(.semibold))

                if let primaryJob {
                    Text("\(primaryJob.engine.displayName) · \(primaryJob.symbol) · \(primaryJob.purpose)")
                        .font(.callout)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(elapsedText(from: primaryJob.startedAt, to: timeline.date))
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                if jobs.count > 1 {
                    Text("외 \(jobs.count - 1)개")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Text("완료되면 자동으로 사라집니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
            .background(Color.accentColor.opacity(0.10))
        }
    }

    private func elapsedText(from startDate: Date, to currentDate: Date) -> String {
        let seconds = max(0, Int(currentDate.timeIntervalSince(startDate)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

struct CommandPaletteView: View {
    @EnvironmentObject private var session: AppSession
    @Binding var isPresented: Bool
    @State private var query = ""
    @FocusState private var isFocused: Bool

    private var sectionMatches: [SidebarSection] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return SidebarSection.allCases
        }
        return SidebarSection.allCases.filter {
            $0.title.localizedStandardContains(trimmed)
        }
    }

    private var stockMatches: [StockSearchItem] {
        session.stockSuggestions(for: query, limit: 8)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "command")
                    .foregroundStyle(.secondary)
                TextField("화면, 종목, 작업 검색", text: $query)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .focused($isFocused)
                    .onSubmit {
                        if let first = stockMatches.first {
                            chooseStock(first.symbol)
                        } else if let first = sectionMatches.first {
                            chooseSection(first)
                        }
                    }
                Spacer()
                Text("ESC")
                    .font(.caption.monospaced().weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    commandSection("빠른 화면") {
                        ForEach(sectionMatches) { section in
                            CommandRow(
                                icon: section.systemImage,
                                title: section.title,
                                subtitle: commandSubtitle(for: section)
                            ) {
                                chooseSection(section)
                            }
                        }
                    }

                    commandSection("종목") {
                        if stockMatches.isEmpty {
                            Text(query.isEmpty ? "검색어를 입력하면 종목이 나옵니다." : "검색 결과가 없습니다.")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(12)
                        } else {
                            ForEach(stockMatches) { item in
                                CommandRow(
                                    icon: "magnifyingglass",
                                    title: item.displayText,
                                    subtitle: "\(item.englishName) · \(item.market)"
                                ) {
                                    chooseStock(item.symbol)
                                }
                            }
                        }
                    }

                    commandSection("작업") {
                        CommandRow(icon: "star", title: "현재 종목 관심등록/해제", subtitle: session.selectedSymbol) {
                            session.toggleWatchedSymbol(session.selectedSymbol)
                            isPresented = false
                        }
                        CommandRow(icon: "newspaper", title: "관심종목 AI 브리프 생성", subtitle: "OpenStock식 개인화 요약") {
                            isPresented = false
                            Task { await session.runWatchlistBrief() }
                        }
                        CommandRow(icon: "arrow.clockwise", title: "현재 화면 새로고침", subtitle: session.selectedSection.title) {
                            isPresented = false
                            Task { await session.refreshSelectedSectionIfNeeded(force: true) }
                        }
                    }
                }
            }
        }
        .padding(18)
        .onAppear {
            isFocused = true
        }
    }

    private func commandSection<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            VStack(spacing: 0) {
                content()
            }
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func commandSubtitle(for section: SidebarSection) -> String {
        switch section {
        case .dashboard: "차트와 종목 인사이트"
        case .strategyManager: "자동선택, 기계적 매매, AI 모드"
        case .aiAnalysis: "종목 리포트와 AI 기록"
        case .orderLog: "승인 대기 주문과 실행 로그"
        case .market: "거래대금·거래량 랭킹"
        case .watchlist: "관심종목과 가격 알림"
        case .account: "보유종목과 단일 주문 테스트"
        case .settings: "API, 안전 한도, 투자 성향"
        }
    }

    private func chooseSection(_ section: SidebarSection) {
        session.selectedSection = section
        isPresented = false
    }

    private func chooseStock(_ symbol: String) {
        session.selectedSymbol = symbol
        session.selectedSection = .dashboard
        isPresented = false
        Task { await session.refreshMarketData() }
    }
}

struct CommandRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.callout.weight(.medium))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "return")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct DashboardView: View {
    @EnvironmentObject private var session: AppSession
    @State private var symbolDraft = "005930"

    private var selectedPrice: PriceResponse? {
        session.prices.first {
            $0.symbol.caseInsensitiveCompare(session.selectedSymbol) == .orderedSame
        }
    }

    private var selectedName: String {
        session.stockName(for: session.selectedSymbol) ?? session.selectedSymbol
    }

    private var isRefreshing: Bool {
        if case .loading = session.connectionState {
            return true
        }
        return session.isAPICoolingDown
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DashboardHero(
                        symbol: session.selectedSymbol,
                        name: selectedName,
                        price: selectedPrice,
                        connectionState: session.connectionState
                    )

                    VStack(alignment: .leading, spacing: 16) {
                        StockInsightPanel(
                            symbol: session.selectedSymbol,
                            name: selectedName,
                            price: selectedPrice,
                            candles: session.candles
                        )
                        .frame(maxWidth: .infinity)

                        WatchlistBriefPanel()
                            .frame(maxWidth: .infinity)
                    }

                    RuntimeStatusPanel()

                    HStack(alignment: .top, spacing: 18) {
                        ChartPanel(
                            candles: session.candles,
                            timeframe: $session.chartTimeframe
                        ) {
                            Task { await session.refreshMarketData() }
                        }
                        .frame(minWidth: 620, minHeight: 500)

                        VStack(spacing: 16) {
                            OrderbookPanel(orderbook: session.orderbook)
                            DashboardFocusPanel(
                                symbol: session.selectedSymbol,
                                latestAIStatus: session.latestAIStatus,
                                pendingOrderCount: session.pendingOrderCount,
                                riskWarnings: session.riskWarnings,
                                liveReadinessWarnings: session.liveOrderReadinessWarnings
                            )
                        }
                        .frame(width: 330)
                    }

                    StrategySnapshotPanel()

                }
                .padding(20)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            symbolDraft = session.stockDisplayText(for: session.selectedSymbol)
        }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
            StockSearchField(text: $symbolDraft, placeholder: "종목명 또는 회사명", width: 280, showsSelectedName: true) { symbol in
                session.selectedSymbol = symbol
                symbolDraft = session.stockDisplayText(for: symbol)
                Task { await session.refreshMarketData() }
            }

            Button {
                session.selectSymbol(from: symbolDraft)
                symbolDraft = session.stockDisplayText(for: session.selectedSymbol)
                Task { await session.refreshMarketData() }
            } label: {
                if session.isAPICoolingDown {
                    Label("잠시 대기 \(session.apiCooldownRemainingSeconds)초", systemImage: "timer")
                } else if isRefreshing {
                    Label("불러오는 중", systemImage: "hourglass")
                } else {
                    Label("새로고침", systemImage: "arrow.clockwise")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRefreshing)

            Spacer()

            Label(session.connectionState.label, systemImage: statusIcon)
                .foregroundStyle(statusColor)

            Toggle("자동매매", isOn: Binding(
                get: { session.automationEnabled },
                set: { value in
                    session.setAutomationEnabled(value)
                }
            ))
            .toggleStyle(.switch)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    private var statusIcon: String {
        switch session.connectionState {
        case .demo: "sparkles"
        case .loading: "hourglass"
        case .live: "checkmark.circle"
        case .failed: "exclamationmark.triangle"
        }
    }

    private var statusColor: Color {
        switch session.connectionState {
        case .demo: .secondary
        case .loading: .orange
        case .live: .green
        case .failed: .red
        }
    }
}

struct DashboardHero: View {
    let symbol: String
    let name: String
    let price: PriceResponse?
    let connectionState: ConnectionState

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(name)
                        .font(.title.weight(.semibold))
                    Text(symbol)
                        .font(.title3.monospaced().weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Text(priceText)
                        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    Text(price?.currency ?? "")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Label(connectionState.label, systemImage: connectionIcon)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(connectionColor)
                Text(price?.timestamp ?? "데모 시세")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var priceText: String {
        guard let price else {
            return "-"
        }
        return formattedDecimal(price.lastPriceValue, fractionDigits: price.currency == "KRW" ? 0 : 2)
    }

    private var connectionIcon: String {
        switch connectionState {
        case .demo: "sparkles"
        case .loading: "hourglass"
        case .live: "checkmark.circle"
        case .failed: "exclamationmark.triangle"
        }
    }

    private var connectionColor: Color {
        switch connectionState {
        case .demo: .secondary
        case .loading: .orange
        case .live: .green
        case .failed: .red
        }
    }
}

struct StockInsightPanel: View {
    @EnvironmentObject private var session: AppSession
    let symbol: String
    let name: String
    let price: PriceResponse?
    let candles: [Candle]

    private var holding: Holding? {
        session.holdings.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
    }

    private var latestAI: AIAnalysisResult? {
        session.latestAIResult(for: symbol)
    }

    private var closes: [Double] {
        candles
            .sorted { $0.date < $1.date }
            .map { NSDecimalNumber(decimal: $0.closeValue).doubleValue }
            .filter { $0 > 0 }
    }

    private var volumes: [Double] {
        candles
            .sorted { $0.date < $1.date }
            .map { NSDecimalNumber(decimal: $0.volumeValue).doubleValue }
            .filter { $0 >= 0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("종목 인사이트", systemImage: "sparkline")
                    .font(.headline)
                Spacer()
                Button {
                    session.toggleWatchedSymbol(symbol)
                } label: {
                    Label(session.isWatchedSymbol(symbol) ? "관심 해제" : "관심 등록", systemImage: session.isWatchedSymbol(symbol) ? "star.fill" : "star")
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 10) {
                insightMetric("시장", marketText, "building.2")
                insightMetric("보유", holdingText, "briefcase")
                insightMetric("추세", trendText, trendIcon)
                insightMetric("거래량", volumeText, "chart.bar")
            }

            Divider()

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("프로필")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(name)은 \(marketText) 종목입니다. 현재 앱은 토스 시세, 계좌 보유정보, 공개 거래랭킹, AI CLI 리포트를 합쳐 보여줍니다.")
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 6) {
                    Text("AI 코멘트")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(aiComment)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var marketText: String {
        if let item = session.stockDirectory.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
            return "\(item.market) · \(item.currency)"
        }
        return price.map { $0.currency } ?? "-"
    }

    private var holdingText: String {
        guard let holding else {
            return "없음"
        }
        return "\(holding.quantity)주"
    }

    private var trendText: String {
        guard let first = closes.first, let last = closes.last, first > 0 else {
            return "대기"
        }
        let rate = ((last - first) / first) * 100
        return "\(rate >= 0 ? "+" : "")\(formattedDouble(rate, fractionDigits: 2))%"
    }

    private var trendIcon: String {
        guard let first = closes.first, let last = closes.last else {
            return "chart.xyaxis.line"
        }
        return last >= first ? "arrow.up.right" : "arrow.down.right"
    }

    private var volumeText: String {
        guard let latest = volumes.last, volumes.count > 5 else {
            return "대기"
        }
        let recent = Array(volumes.suffix(min(20, volumes.count)))
        let average = recent.reduce(0, +) / Double(recent.count)
        guard average > 0 else {
            return "-"
        }
        return "\(formattedDouble(latest / average, fractionDigits: 1))배"
    }

    private var aiComment: String {
        guard let latestAI else {
            return "아직 이 종목의 AI 리포트가 없습니다. AI 분석 탭에서 종목별 리포트를 만들 수 있어요."
        }
        return latestAI.output
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "AI 리포트가 저장되어 있습니다."
    }

    private func insightMetric(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct WatchlistBriefPanel: View {
    @EnvironmentObject private var session: AppSession
    @State private var isRunning = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("관심종목 브리프", systemImage: "newspaper")
                    .font(.headline)
                Spacer()
                if isRunning {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            Text("OpenStock처럼 관심종목, 보유종목, 거래대금 상위를 묶어 오늘 먼저 볼 종목을 AI가 짧게 정리합니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if !session.investorProfile.dailyBriefEnabled {
                Label("설정에서 관심종목 데일리 브리프가 꺼져 있습니다.", systemImage: "pause.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(session.watchedSymbols, id: \.self) { symbol in
                        Button {
                            session.selectedSymbol = symbol
                            session.selectedSection = .dashboard
                            Task { await session.refreshMarketData() }
                        } label: {
                            Text(session.stockName(for: symbol) ?? symbol)
                                .font(.caption.weight(.medium))
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }

            if let brief = session.latestWatchlistBrief {
                ScrollView {
                    Text(brief.output)
                        .font(.callout)
                        .textSelection(.enabled)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                }
                .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 420, alignment: .topLeading)
                .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
            } else {
                Text("아직 생성된 브리프가 없습니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
                    .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
            }

            Button {
                guard !isRunning else {
                    return
                }
                isRunning = true
                Task {
                    _ = await session.runWatchlistBrief()
                    isRunning = false
                }
            } label: {
                Label(isRunning ? "생성 중" : "브리프 생성", systemImage: "wand.and.stars")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning || session.watchedSymbols.isEmpty || !session.investorProfile.dailyBriefEnabled)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct ChartPanel: View {
    let candles: [Candle]
    @Binding var timeframe: ChartTimeframe
    let onTimeframeChange: () -> Void
    @State private var zoomLevel = 0

    private var baseCandles: [Candle] {
        switch timeframe {
        case .oneMinuteRegular, .oneMinuteExtended, .daily:
            candles
        case .weekly:
            aggregateCandles(by: .weekOfYear)
        case .monthly:
            aggregateCandles(by: .month)
        }
    }

    private var displayCandles: [Candle] {
        let source = baseCandles
        guard zoomLevel > 0 else {
            return source
        }

        let divisor = pow(2.0, Double(zoomLevel))
        let count = max(20, Int(Double(source.count) / divisor))
        return Array(source.suffix(count))
    }

    private var chartCandles: [Candle] {
        CandleSeriesReducer.bucketedOHLC(displayCandles, maxCount: maxRenderedCandles)
    }

    private var maxRenderedCandles: Int {
        switch timeframe {
        case .oneMinuteExtended:
            300
        case .oneMinuteRegular:
            260
        case .daily, .weekly, .monthly:
            180
        }
    }

    private var latestCandle: Candle? {
        displayCandles.last
    }

    private var previousCandle: Candle? {
        guard displayCandles.count >= 2 else {
            return nil
        }
        return displayCandles[displayCandles.count - 2]
    }

    var body: some View {
        let renderedCandles = chartCandles
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("차트", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                Spacer()
                Picker("기간", selection: $timeframe) {
                    ForEach(ChartTimeframe.allCases) { timeframe in
                        Text(timeframe.title).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 390)
                .help("정규분봉은 정규장 중심, 전체분봉은 데이마켓/프리/정규/애프터와 국내 NXT 구간까지 보기 위한 최근 1440개 1분봉입니다.")
                .onChange(of: timeframe) { oldValue, newValue in
                    zoomLevel = 0
                    if oldValue.apiInterval != newValue.apiInterval || oldValue.candleCount != newValue.candleCount {
                        onTimeframeChange()
                    }
                }

                HStack(spacing: 4) {
                    Button {
                        zoomLevel = max(0, zoomLevel - 1)
                    } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .disabled(zoomLevel == 0)
                    .help("축소")

                    Button {
                        zoomLevel = min(4, zoomLevel + 1)
                    } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .disabled(displayCandles.count <= 24)
                    .help("확대")

                    Button {
                        zoomLevel = 0
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .disabled(zoomLevel == 0)
                    .help("전체 보기")
                }
                .buttonStyle(.bordered)
            }

            Chart(renderedCandles) { candle in
                RuleMark(
                    x: .value("시간", candle.date),
                    yStart: .value("저가", decimalDouble(candle.lowValue)),
                    yEnd: .value("고가", decimalDouble(candle.highValue))
                )
                .foregroundStyle(candle.isRising ? Color.red.opacity(0.85) : Color.blue.opacity(0.85))

                RectangleMark(
                    x: .value("시간", candle.date),
                    yStart: .value("시가", decimalDouble(candle.openValue)),
                    yEnd: .value("종가", decimalDouble(candle.closeValue)),
                    width: .fixed(candleWidth)
                )
                .foregroundStyle(candle.isRising ? Color.red.opacity(0.72) : Color.blue.opacity(0.72))
            }
            .chartYScale(domain: .automatic(includesZero: false))
            .frame(minHeight: 320)

            Chart(renderedCandles) { candle in
                BarMark(
                    x: .value("시간", candle.date),
                    y: .value("거래량", decimalDouble(candle.volumeValue))
                )
                .foregroundStyle(candle.isRising ? Color.red.opacity(0.35) : Color.blue.opacity(0.35))
            }
            .frame(height: 86)

            HStack(spacing: 18) {
                metric("종가", latestCandle?.closePrice)
                metric("변동", changeText)
                metric("고가", displayHighText)
                metric("저가", displayLowText)
                metric("거래량", latestCandle?.volume)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var candleWidth: CGFloat {
        switch timeframe {
        case .oneMinuteRegular: 3
        case .oneMinuteExtended: 2
        case .daily: 5
        case .weekly: 8
        case .monthly: 12
        }
    }

    private var displayHighText: String? {
        guard let high = displayCandles.map(\.highValue).max() else {
            return nil
        }
        return formattedDecimal(high, fractionDigits: 2)
    }

    private var displayLowText: String? {
        guard let low = displayCandles.map(\.lowValue).min() else {
            return nil
        }
        return formattedDecimal(low, fractionDigits: 2)
    }

    private var changeText: String? {
        guard let latestCandle, let previousCandle else {
            return nil
        }
        let change = latestCandle.closeValue - previousCandle.closeValue
        guard previousCandle.closeValue != 0 else {
            return formattedDecimal(change, fractionDigits: 2)
        }
        let rate = (change / previousCandle.closeValue) * 100
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(formattedDecimal(change, fractionDigits: 2)) (\(sign)\(formattedDecimal(rate, fractionDigits: 2))%)"
    }

    private func metric(_ title: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value ?? "-")
                .font(.callout.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func aggregateCandles(by component: Calendar.Component) -> [Candle] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: candles) { candle in
            calendar.dateInterval(of: component, for: candle.date)?.start ?? candle.date
        }

        return grouped.keys.sorted().compactMap { key in
            guard let group = grouped[key]?.sorted(by: { $0.date < $1.date }),
                  let first = group.first,
                  let last = group.last else {
                return nil
            }

            let high = group.map(\.highValue).max() ?? first.highValue
            let low = group.map(\.lowValue).min() ?? first.lowValue
            let volume = group.reduce(Decimal(0)) { partialResult, candle in
                partialResult + candle.volumeValue
            }

            return Candle(
                timestamp: ISO8601DateFormatter().string(from: key),
                openPrice: first.openPrice,
                highPrice: formattedDecimal(high, fractionDigits: 4),
                lowPrice: formattedDecimal(low, fractionDigits: 4),
                closePrice: last.closePrice,
                volume: formattedDecimal(volume, fractionDigits: 0),
                currency: last.currency
            )
        }
    }

    private func decimalDouble(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}

struct DashboardFocusPanel: View {
    let symbol: String
    let latestAIStatus: String
    let pendingOrderCount: Int
    let riskWarnings: [String]
    let liveReadinessWarnings: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("오늘 체크", systemImage: "checklist.checked")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                focusRow("종목", symbol, "scope")
                focusRow("AI", latestAIStatus, "brain.head.profile")
                focusRow("승인 대기", "\(pendingOrderCount)건", "clock.badge.exclamationmark")
            }

            Divider()

            if liveReadinessWarnings.isEmpty {
                Label("실주문 조건이 준비되어 있습니다. 조건 충족 시 자동 제출을 시도합니다.", systemImage: "bolt.circle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                ForEach(liveReadinessWarnings.prefix(3), id: \.self) { warning in
                    Label(warning, systemImage: "lock.trianglebadge.exclamationmark")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            ForEach(riskWarnings.prefix(3), id: \.self) { warning in
                Label(warning, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func focusRow(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout.weight(.medium))
                    .lineLimit(2)
            }
        }
    }
}

struct PricesPanel: View {
    @EnvironmentObject private var session: AppSession
    let prices: [PriceResponse]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("관심 종목", systemImage: "star")
                .font(.headline)

            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 8) {
                GridRow {
                    Text("종목").foregroundStyle(.secondary)
                    Text("현재가").foregroundStyle(.secondary)
                    Text("통화").foregroundStyle(.secondary)
                    Text("시각").foregroundStyle(.secondary)
                }
                ForEach(prices) { price in
                    GridRow {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.stockName(for: price.symbol) ?? price.symbol)
                                .font(.body)
                            Text(price.symbol)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                        }
                        Text(formattedDecimal(price.lastPriceValue, fractionDigits: 2))
                            .font(.body.monospacedDigit())
                        Text(price.currency)
                        Text(price.timestamp ?? "-")
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct OrderbookPanel: View {
    let orderbook: OrderbookResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("호가", systemImage: "rectangle.split.3x3")
                    .font(.headline)
                Spacer()
                Text(orderbook.currency)
                    .foregroundStyle(.secondary)
            }

            orderbookRows(orderbook.asks.reversed(), color: .red)
            Divider()
            orderbookRows(orderbook.bids, color: .blue)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func orderbookRows(_ rows: [OrderbookEntry], color: Color) -> some View {
        VStack(spacing: 5) {
            ForEach(rows) { row in
                HStack {
                    Text(row.price)
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(color)
                    Spacer()
                    Text(row.volume)
                        .font(.callout.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct HoldingsPanel: View {
    let holdings: [Holding]
    var onTrade: ((Holding, StrategyAction) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("보유 종목", systemImage: "briefcase")
                .font(.headline)

            ForEach(holdings) { holding in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(holding.symbol)
                            .font(.body.monospaced())
                        Text(holding.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(holding.quantity)
                        .font(.body.monospacedDigit())
                    Text("\(holding.value) \(holding.currency)")
                        .font(.body.monospacedDigit())
                        .frame(width: 160, alignment: .trailing)
                    Text(holding.profitLoss)
                        .font(.body.monospacedDigit())
                        .frame(width: 72, alignment: .trailing)

                    if let onTrade {
                        HStack(spacing: 6) {
                            Button {
                                onTrade(holding, .buy)
                            } label: {
                                Label("매수", systemImage: "plus.circle")
                            }

                            Button {
                                onTrade(holding, .sell)
                            } label: {
                                Label("매도", systemImage: "minus.circle")
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private enum MarketScreenMode: String, CaseIterable, Identifiable {
    case overview
    case ranking

    var id: String { rawValue }

    var title: String {
        switch self {
        case .overview: "시장 개요"
        case .ranking: "랭킹"
        }
    }

    var systemImage: String {
        switch self {
        case .overview: "square.grid.3x3.fill"
        case .ranking: "list.number"
        }
    }
}

struct MarketView: View {
    @EnvironmentObject private var session: AppSession
    @State private var selectedMode: MarketScreenMode = .overview
    @State private var selectedScope: MarketScope = .all
    @State private var selectedMetric: MarketRankingMetric = .tradingValue
    @State private var selectedSector: MarketSector = .all

    private var rankedActivities: [MarketActivitySnapshot] {
        let sorted = session.marketActivities
            .filter { $0.matches(scope: selectedScope) }
            .sorted { left, right in
                switch selectedMetric {
                case .tradingValue:
                    return (left.tradeValue ?? -1) > (right.tradeValue ?? -1)
                case .tradingVolume:
                    return (left.tradeVolume ?? -1) > (right.tradeVolume ?? -1)
                }
            }
        let visibleLimit = selectedMode == .overview ? 650 : 350
        var visible = Array(sorted.prefix(visibleLimit))
        let anchorSymbols: Set<String> = [
            "005930", "000660", "009150", "042700",
            "373220", "051910", "006400", "086520", "247540", "450080", "003670", "066970", "361610"
        ]
        let visibleKeys = Set(visible.map { $0.symbol.uppercased() })
        let anchors = sorted.filter { anchorSymbols.contains($0.symbol.uppercased()) && !visibleKeys.contains($0.symbol.uppercased()) }
        visible.append(contentsOf: anchors)
        return visible
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Label("시장", systemImage: selectedMode.systemImage)
                    .font(.title3.weight(.semibold))
                Spacer()
                Picker("보기", selection: $selectedMode) {
                    ForEach(MarketScreenMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)

                Picker("시장", selection: $selectedScope) {
                    ForEach(MarketScope.allCases) { scope in
                        Text(scope.title).tag(scope)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 220)

                Picker("기준", selection: $selectedMetric) {
                    ForEach(MarketRankingMetric.allCases) { metric in
                        Label(metric.title, systemImage: metric.systemImage).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 240)

                Button {
                    Task { await session.refreshMarketActivity() }
                } label: {
                    Label("새로고침", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    MarketDataSourceNotice(text: session.marketActivitySourceText)

                    if selectedMode == .overview {
                        SectorMarketOverview(
                            rows: rankedActivities,
                            selectedSector: $selectedSector
                        ) { symbol in
                            session.selectedSymbol = symbol
                        }
                    } else {
                        MarketRankingSummary(
                            rows: rankedActivities,
                            scope: selectedScope,
                            metric: selectedMetric
                        )

                        MarketRankingPanel(
                            rows: rankedActivities,
                            metric: selectedMetric,
                            sourceText: session.marketActivitySourceText
                        ) { symbol in
                            session.selectedSymbol = symbol
                        }
                    }
                }
                .padding(20)
            }
        }
    }
}

private struct SectorSummary: Identifiable {
    var id: String { sector.id }
    let sector: MarketSector
    let rows: [MarketActivitySnapshot]
    let averageChange: Double?
    let totalTradeValue: Decimal

    var risingCount: Int {
        rows.filter { ($0.changePercent ?? 0) > 0 }.count
    }

    var fallingCount: Int {
        rows.filter { ($0.changePercent ?? 0) < 0 }.count
    }
}

private struct SectorMarketOverview: View {
    let rows: [MarketActivitySnapshot]
    @Binding var selectedSector: MarketSector
    let onSelect: (String) -> Void

    private var summaries: [SectorSummary] {
        sectorSummaries(from: rows)
    }

    private var leadingSector: SectorSummary? {
        summaries
            .filter { $0.averageChange != nil }
            .max { ($0.averageChange ?? -999) < ($1.averageChange ?? -999) }
    }

    private var weakestSector: SectorSummary? {
        summaries
            .filter { $0.averageChange != nil }
            .min { ($0.averageChange ?? 999) < ($1.averageChange ?? 999) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                overviewMetric(
                    "강한 섹터",
                    leadingSector?.sector.title ?? "-",
                    leadingSector.flatMap { changeText($0.averageChange) } ?? "등락률 없음",
                    "arrow.up.right"
                )
                overviewMetric(
                    "약한 섹터",
                    weakestSector?.sector.title ?? "-",
                    weakestSector.flatMap { changeText($0.averageChange) } ?? "등락률 없음",
                    "arrow.down.right"
                )
                overviewMetric(
                    "상승 종목",
                    "\(rows.filter { ($0.changePercent ?? 0) > 0 }.count)개",
                    "하락 \(rows.filter { ($0.changePercent ?? 0) < 0 }.count)개",
                    "chart.bar.xaxis"
                )
                overviewMetric(
                    "데이터",
                    "\(rows.filter { $0.changePercent != nil }.count)개",
                    "등락률 포함",
                    "checkmark.seal"
                )
            }

            SectorStrip(summaries: summaries, selectedSector: $selectedSector)

            SectorHeatmapPanel(
                rows: rows,
                selectedSector: selectedSector,
                onSelect: onSelect
            )

            Text("빨강은 상승, 파랑은 하락입니다. 전체 보기에서는 섹터 박스 안에 종목 박스를 넣어 업종 흐름을 한눈에 봅니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func overviewMetric(_ title: String, _ value: String, _ caption: String, _ icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func changeText(_ value: Double?) -> String {
        guard let value else {
            return "등락률 없음"
        }
        return "\(value >= 0 ? "+" : "")\(formattedDouble(value, fractionDigits: 2))%"
    }
}

private struct SectorStrip: View {
    let summaries: [SectorSummary]
    @Binding var selectedSector: MarketSector

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                sectorButton(
                    sector: .all,
                    change: allAverageChange,
                    count: summaries.reduce(0) { $0 + $1.rows.count }
                )
                ForEach(summaries) { summary in
                    sectorButton(
                        sector: summary.sector,
                        change: summary.averageChange,
                        count: summary.rows.count
                    )
                }
            }
        }
    }

    private var allAverageChange: Double? {
        let values = summaries.compactMap(\.averageChange)
        guard !values.isEmpty else {
            return nil
        }
        return values.reduce(0, +) / Double(values.count)
    }

    private func sectorButton(sector: MarketSector, change: Double?, count: Int) -> some View {
        Button {
            selectedSector = sector
        } label: {
            HStack(spacing: 8) {
                Image(systemName: sector.systemImage)
                VStack(alignment: .leading, spacing: 2) {
                    Text(sector.title)
                        .font(.caption.weight(.semibold))
                    Text("\(count)개 · \(changeLabel(change))")
                        .font(.caption2.monospacedDigit())
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .foregroundStyle(selectedSector == sector ? .white : .primary)
            .background(selectedSector == sector ? sectorColor(change).opacity(0.82) : Color.secondary.opacity(0.10), in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private func changeLabel(_ change: Double?) -> String {
        guard let change else {
            return "-"
        }
        return "\(change >= 0 ? "+" : "")\(formattedDouble(change, fractionDigits: 1))%"
    }
}

private struct SectorHeatmapPanel: View {
    let rows: [MarketActivitySnapshot]
    let selectedSector: MarketSector
    let onSelect: (String) -> Void

    private var summaries: [SectorSummary] {
        sectorSummaries(from: rows)
    }

    private var displayedSummaries: [SectorSummary] {
        if selectedSector == .all {
            return summaries
        }
        return summaries.filter { $0.sector == selectedSector }
    }

    private var columns: [GridItem] {
        [
            GridItem(.adaptive(minimum: selectedSector == .all ? 330 : 520), spacing: 12)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(selectedSector == .all ? "섹터별 주식 히트맵" : "\(selectedSector.title) 히트맵", systemImage: "square.grid.3x3.fill")
                    .font(.headline)
                Spacer()
                Text("\(displayedSummaries.reduce(0) { $0 + $1.rows.count })개")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if displayedSummaries.isEmpty {
                ContentUnavailableView("표시할 섹터 데이터가 없습니다", systemImage: "square.grid.3x3")
                    .frame(maxWidth: .infinity, minHeight: 260)
            } else {
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(displayedSummaries) { summary in
                        SectorHeatmapGroup(
                            summary: summary,
                            isExpanded: selectedSector != .all,
                            onSelect: onSelect
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct SectorHeatmapGroup: View {
    let summary: SectorSummary
    let isExpanded: Bool
    let onSelect: (String) -> Void

    private var stockRows: [MarketActivitySnapshot] {
        Array(summary.rows.prefix(isExpanded ? 36 : 12))
    }

    private var featuredRows: [MarketActivitySnapshot] {
        Array(stockRows.prefix(isExpanded ? 3 : 2))
    }

    private var compactRows: [MarketActivitySnapshot] {
        Array(stockRows.dropFirst(featuredRows.count))
    }

    private var miniColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: isExpanded ? 104 : 82), spacing: 5)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Label(summary.sector.title, systemImage: summary.sector.systemImage)
                    .font(.headline)
                Spacer()
                Text(changeLabel)
                    .font(.callout.monospacedDigit().weight(.bold))
                    .foregroundStyle(sectorColor(summary.averageChange))
                Text("\(summary.rows.count)개")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !featuredRows.isEmpty {
                HStack(spacing: 5) {
                    ForEach(featuredRows, id: \.id) { row in
                        Button {
                            onSelect(row.symbol)
                        } label: {
                            SectorStockHeatTile(row: row, isFeatured: true)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if !compactRows.isEmpty {
                LazyVGrid(columns: miniColumns, spacing: 5) {
                    ForEach(compactRows, id: \.id) { row in
                        Button {
                            onSelect(row.symbol)
                        } label: {
                            SectorStockHeatTile(row: row, isFeatured: false)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(sectorColor(summary.averageChange).opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(sectorColor(summary.averageChange).opacity(0.30), lineWidth: 1)
        )
    }

    private var changeLabel: String {
        guard let change = summary.averageChange else {
            return "-"
        }
        return "\(change >= 0 ? "+" : "")\(formattedDouble(change, fractionDigits: 2))%"
    }
}

private struct SectorStockHeatTile: View {
    let row: MarketActivitySnapshot
    let isFeatured: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: isFeatured ? 8 : 4) {
            Text(row.name)
                .font(isFeatured ? .title3.weight(.bold) : .caption.weight(.semibold))
                .lineLimit(isFeatured ? 2 : 1)
                .minimumScaleFactor(0.72)
            Text(row.symbol)
                .font(.caption2.monospaced())
                .foregroundStyle(.white.opacity(0.78))
            Spacer(minLength: 4)
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(changeLabel)
                    .font(isFeatured ? .title3.monospacedDigit().weight(.bold) : .caption.monospacedDigit().weight(.bold))
                Spacer()
                if isFeatured {
                    Text(priceText)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.78))
                }
            }
        }
        .foregroundStyle(.white)
        .padding(isFeatured ? 12 : 8)
        .frame(maxWidth: .infinity, minHeight: isFeatured ? 118 : 72, alignment: .topLeading)
        .background(tileColor, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.14), lineWidth: 1)
        )
    }

    private var tileColor: Color {
        let base = sectorColor(row.changePercent)
        let intensity = min(0.95, max(0.34, abs(row.changePercent ?? 0) / 7 + 0.34))
        return base.opacity(intensity)
    }

    private var changeLabel: String {
        guard let change = row.changePercent else {
            return "-"
        }
        return "\(change >= 0 ? "+" : "")\(formattedDouble(change, fractionDigits: 2))%"
    }

    private var priceText: String {
        "\(row.currency) \(row.lastPrice)"
    }
}

private func sectorSummaries(from rows: [MarketActivitySnapshot]) -> [SectorSummary] {
    let grouped = Dictionary(grouping: rows) { row in
        marketSector(for: row)
    }
    return MarketSector.allCases
        .filter { $0 != .all }
        .compactMap { sector in
            guard let sectorRows = grouped[sector], !sectorRows.isEmpty else {
                return nil
            }
            let weightedRows = sectorRows.compactMap { row -> (change: Double, weight: Double)? in
                guard let change = row.changePercent else {
                    return nil
                }
                let weight = max(1, NSDecimalNumber(decimal: row.tradeValue ?? 1).doubleValue)
                return (change, weight)
            }
            let average: Double?
            if weightedRows.isEmpty {
                average = nil
            } else {
                let totalWeight = weightedRows.reduce(0) { $0 + $1.weight }
                average = weightedRows.reduce(0) { $0 + $1.change * $1.weight } / totalWeight
            }
            let totalTradeValue = sectorRows.reduce(Decimal(0)) { $0 + ($1.tradeValue ?? 0) }
            return SectorSummary(
                sector: sector,
                rows: sectorRows.sorted { ($0.tradeValue ?? 0) > ($1.tradeValue ?? 0) },
                averageChange: average,
                totalTradeValue: totalTradeValue
            )
        }
        .sorted { left, right in
            if left.averageChange == nil, right.averageChange != nil {
                return false
            }
            if left.averageChange != nil, right.averageChange == nil {
                return true
            }
            return (left.averageChange ?? -999) > (right.averageChange ?? -999)
        }
}

private func marketSector(for row: MarketActivitySnapshot) -> MarketSector {
    let symbol = row.symbol.uppercased()
    let text = "\(row.name) \(row.englishName) \(row.market) \(symbol)".lowercased()

    let semiconductorSymbols: Set<String> = [
        "005930", "000660", "009150", "042700", "011070",
        "NVDA", "AMD", "AVGO", "TSM", "ASML", "AMAT", "LRCX", "KLAC", "MU", "INTC", "QCOM", "ARM", "MRVL",
        "ON", "NXPI", "MCHP", "TXN", "ADI", "MPWR", "GFS", "UMC", "AMKR", "COHR", "ACMR"
    ]
    let batterySymbols: Set<String> = ["373220", "006400", "051910", "096770", "247540", "086520", "450080", "003670", "066970", "361610"]
    let healthcareSymbols: Set<String> = ["068270", "207940", "000100", "128940", "196170", "HLB"]
    let platformSymbols: Set<String> = ["035420", "035720", "AAPL", "MSFT", "GOOGL", "META", "AMZN", "NFLX", "PLTR"]
    let autoSymbols: Set<String> = ["005380", "000270", "TSLA", "GM", "F"]
    let financeSymbols: Set<String> = ["055550", "105560", "086790", "JPM", "BAC", "C", "WFC", "MA", "V"]
    let steelSymbols: Set<String> = ["005490", "010130", "004020", "POSCO"]
    let energySymbols: Set<String> = ["010120", "066570", "034020", "009540", "267250", "XOM", "CVX"]
    let aerospaceSymbols: Set<String> = ["RKLB", "LUNR", "LMT", "BA", "012450"]
    let etfSymbols: Set<String> = ["SPY", "QQQ", "DIA", "IWM", "VOO"]

    if semiconductorSymbols.contains(symbol) || text.contains("반도체") || text.contains("semiconductor") || text.contains("hynix") {
        return .semiconductor
    }
    if batterySymbols.contains(symbol) ||
        text.contains("battery") ||
        text.contains("sdi") ||
        text.contains("energy solution") ||
        text.contains("2차전지") ||
        text.contains("에너지솔루션") ||
        text.contains("에코프로") ||
        text.contains("ecopro") ||
        text.contains("엘앤에프") ||
        text.contains("l&f") ||
        text.contains("퓨처엠") ||
        text.contains("future m") ||
        text.contains("양극재") ||
        text.contains("분리막") {
        return .battery
    }
    if healthcareSymbols.contains(symbol) || text.contains("셀트리온") || text.contains("bio") || text.contains("pharma") || text.contains("health") || text.contains("medical") {
        return .healthcare
    }
    if platformSymbols.contains(symbol) || text.contains("naver") || text.contains("kakao") || text.contains("platform") || text.contains("software") {
        return .internetPlatform
    }
    if autoSymbols.contains(symbol) || text.contains("현대차") || text.contains("기아") || text.contains("motor") || text.contains("tesla") {
        return .auto
    }
    if financeSymbols.contains(symbol) || text.contains("bank") || text.contains("금융") || text.contains("증권") || text.contains("card") {
        return .finance
    }
    if steelSymbols.contains(symbol) || text.contains("posco") || text.contains("steel") || text.contains("철강") || text.contains("소재") {
        return .steelMaterials
    }
    if energySymbols.contains(symbol) || text.contains("electric") || text.contains("에너지") || text.contains("조선") || text.contains("industrial") {
        return .energyIndustrial
    }
    if aerospaceSymbols.contains(symbol) || text.contains("rocket") || text.contains("space") || text.contains("lockheed") || text.contains("방산") || text.contains("우주") {
        return .aerospaceDefense
    }
    if etfSymbols.contains(symbol) || text.contains("etf") || text.contains("index") {
        return .etfIndex
    }
    if text.contains("consumer") || text.contains("retail") || text.contains("walmart") {
        return .consumer
    }
    return .other
}

private func sectorColor(_ change: Double?) -> Color {
    guard let change else {
        return .secondary
    }
    if change > 0 {
        return .red
    }
    if change < 0 {
        return .blue
    }
    return .secondary
}

struct MarketDataSourceNotice: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle")
                .foregroundStyle(.blue)
                .font(.headline)
            VStack(alignment: .leading, spacing: 4) {
                Text("데이터 출처")
                    .font(.callout.weight(.semibold))
                Text(text)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MarketRankingSummary: View {
    let rows: [MarketActivitySnapshot]
    let scope: MarketScope
    let metric: MarketRankingMetric

    private var topRow: MarketActivitySnapshot? {
        rows.first
    }

    var body: some View {
        HStack(spacing: 14) {
            summaryMetric("분류", scope.title, "필터")
            summaryMetric("기준", metric.title, "정렬")
            summaryMetric("범위", "혼합", "출처 확인")
            summaryMetric("종목 수", "\(rows.count)", "개")
            if let topRow {
                summaryMetric("1위", "\(topRow.name)", topRow.symbol)
            }
            Spacer(minLength: 0)
        }
    }

    private func summaryMetric(_ title: String, _ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 150, alignment: .leading)
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MarketRankingPanel: View {
    let rows: [MarketActivitySnapshot]
    let metric: MarketRankingMetric
    let sourceText: String
    let onSelect: (String) -> Void

    private var visibleRows: [MarketActivitySnapshot] {
        Array(rows.prefix(300))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label(metric.title, systemImage: metric.systemImage)
                    .font(.headline)
                Spacer()
                Text(sourceText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }
            .padding(16)

            Divider()

            if visibleRows.isEmpty {
                ContentUnavailableView("표시할 종목이 없습니다", systemImage: "chart.bar")
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                LazyVStack(spacing: 0) {
                    MarketRankingHeader(metric: metric)
                    ForEach(Array(visibleRows.enumerated()), id: \.element.id) { index, row in
                        MarketRankingRow(rank: index + 1, row: row, metric: metric)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelect(row.symbol)
                            }
                        if row.id != visibleRows.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                    if rows.count > visibleRows.count {
                        Text("화면 성능을 위해 상위 \(visibleRows.count)개만 표시합니다. 전체 흐름은 섹터 히트맵에서 확인하세요.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(14)
                    }
                }
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MarketRankingHeader: View {
    let metric: MarketRankingMetric

    var body: some View {
        HStack(spacing: 12) {
            headerText("순위", width: 44, alignment: .leading)
            headerText("종목", minWidth: 180, alignment: .leading)
            headerText("시장", width: 96, alignment: .leading)
            headerText("현재가", width: 118, alignment: .trailing)
            headerText("등락", width: 84, alignment: .trailing)
            headerText(metric == .tradingVolume ? "거래량" : "거래대금", width: 150, alignment: .trailing)
            headerText(metric == .tradingVolume ? "거래대금" : "거래량", width: 150, alignment: .trailing)
            headerText("체결", width: 72, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color.secondary.opacity(0.08))
    }

    private func headerText(_ text: String, width: CGFloat? = nil, minWidth: CGFloat? = nil, alignment: Alignment) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(minWidth: minWidth, maxWidth: width == nil ? .infinity : width, alignment: alignment)
            .frame(width: width, alignment: alignment)
    }
}

struct MarketRankingRow: View {
    let rank: Int
    let row: MarketActivitySnapshot
    let metric: MarketRankingMetric

    var body: some View {
        HStack(spacing: 12) {
            Text("\(rank)")
                .font(.callout.monospacedDigit().weight(.semibold))
                .foregroundStyle(rank <= 3 ? .blue : .primary)
                .frame(width: 44, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(row.name)
                        .font(.callout.weight(.medium))
                        .lineLimit(1)
                    Text(row.symbol)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Text(row.englishName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(minWidth: 180, maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(row.marketScopeTitle)
                    .font(.caption.weight(.semibold))
                Text(row.market)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 96, alignment: .leading)

            Text("\(formattedDecimal(row.lastPriceValue, fractionDigits: row.currency == "KRW" ? 0 : 2)) \(row.currency)")
                .font(.callout.monospacedDigit())
                .frame(width: 118, alignment: .trailing)

            Text(changeText)
                .font(.callout.monospacedDigit().weight(.semibold))
                .foregroundStyle(sectorColor(row.changePercent))
                .frame(width: 84, alignment: .trailing)

            metricValue(primary: true)
                .frame(width: 150, alignment: .trailing)

            metricValue(primary: false)
                .frame(width: 150, alignment: .trailing)

            Text(row.tradeSampleCount > 0 ? "\(row.tradeSampleCount)건" : "-")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 72, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func metricValue(primary: Bool) -> some View {
        let showsTradingValue = (metric == .tradingValue) == primary
        return VStack(alignment: .trailing, spacing: 3) {
            Text(showsTradingValue ? formattedTradeValue(row.tradeValue, currency: row.currency) : formattedVolume(row.tradeVolume))
                .font(primary ? .callout.monospacedDigit().weight(.semibold) : .callout.monospacedDigit())
                .foregroundStyle(primary ? .primary : .secondary)
            Text(showsTradingValue ? "대금" : "수량")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func formattedTradeValue(_ value: Decimal?, currency: String) -> String {
        guard let value else {
            return "-"
        }
        return "\(compactDecimal(value, fractionDigits: 1)) \(currency)"
    }

    private func formattedVolume(_ value: Decimal?) -> String {
        guard let value else {
            return "-"
        }
        return compactDecimal(value, fractionDigits: 1)
    }

    private var changeText: String {
        guard let change = row.changePercent else {
            return "-"
        }
        return "\(change >= 0 ? "+" : "")\(formattedDouble(change, fractionDigits: 2))%"
    }
}

struct WatchlistView: View {
    @EnvironmentObject private var session: AppSession
    @State private var addDraft = ""
    @State private var showsAlertSheet = false
    @State private var alertSymbol = ""
    @State private var alertPrice = 0.0

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Label("관심종목", systemImage: "star")
                    .font(.title3.weight(.semibold))
                Spacer()
                StockSearchField(text: $addDraft, placeholder: "관심종목 추가", width: 260, showsSelectedName: true) { symbol in
                    session.addWatchedSymbol(from: symbol)
                    addDraft = ""
                    Task { await session.refreshMarketData() }
                }
                Button {
                    Task { await session.refreshMarketData() }
                } label: {
                    Label("새로고침", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    WatchlistTablePanel { symbol, price in
                        alertSymbol = symbol
                        alertPrice = price
                        showsAlertSheet = true
                    }

                    WatchlistBriefPanel()
                        .frame(maxWidth: .infinity)

                    PriceAlertsPanel()
                        .frame(maxWidth: .infinity)
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showsAlertSheet) {
            PriceAlertEditorSheet(initialSymbol: alertSymbol, initialPrice: alertPrice)
                .environmentObject(session)
                .frame(width: 460, height: 360)
        }
    }
}

struct WatchlistTablePanel: View {
    @EnvironmentObject private var session: AppSession
    let onCreateAlert: (String, Double) -> Void

    private var watchedRows: [String] {
        session.watchedSymbols
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("관심종목 표", systemImage: "tablecells")
                    .font(.headline)
                Spacer()
                Text("\(watchedRows.count)개")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)

            Divider()

            if watchedRows.isEmpty {
                ContentUnavailableView("관심종목이 없습니다", systemImage: "star")
                    .frame(maxWidth: .infinity, minHeight: 220)
            } else {
                VStack(spacing: 0) {
                    WatchlistHeader()
                    ForEach(watchedRows, id: \.self) { symbol in
                        WatchlistRow(symbol: symbol, onCreateAlert: onCreateAlert)
                            .environmentObject(session)
                        if symbol != watchedRows.last {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct WatchlistHeader: View {
    var body: some View {
        HStack(spacing: 12) {
            header("종목", minWidth: 220, alignment: .leading)
            header("현재가", width: 130, alignment: .trailing)
            header("보유", width: 100, alignment: .trailing)
            header("알림", width: 80, alignment: .trailing)
            header("작업", width: 210, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(Color.secondary.opacity(0.08))
    }

    private func header(_ text: String, width: CGFloat? = nil, minWidth: CGFloat? = nil, alignment: Alignment) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(minWidth: minWidth, maxWidth: width == nil ? .infinity : width, alignment: alignment)
            .frame(width: width, alignment: alignment)
    }
}

struct WatchlistRow: View {
    @EnvironmentObject private var session: AppSession
    let symbol: String
    let onCreateAlert: (String, Double) -> Void

    private var price: PriceResponse? {
        session.prices.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
    }

    private var holding: Holding? {
        session.holdings.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
    }

    private var alertCount: Int {
        session.priceAlerts.filter { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame && $0.isEnabled }.count
    }

    private var currentPrice: Double {
        price.map { NSDecimalNumber(decimal: $0.lastPriceValue).doubleValue } ?? 0
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(session.stockName(for: symbol) ?? symbol)
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
                Text(symbol)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
            .frame(minWidth: 220, maxWidth: .infinity, alignment: .leading)

            Text(priceText)
                .font(.callout.monospacedDigit())
                .frame(width: 130, alignment: .trailing)

            Text(holding?.quantity ?? "-")
                .font(.callout.monospacedDigit())
                .foregroundStyle(holding == nil ? .secondary : .primary)
                .frame(width: 100, alignment: .trailing)

            Text("\(alertCount)개")
                .font(.callout.monospacedDigit())
                .foregroundStyle(alertCount > 0 ? .orange : .secondary)
                .frame(width: 80, alignment: .trailing)

            HStack(spacing: 8) {
                Button {
                    session.selectedSymbol = symbol
                    session.selectedSection = .dashboard
                    Task { await session.refreshMarketData() }
                } label: {
                    Image(systemName: "chart.xyaxis.line")
                }
                .help("대시보드에서 보기")

                Button {
                    onCreateAlert(symbol, currentPrice)
                } label: {
                    Image(systemName: "bell.badge")
                }
                .help("가격 알림 만들기")

                Button {
                    session.removeWatchedSymbol(symbol)
                } label: {
                    Image(systemName: "trash")
                }
                .help("관심종목 삭제")
            }
            .buttonStyle(.bordered)
            .frame(width: 210, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var priceText: String {
        guard let price else {
            return "-"
        }
        return "\(formattedDecimal(price.lastPriceValue, fractionDigits: price.currency == "KRW" ? 0 : 2)) \(price.currency)"
    }
}

struct PriceAlertsPanel: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("가격 알림", systemImage: "bell")
                    .font(.headline)
                Spacer()
                Text("\(session.activePriceAlertCount)개 활성")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)

            Divider()

            if session.priceAlerts.isEmpty {
                Text("관심종목 표에서 종 모양 버튼을 눌러 가격 알림을 만들 수 있습니다.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
            } else {
                VStack(spacing: 0) {
                    ForEach(session.priceAlerts) { alert in
                        PriceAlertRow(alert: alert)
                            .environmentObject(session)
                        if alert.id != session.priceAlerts.last?.id {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
            }
        }
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct PriceAlertRow: View {
    @EnvironmentObject private var session: AppSession
    let alert: PriceAlert

    private var currentPrice: PriceResponse? {
        session.prices.first { $0.symbol.caseInsensitiveCompare(alert.symbol) == .orderedSame }
    }

    private var isExpired: Bool {
        alert.expiresAt <= Date()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: alert.isEnabled && !isExpired ? "bell.fill" : "bell.slash")
                .foregroundStyle(alert.isEnabled && !isExpired ? .orange : .secondary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(alert.name)
                        .font(.callout.weight(.medium))
                    Text(alert.symbol)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                Text("\(alert.conditionText) · 현재 \(currentPriceText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("만료 \(alert.expiresAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: Binding(
                get: { alert.isEnabled && !isExpired },
                set: { _ in session.togglePriceAlert(alert) }
            ))
            .labelsHidden()

            Button {
                session.removePriceAlert(alert)
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.bordered)
        }
        .padding(14)
    }

    private var currentPriceText: String {
        guard let currentPrice else {
            return "-"
        }
        return "\(formattedDecimal(currentPrice.lastPriceValue, fractionDigits: currentPrice.currency == "KRW" ? 0 : 2)) \(currentPrice.currency)"
    }
}

struct PriceAlertEditorSheet: View {
    @EnvironmentObject private var session: AppSession
    @Environment(\.dismiss) private var dismiss
    @State private var symbolDraft: String
    @State private var condition: PriceAlertCondition = .above
    @State private var targetPrice: Double

    init(initialSymbol: String, initialPrice: Double) {
        _symbolDraft = State(initialValue: initialSymbol)
        _targetPrice = State(initialValue: initialPrice)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("가격 알림 만들기", systemImage: "bell.badge")
                .font(.title3.weight(.semibold))

            Text("조건이 맞으면 주문하지 않고 macOS 알림과 로그만 남깁니다. 자동 감시가 켜져 있어야 1분마다 확인합니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            StockSearchField(text: $symbolDraft, placeholder: "종목명 또는 코드", width: 360, showsSelectedName: true) { symbol in
                symbolDraft = session.stockDisplayText(for: symbol)
                if let price = session.prices.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
                    targetPrice = NSDecimalNumber(decimal: price.lastPriceValue).doubleValue
                }
            }

            Picker("조건", selection: $condition) {
                ForEach(PriceAlertCondition.allCases) { condition in
                    Text("현재가 \(condition.title)").tag(condition)
                }
            }
            .pickerStyle(.segmented)

            HStack(spacing: 8) {
                TextField("목표 가격", value: $targetPrice, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 180)
                Button {
                    let symbol = session.resolveSymbol(from: symbolDraft)
                    if let price = session.prices.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
                        targetPrice = NSDecimalNumber(decimal: price.lastPriceValue).doubleValue
                    }
                } label: {
                    Label("현재가", systemImage: "arrow.clockwise")
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("취소") {
                    dismiss()
                }
                Button {
                    session.createPriceAlert(symbolInput: symbolDraft, targetPrice: targetPrice, condition: condition)
                    dismiss()
                } label: {
                    Label("알림 저장", systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(targetPrice <= 0 || symbolDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
    }
}

struct AccountView: View {
    @EnvironmentObject private var session: AppSession
    @State private var orderSymbolDraft = "삼성전자 · 005930"
    @State private var orderSide: StrategyAction = .buy
    @State private var orderType: DraftOrderType = .limit
    @State private var orderAmount = 100_000.0
    @State private var orderQuantity = 0.0
    @State private var orderLimitPrice = 0.0
    @State private var isCreatingOrderDraft = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("계좌", systemImage: "person.crop.circle")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    Task {
                        await session.refreshAccounts()
                        await session.refreshHoldings()
                    }
                } label: {
                    Label("새로고침", systemImage: "arrow.clockwise")
                }
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("계좌 선택", systemImage: "creditcard")
                            .font(.headline)

                        if session.accounts.isEmpty {
                            Text("불러온 계좌가 없습니다. 새로고침으로 계좌를 먼저 확인하세요.")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                        } else {
                            ForEach(session.accounts) { account in
                                AccountRow(
                                    account: account,
                                    isSelected: session.selectedAccountSeq == account.accountSeq
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    session.selectedAccountSeq = account.accountSeq
                                    session.saveAppState()
                                }
                            }
                        }
                    }

                    AccountManualOrderPanel(
                        symbolDraft: $orderSymbolDraft,
                        side: $orderSide,
                        orderType: $orderType,
                        amount: $orderAmount,
                        quantity: $orderQuantity,
                        limitPrice: $orderLimitPrice,
                        isCreating: isCreatingOrderDraft,
                        status: session.manualOrderStatus,
                        allowLiveOrders: session.safetySettings.allowLiveOrders
                    ) {
                        createManualOrderDraft()
                    }

                    PendingOrdersPanel()
                        .environmentObject(session)

                    HStack(alignment: .top, spacing: 18) {
                        HoldingsPanel(holdings: session.holdings) { holding, side in
                            fillManualOrder(from: holding, side: side)
                        }
                        PricesPanel(prices: session.prices)
                    }
                }
                .padding(20)
            }
        }
        .onAppear {
            orderSymbolDraft = session.stockDisplayText(for: session.selectedSymbol)
            seedLimitPrice()
        }
    }

    private func createManualOrderDraft() {
        guard !isCreatingOrderDraft else {
            return
        }
        isCreatingOrderDraft = true
        Task {
            await session.createManualOrderDraft(
                symbolInput: orderSymbolDraft,
                side: orderSide,
                orderType: orderType,
                amount: orderAmount,
                quantity: orderQuantity,
                limitPrice: orderLimitPrice
            )
            isCreatingOrderDraft = false
        }
    }

    private func fillManualOrder(from holding: Holding, side: StrategyAction) {
        orderSymbolDraft = session.stockDisplayText(for: holding.symbol)
        orderSide = side
        orderType = .limit
        orderLimitPrice = currentPrice(for: holding.symbol) ?? estimatedHoldingPrice(holding)
        if side == .sell {
            orderQuantity = NSDecimalNumber(decimal: decimalValue(holding.quantity)).doubleValue
            orderAmount = 0
        } else {
            orderQuantity = 0
            orderAmount = holding.currency.uppercased() == "KRW" ? 100_000 : 100_000
        }
    }

    private func seedLimitPrice() {
        let symbol = session.resolveSymbol(from: orderSymbolDraft)
        orderLimitPrice = currentPrice(for: symbol) ?? orderLimitPrice
    }

    private func currentPrice(for symbol: String) -> Double? {
        session.prices.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
            .map { NSDecimalNumber(decimal: $0.lastPriceValue).doubleValue }
    }

    private func estimatedHoldingPrice(_ holding: Holding) -> Double {
        let quantity = NSDecimalNumber(decimal: decimalValue(holding.quantity)).doubleValue
        let value = NSDecimalNumber(decimal: decimalValue(holding.value)).doubleValue
        guard quantity > 0 else {
            return 0
        }
        return value / quantity
    }
}

struct AccountRow: View {
    let account: Account
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? .green : .secondary)
                .accessibilityLabel(isSelected ? "선택된 계좌" : "선택 안 됨")

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text("계좌번호")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(account.accountNo)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                }

                HStack(spacing: 16) {
                    labeledValue("API 계좌 ID", "\(account.accountSeq)")
                        .help("토스증권 API의 X-Tossinvest-Account 헤더에 쓰이는 내부 식별값입니다.")
                    labeledValue("유형", account.accountTypeTitle)
                        .help("\(account.accountType): \(account.accountTypeDescription)")
                }
            }

            Spacer()

            Text(isSelected ? "사용 중" : "선택")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .green : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary.opacity(0.45), in: Capsule())
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.green.opacity(0.5) : Color.secondary.opacity(0.12))
        )
    }

    private func labeledValue(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.callout.weight(.medium))
        }
    }
}

struct AccountManualOrderPanel: View {
    @EnvironmentObject private var session: AppSession
    @Binding var symbolDraft: String
    @Binding var side: StrategyAction
    @Binding var orderType: DraftOrderType
    @Binding var amount: Double
    @Binding var quantity: Double
    @Binding var limitPrice: Double
    let isCreating: Bool
    let status: String
    let allowLiveOrders: Bool
    let onCreate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("단일 종목 주문 테스트", systemImage: "bolt.badge.clock")
                    .font(.headline)
                Spacer()
                Label(allowLiveOrders ? "실주문 허용" : "실주문 잠김", systemImage: allowLiveOrders ? "lock.open" : "lock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(allowLiveOrders ? .orange : .secondary)
            }

            Text("먼저 주문 후보만 만듭니다. 실제 주문은 아래 승인 대기 카드에서 한 번 더 눌러야 제출됩니다.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 12) {
                StockSearchField(text: $symbolDraft, placeholder: "종목명 또는 코드", width: 260, showsSelectedName: true) { symbol in
                    symbolDraft = session.stockDisplayText(for: symbol)
                    seedPrice(symbol)
                }

                Picker("방향", selection: $side) {
                    Text("매수").tag(StrategyAction.buy)
                    Text("매도").tag(StrategyAction.sell)
                }
                .pickerStyle(.segmented)
                .frame(width: 150)

                Picker("주문", selection: $orderType) {
                    ForEach(DraftOrderType.allCases) { type in
                        Text(type.title).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 150)
            }

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 10) {
                GridRow {
                    orderNumberField("금액", value: $amount, suffix: "원")
                    orderNumberField("수량", value: $quantity, suffix: "주")
                    orderNumberField(orderType == .limit ? "지정가" : "참고가", value: $limitPrice, suffix: "")
                }
            }

            HStack(spacing: 10) {
                Button(action: onCreate) {
                    if isCreating {
                        Label("만드는 중", systemImage: "hourglass")
                    } else {
                        Label("주문 후보 만들기", systemImage: "plus.circle")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCreating)

                Button {
                    seedPrice(session.resolveSymbol(from: symbolDraft))
                } label: {
                    Label("현재가 넣기", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.bordered)

                Text(status)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func orderNumberField(_ title: String, value: Binding<Double>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                TextField(title, value: value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 130)
                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func seedPrice(_ symbol: String) {
        if let price = session.prices.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
            limitPrice = NSDecimalNumber(decimal: price.lastPriceValue).doubleValue
        }
    }
}

struct OrdersView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("주문", systemImage: "arrow.left.arrow.right")
                .font(.title3.weight(.semibold))
            Text("주문 입력과 주문 내역 화면은 다음 단계에서 구현합니다.")
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(20)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var session: AppSession
    @State private var saveMessage = ""
    @State private var watchedSymbolDraft = ""

    var body: some View {
        ScrollView {
            Form {
                Section("토스증권 API") {
                    TextField("클라이언트 ID", text: $session.credentials.clientID)
                    SecureField("클라이언트 시크릿", text: $session.credentials.clientSecret)

                    HStack {
                        Button {
                            do {
                                try session.saveCredentials()
                                saveMessage = "저장됨"
                            } catch {
                                saveMessage = error.localizedDescription
                            }
                        } label: {
                            Label("키체인 저장", systemImage: "key")
                        }
                        .buttonStyle(.borderedProminent)

                        Text(saveMessage)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("tossctl 후보 보강") {
                    Toggle("토스 인기순위 후보 가져오기", isOn: $session.tossCLISettings.isEnabled)

                    Text("JungHoonGhae/tossinvest-cli가 설치되어 있고 `tossctl auth login`이 된 경우에만 사용하세요. 이 기능은 토스 웹 인기순위로 후보를 넓히는 보조 기능이며, 거래대금 Top100 원본 데이터가 아닙니다. 실패하면 기존 공식 API 후보 방식으로 돌아갑니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("tossctl 경로 또는 명령어", text: $session.tossCLISettings.commandPath)

                    Stepper(
                        "가져올 인기순위 \(session.tossCLISettings.rankingSize)개",
                        value: $session.tossCLISettings.rankingSize,
                        in: 5...100,
                        step: 5
                    )

                    HStack(spacing: 10) {
                        Button {
                            Task {
                                await session.refreshMarketActivity()
                            }
                        } label: {
                            Label("후보 보강 테스트", systemImage: "scope")
                        }
                        .buttonStyle(.borderedProminent)

                        Text(session.tossCLIDiscoveryStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("AI CLI 명령어") {
                    ForEach($session.aiEngines) { $engine in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Toggle(engine.engine.displayName, isOn: $engine.isEnabled)
                                Spacer()
                                Button {
                                    Task { await session.testAIEngine(engine.engine) }
                                } label: {
                                    Label("테스트", systemImage: "terminal")
                                }
                            }
                            Text(engine.engine.role)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("분석 명령어", text: $engine.analysisCommand)
                            TextField("버전 확인 명령어", text: $engine.versionCommand)
                            Text(engine.lastStatus)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                }

                Section("투자 성향") {
                    TextField("국가", text: $session.investorProfile.country)
                    TextField("목표", text: $session.investorProfile.primaryGoal)

                    Picker("위험 성향", selection: $session.investorProfile.riskTolerance) {
                        ForEach(InvestorRiskTolerance.allCases) { tolerance in
                            Text(tolerance.title).tag(tolerance)
                        }
                    }
                    .pickerStyle(.segmented)

                    Text(session.investorProfile.riskTolerance.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    TextField("선호 업종", text: $session.investorProfile.preferredIndustries)
                    Toggle("관심종목 데일리 브리프 사용", isOn: $session.investorProfile.dailyBriefEnabled)
                }

                Section("안전 한도") {
                    Toggle("라이브 주문 허용", isOn: $session.safetySettings.allowLiveOrders)
                    Toggle("시장가 주문 추가 확인", isOn: $session.safetySettings.requireMarketOrderConfirmation)
                    Toggle("중복 주문 차단", isOn: $session.safetySettings.blockDuplicateOrders)
                    Toggle("API 오류 시 자동매매 중지", isOn: $session.safetySettings.haltOnAPIError)
                    Toggle("네트워크 장애 시 주문 차단", isOn: $session.safetySettings.blockOnNetworkFailure)
                    Toggle("장 운영일 확인", isOn: $session.safetySettings.respectMarketCalendar)

                    Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 10) {
                        GridRow {
                            settingNumber("일일 매수 한도", value: $session.safetySettings.dailyBuyLimit)
                            settingNumber("일일 손실 한도", value: $session.safetySettings.dailyLossLimit)
                        }
                        GridRow {
                            settingNumber("종목 최대 비중 %", value: $session.safetySettings.maxPositionPercent)
                            Stepper("주문 쿨다운 \(session.safetySettings.orderCooldownSeconds)초", value: $session.safetySettings.orderCooldownSeconds, in: 10...3600)
                        }
                    }
                }

                Section("실주문 연결 점검") {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("실제 주문을 넣지 않고, 주문에 필요한 API 연결만 확인합니다.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        HStack(spacing: 10) {
                            Button {
                                Task {
                                    await session.runLiveOrderReadinessCheck()
                                }
                            } label: {
                                Label(session.isLiveOrderReadinessChecking ? "점검 중" : "실주문 연결 점검", systemImage: "checkmark.shield")
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(session.isLiveOrderReadinessChecking)

                            if session.isLiveOrderReadinessChecking {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }

                        Text(session.liveOrderReadinessCheckStatus)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                            .lineSpacing(3)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
                    }
                }

                Section("종목") {
                    StockSearchField(text: $watchedSymbolDraft, placeholder: "관심 종목 추가", width: 260) { symbol in
                        session.addWatchedSymbol(from: symbol)
                        watchedSymbolDraft = ""
                    }

                    TextField(
                        "관심 종목",
                        text: Binding(
                            get: { session.watchedSymbols.joined(separator: ",") },
                            set: { value in
                                session.watchedSymbols = value
                                    .split(separator: ",")
                                    .map { session.resolveSymbol(from: String($0)) }
                                    .filter { !$0.isEmpty }
                            }
                        )
                    )
                }

                Section("정책") {
                    Text("본 앱은 투자 수익을 보장하지 않으며, 모든 투자 판단과 손실 책임은 사용자에게 있습니다. AI 분석은 참고용이며 매수·매도 결정을 보장하지 않습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    session.saveAppState()
                    saveMessage = "저장됨"
                } label: {
                    Label("설정 저장", systemImage: "tray.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(20)
        }
        .onChange(of: session.safetySettings) { _, _ in
            session.saveAppState()
            saveMessage = "자동 저장됨"
        }
        .onChange(of: session.aiEngines) { _, _ in
            session.saveAppState()
            saveMessage = "자동 저장됨"
        }
        .onChange(of: session.tossCLISettings) { _, _ in
            session.saveAppState()
            saveMessage = "자동 저장됨"
        }
        .onChange(of: session.investorProfile) { _, _ in
            session.saveAppState()
            saveMessage = "자동 저장됨"
        }
    }

    private func settingNumber(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 170)
        }
    }
}
