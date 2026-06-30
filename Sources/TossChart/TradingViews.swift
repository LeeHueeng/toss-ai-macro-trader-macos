import Charts
import Foundation
import SwiftUI

enum StrategyEditorStep: String, CaseIterable, Identifiable {
    case basic
    case conditions
    case risk
    case review
    case execution

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basic: "기본"
        case .conditions: "조건"
        case .risk: "위험"
        case .review: "AI 검토"
        case .execution: "실행"
        }
    }
}

enum StrategyManagerMode: String, CaseIterable, Identifiable {
    case autoPick
    case mechanical
    case ai
    case manual

    var id: String { rawValue }

    var title: String {
        switch self {
        case .autoPick: "자동 선택"
        case .mechanical: "기계적 매매"
        case .ai: "AI 모드"
        case .manual: "직접 입력"
        }
    }
}

enum MechanicalStrategyTemplate: String, CaseIterable, Identifiable {
    case movingAverageCross
    case rsiRebound
    case bollingerRebound
    case breakout
    case macdCross
    case surgeVolumeMomentum
    case plungeRebound
    case tradeValueFocus
    case fixedGridTrading
    case bollingerBandChannel
    case rsiBandChannel
    case meanReversionCombo
    case marketMakingLite
    case koquantMinuteMomentum
    case rangeSwingRebound
    case rangeUpperWarning
    case semiconductorValueBreakout
    case semiconductorDipStabilize
    case semiconductorTrendRestart

    var id: String { rawValue }

    var title: String {
        switch self {
        case .movingAverageCross: "이동평균 골든크로스"
        case .rsiRebound: "RSI 과매도 반등"
        case .bollingerRebound: "볼린저 하단 반등"
        case .breakout: "전고점 돌파"
        case .macdCross: "MACD 상승 전환"
        case .surgeVolumeMomentum: "급등 거래량 추세"
        case .plungeRebound: "급락 반등 확인"
        case .tradeValueFocus: "거래대금 집중"
        case .fixedGridTrading: "고정 간격 그리드"
        case .bollingerBandChannel: "볼린저 하단 매수·상단 매도"
        case .rsiBandChannel: "RSI 과매도 매수·과매수 매도"
        case .meanReversionCombo: "볼린저+RSI 평균회귀"
        case .marketMakingLite: "간이 마켓메이킹"
        case .koquantMinuteMomentum: "KOQUANT 분봉 거래대금 돌파"
        case .rangeSwingRebound: "2~3% 박스권 하단 반등"
        case .rangeUpperWarning: "2~3% 박스권 상단 알림"
        case .semiconductorValueBreakout: "반도체 거래대금 돌파"
        case .semiconductorDipStabilize: "반도체 급락 진정"
        case .semiconductorTrendRestart: "반도체 추세 재점화"
        }
    }

    var formula: String {
        switch self {
        case .movingAverageCross: "짧은 평균선이 긴 평균선을 아래에서 위로 넘으면 신호"
        case .rsiRebound: "RSI가 과매도 구간 아래에 있다가 다시 올라오면 신호"
        case .bollingerRebound: "가격이 볼린저 하단 밖으로 밀렸다가 다시 안으로 들어오면 신호"
        case .breakout: "현재 종가가 최근 고점 구간을 돌파하면 신호"
        case .macdCross: "MACD선이 시그널선을 아래에서 위로 넘으면 신호"
        case .surgeVolumeMomentum: "짧은 시간에 크게 오르고 거래량이 평소보다 많이 붙으면 신호"
        case .plungeRebound: "급락 직후 바로 첫 반등이 나오면 신호"
        case .tradeValueFocus: "가격보다 거래대금이 갑자기 커진 종목을 찾는 신호"
        case .fixedGridTrading: "기준가를 중심으로 일정 간격마다 내려오면 분할매수, 올라가면 분할매도"
        case .bollingerBandChannel: "볼린저밴드 하단에 닿으면 매수 후보, 상단에 닿으면 매도 후보"
        case .rsiBandChannel: "RSI가 과매도권에 들어가면 매수 후보, 과매수권에 들어가면 매도 후보"
        case .meanReversionCombo: "볼린저 하단과 RSI 과매도를 함께 확인해 평균회귀 진입, 상단/과매수에서 청산"
        case .marketMakingLite: "최근 평균가격 주변에 좁은 매수·매도 호가 후보를 두는 보수형 양방향 룰"
        case .koquantMinuteMomentum: "최근 평균 거래대금보다 크게 붙고, 종가가 최근 VWAP 위에 있으면 단기 매수 후보"
        case .rangeSwingRebound: "2~3%씩 오르내리는 박스권의 아래쪽에서 반등하면 신호"
        case .rangeUpperWarning: "2~3% 박스권 위쪽에 닿으면 추격매수 주의 알림"
        case .semiconductorValueBreakout: "최근 고점을 넘으면서 거래량이 평균보다 크게 붙으면 신호"
        case .semiconductorDipStabilize: "짧은 급락 뒤 매도 압력이 줄고 첫 반등이 나오면 신호"
        case .semiconductorTrendRestart: "짧은 추세가 긴 추세 위에 있고 최근 저항을 다시 넘으면 신호"
        }
    }

    var sourceNote: String {
        switch self {
        case .movingAverageCross:
            "backtrader, backtesting.py, Lean 예제에서 자주 쓰이는 기본 추세 추종 룰"
        case .rsiRebound:
            "quant-trading, Stock.Indicators 계열에서 흔한 오실레이터 룰"
        case .bollingerRebound:
            "quant-trading, 기술적 분석 라이브러리에서 자주 쓰이는 평균회귀 룰"
        case .breakout:
            "London Breakout, Dual Thrust류 전략에서 반복되는 돌파 룰"
        case .macdCross:
            "MACD 기반 추세 전환 전략에서 많이 쓰이는 신호"
        case .surgeVolumeMomentum:
            "급등주 스캐너, 상대거래량 돌파, breakout scanner repo에서 반복되는 단기 모멘텀 룰"
        case .plungeRebound:
            "평균회귀와 급락 후 되돌림 전략에서 쓰는 방어형 반등 확인 룰"
        case .tradeValueFocus:
            "거래량보다 실전 체감에 가까운 거래대금 급증 감시 룰"
        case .fixedGridTrading:
            "OctoBot, OpenTrader, chrisleekr/binance-trading-bot류의 고정 가격 간격 그리드 룰"
        case .bollingerBandChannel:
            "Freqtrade, Backtrader 예제에서 흔한 평균회귀형 밴드 터치 룰"
        case .rsiBandChannel:
            "Freqtrade/OpenTrader 계열에서 초보자용으로 자주 제공되는 RSI 임계값 룰"
        case .meanReversionCombo:
            "Bollinger + RSI 조합으로 단독 지표 오신호를 줄이는 평균회귀 룰"
        case .marketMakingLite:
            "Hummingbot, Passivbot, Krypto-trading-bot의 양방향 호가·스프레드 개념을 주식 분봉용으로 단순화"
        case .koquantMinuteMomentum:
            "DAWNCR0W/koquant의 minute_momentum 샘플을 토스 분봉 데이터와 초보자용 위험 설정에 맞게 재구현"
        case .rangeSwingRebound:
            "볼린저/평균회귀 계열의 박스권 하단 매수 후보 룰"
        case .rangeUpperWarning:
            "박스권 상단에서 추격매수를 피하기 위한 알림 전용 룰"
        case .semiconductorValueBreakout:
            "한국 반도체/HBM 이슈장에서 자주 보는 거래대금 급증+돌파 흐름을 단순화"
        case .semiconductorDipStabilize:
            "반도체 대형주의 뉴스성 급락 이후 추격매도 진정 여부를 보는 방어형 룰"
        case .semiconductorTrendRestart:
            "삼성전자, SK하이닉스, NVDA처럼 이슈 민감 종목의 추세 재진입 확인용 룰"
        }
    }

    var token: String {
        switch self {
        case .movingAverageCross: "SMA_CROSS"
        case .rsiRebound: "RSI_REBOUND"
        case .bollingerRebound: "BOLLINGER_REBOUND"
        case .breakout: "BREAKOUT"
        case .macdCross: "MACD_CROSS"
        case .surgeVolumeMomentum: "SURGE_VOLUME_MOMENTUM"
        case .plungeRebound: "PLUNGE_REBOUND"
        case .tradeValueFocus: "TRADE_VALUE_FOCUS"
        case .fixedGridTrading: "FIXED_GRID"
        case .bollingerBandChannel: "BOLLINGER_CHANNEL"
        case .rsiBandChannel: "RSI_CHANNEL"
        case .meanReversionCombo: "MEAN_REVERSION_COMBO"
        case .marketMakingLite: "MARKET_MAKING_LITE"
        case .koquantMinuteMomentum: "KOQUANT_MINUTE_MOMENTUM"
        case .rangeSwingRebound: "RANGE_SWING_REBOUND"
        case .rangeUpperWarning: "RANGE_UPPER_WARNING"
        case .semiconductorValueBreakout: "SEMI_VALUE_BREAKOUT"
        case .semiconductorDipStabilize: "SEMI_DIP_STABILIZE"
        case .semiconductorTrendRestart: "SEMI_TREND_RESTART"
        }
    }

    var isTwoSided: Bool {
        switch self {
        case .fixedGridTrading, .bollingerBandChannel, .rsiBandChannel, .meanReversionCombo, .marketMakingLite:
            true
        default:
            false
        }
    }
}

enum SimpleMacroTemplate: String, CaseIterable, Identifiable {
    case buyDip
    case watchExit
    case priceAlert

    var id: String { rawValue }

    var title: String {
        switch self {
        case .buyDip: "떨어지면 사기"
        case .watchExit: "손절·익절 지켜보기"
        case .priceAlert: "가격 오면 알림"
        }
    }

    var detail: String {
        switch self {
        case .buyDip: "분봉을 보다가 정한 만큼 내려오면 매수 후보로 올립니다."
        case .watchExit: "보유 중인 종목이 손절·익절 구간에 오면 알려줍니다."
        case .priceAlert: "원하는 가격 근처에 오면 주문 없이 알림만 줍니다."
        }
    }
}

enum SimpleMacroMode: String, CaseIterable, Identifiable {
    case alert
    case ask
    case auto

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alert: "알림만"
        case .ask: "물어보고 주문"
        case .auto: "자동 주문"
        }
    }

    var operationMode: OperationMode {
        switch self {
        case .alert: .alertOnly
        case .ask: .confirmBeforeOrder
        case .auto: .autoOrder
        }
    }
}

enum AIChartPayloadMode: String, CaseIterable, Identifiable {
    case compact
    case full

    var id: String { rawValue }

    var title: String {
        switch self {
        case .compact: "핵심"
        case .full: "전체"
        }
    }

    var candleLimit: Int {
        switch self {
        case .compact: 240
        case .full: 1_440
        }
    }
}

struct MechanicalAITuningSuggestion: Codable, Equatable {
    var template: String?
    var triggerPercent: Double?
    var shortPeriod: Double?
    var longPeriod: Double?
    var rsiPeriod: Double?
    var rsiLevel: Double?
    var bandPeriod: Double?
    var bandStdDev: Double?
    var breakoutLookback: Double?
    var volumeMultiplier: Double?
    var stopLossPercent: Double?
    var takeProfitPercent: Double?
    var buyAmount: Double?
    var cooldownMinutes: Double?
    var reason: String?
    var riskNote: String?
}

struct SimpleBacktestSummary {
    let signalCount: Int
    let winCount: Int
    let averageReturn: Double
    let worstReturn: Double
    let estimatedPnL: Double

    var winRate: Double {
        guard signalCount > 0 else {
            return 0
        }
        return Double(winCount) / Double(signalCount) * 100
    }

    var hasSignals: Bool {
        signalCount > 0
    }
}

struct StrategyRankingResult: Identifiable {
    let template: MechanicalStrategyTemplate
    let summary: SimpleBacktestSummary

    var id: String { template.id }
}

struct SimplePreviewData {
    let candles: [Candle]
    let signalIndexes: [Int]
    let summary: SimpleBacktestSummary
}

struct MechanicalPreviewData {
    let candles: [Candle]
    let signalIndexes: [Int]
    let exitSignalIndexes: [Int]
    let summary: SimpleBacktestSummary
    let rankings: [StrategyRankingResult]
}

struct AutoAllocationCandidate: Identifiable {
    var id: String { symbol }
    let symbol: String
    let name: String
    let market: String
    let currency: String
    let lastPrice: String
    let template: MechanicalStrategyTemplate
    let summary: SimpleBacktestSummary
    let trendScore: Double
    let trendPercent: Double
    let tradeValueText: String
    let suggestedAmount: Double
    let expectedQuantity: Double
    let expectedPnL: Double
    let affordabilityText: String
    let executionHint: String
    let reason: String
    let berkshireVerdict: String
    let berkshireGuardText: String
    let allowsAutoOrder: Bool
}

struct StrategyManagerView: View {
    @EnvironmentObject private var session: AppSession
    @State private var selectedManagerMode: StrategyManagerMode = .mechanical
    @State private var symbolDraft = "엔비디아 · NVDA"
    @State private var selectedTemplate: SimpleMacroTemplate = .buyDip
    @State private var selectedMechanicalTemplate: MechanicalStrategyTemplate = .movingAverageCross
    @State private var selectedMode: SimpleMacroMode = .ask
    @State private var aiStrategyInput = "엔비디아가 분봉에서 급락 후 반등 신호가 나오면 30만 원만 매수 후보로 올려줘"
    @State private var triggerPercent = 2.0
    @State private var buyAmount = 300_000.0
    @State private var stopLossPercent = -5.0
    @State private var takeProfitPercent = 6.0
    @State private var cooldownMinutes = 10
    @State private var reviewEngine: AIEngineKind = .claude
    @State private var shortPeriod = 5.0
    @State private var longPeriod = 20.0
    @State private var rsiPeriod = 14.0
    @State private var rsiLevel = 30.0
    @State private var bandPeriod = 20.0
    @State private var bandStdDev = 2.0
    @State private var breakoutLookback = 20.0
    @State private var volumeMultiplier = 1.8
    @State private var isPreviewRefreshing = false
    @State private var aiChartPayloadMode: AIChartPayloadMode = .compact
    @State private var isMechanicalAITuning = false
    @State private var mechanicalAITuningSuggestion: MechanicalAITuningSuggestion?
    @State private var mechanicalAITuningOutput = ""
    @State private var mechanicalAITuningError: String?
    @State private var autoAllocationBudget = 1_000_000.0
    @State private var autoPickCount = 3.0
    @State private var autoScanLimit = 8.0
    @State private var autoScope: MarketScope = .all
    @State private var isAutoScanning = false
    @State private var autoCandidates: [AutoAllocationCandidate] = []
    @State private var autoScanError: String?

    private var backtestSummary: SimpleBacktestSummary {
        simplePreviewData.summary
    }

    private var mechanicalBacktestSummary: SimpleBacktestSummary {
        mechanicalPreviewData.summary
    }

    private var selectedMechanicalSignalIndexes: [Int] {
        mechanicalPreviewData.signalIndexes
    }

    private var selectedSimpleSignalIndexes: [Int] {
        simplePreviewData.signalIndexes
    }

    private var mechanicalRankings: [StrategyRankingResult] {
        mechanicalPreviewData.rankings
    }

    private var simplePreviewData: SimplePreviewData {
        let candles = previewCandles
        let signalIndexes = simpleSignalIndexes(candles: candles)
        let summary = simulateSimpleMacro(candles: candles, signalIndexes: signalIndexes)
        return SimplePreviewData(candles: candles, signalIndexes: signalIndexes, summary: summary)
    }

    private var mechanicalPreviewData: MechanicalPreviewData {
        let candles = previewCandles
        let signalIndexes = mechanicalSignalIndexes(for: selectedMechanicalTemplate, candles: candles)
        let exitSignalIndexes = mechanicalExitSignalIndexes(for: selectedMechanicalTemplate, candles: candles)
        let summary = simulateMechanicalStrategy(candles: candles, signalIndexes: signalIndexes, exitSignalIndexes: exitSignalIndexes)
        let rankings = MechanicalStrategyTemplate.allCases.map { template in
            let signals = mechanicalSignalIndexes(for: template, candles: candles)
            let exits = mechanicalExitSignalIndexes(for: template, candles: candles)
            let summary = MechanicalSignalEngine.summary(
                candles: candles,
                signalIndexes: signals,
                tradeAmount: buyAmount,
                exitSignalIndexes: exits,
                stopLossPercent: stopLossPercent,
                takeProfitPercent: takeProfitPercent
            )
            return StrategyRankingResult(template: template, summary: summary)
        }
        .sorted { lhs, rhs in
            if lhs.summary.hasSignals != rhs.summary.hasSignals {
                return lhs.summary.hasSignals && !rhs.summary.hasSignals
            }
            if lhs.summary.averageReturn == rhs.summary.averageReturn {
                return lhs.summary.estimatedPnL > rhs.summary.estimatedPnL
            }
            return lhs.summary.averageReturn > rhs.summary.averageReturn
        }
        return MechanicalPreviewData(candles: candles, signalIndexes: signalIndexes, exitSignalIndexes: exitSignalIndexes, summary: summary, rankings: rankings)
    }

    private var previewCandles: [Candle] {
        let sortedCandles = session.candles.sorted { $0.date < $1.date }
        switch session.chartTimeframe {
        case .oneMinuteRegular, .oneMinuteExtended, .daily:
            return sortedCandles
        case .weekly:
            return aggregatePreviewCandles(sortedCandles, by: .weekOfYear)
        case .monthly:
            return aggregatePreviewCandles(sortedCandles, by: .month)
        }
    }

    private var previewIdentity: String {
        let candles = previewCandles
        let latestCandle = candles.last
        return [
            selectedManagerMode.rawValue,
            session.selectedSymbol,
            session.chartTimeframe.rawValue,
            "\(candles.count)",
            latestCandle?.timestamp ?? "",
            latestCandle?.closePrice ?? "",
            selectedTemplate.rawValue,
            selectedMechanicalTemplate.rawValue,
            "\(triggerPercent)",
            "\(buyAmount)",
            "\(stopLossPercent)",
            "\(takeProfitPercent)",
            "\(shortPeriod)",
            "\(longPeriod)",
            "\(rsiPeriod)",
            "\(rsiLevel)",
            "\(bandPeriod)",
            "\(bandStdDev)",
            "\(breakoutLookback)",
            "\(volumeMultiplier)"
        ].joined(separator: "-")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("전략 관리", systemImage: "slider.horizontal.3")
                    .font(.title3.weight(.semibold))
                Spacer()
                Picker("AI", selection: $reviewEngine) {
                    ForEach(AIEngineKind.allCases) { engine in
                        Text(engine.displayName).tag(engine)
                    }
                }
                .frame(width: 180)
            }
            .padding(20)

            Divider()

            Picker("전략 모드", selection: $selectedManagerMode) {
                ForEach(StrategyManagerMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
            switch selectedManagerMode {
                    case .autoPick:
                        autoPickBuilder
                    case .mechanical:
                        mechanicalBuilder
                    case .ai:
                        aiBuilder
                    case .manual:
                        simpleBuilder
                    }
                    myMacros
                }
                .padding(20)
            }
        }
        .onAppear {
            if symbolDraft == "엔비디아 · NVDA" {
                symbolDraft = session.stockDisplayText(for: session.selectedSymbol)
            }
            prepareMacroPreview()
        }
    }

    private var autoPickBuilder: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("종목을 직접 고르지 않고, 예산과 시장 범위만 정하면 앱 후보군 안에서 거래대금과 최근 분봉 추세를 보고 후보를 고릅니다. 기본은 승인 후 주문으로 시작하는 것을 권장합니다.")
                .font(.callout)
                .foregroundStyle(.secondary)

            builderStep(number: 1, title: "예산과 범위") {
                HStack(spacing: 12) {
                    easyNumberField("총 예산", value: $autoAllocationBudget, suffix: "원")
                    easyNumberField("나눌 종목", value: $autoPickCount, suffix: "개")
                    easyNumberField("훑을 후보", value: $autoScanLimit, suffix: "개")

                    Picker("시장", selection: $autoScope) {
                        ForEach(MarketScope.allCases) { scope in
                            Text(scope.title).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }

                Picker("실행 방식", selection: $selectedMode) {
                    ForEach(SimpleMacroMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 360)
            }

            builderStep(number: 2, title: "앱이 후보 찾기") {
                HStack(spacing: 10) {
                    Button {
                        Task {
                            await runAutoAllocationScan()
                        }
                    } label: {
                        Label(isAutoScanning ? "찾는 중" : "추세 좋은 종목 찾기", systemImage: "scope")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAutoScanning)

                    if isAutoScanning {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Text("전체 시장 순위가 아니라 앱 후보군에서 거래대금이 큰 종목의 최근 분봉을 확인합니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Label(session.tossCLIDiscoveryStatus, systemImage: session.tossCLISettings.isEnabled ? "terminal" : "terminal.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label(session.marketActivityQualityText, systemImage: session.marketActivityAllowsAutoSelection ? "checkmark.shield" : "exclamationmark.shield")
                    .font(.caption)
                    .foregroundStyle(session.marketActivityAllowsAutoSelection ? .green : .orange)

                if let autoScanError {
                    Label(autoScanError, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                AutoAllocationCandidatePanel(candidates: autoCandidates)
            }

            builderStep(number: 3, title: "전략 초안 만들기") {
                SimpleExecutionGuard(mode: selectedMode, allowLiveOrders: session.safetySettings.allowLiveOrders)

                HStack(spacing: 10) {
                    Button {
                        createAutoAllocationMacros(startNow: false)
                    } label: {
                        Label("선택 후보로 만들기", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(autoCandidates.isEmpty)

                    Button {
                        createAutoAllocationMacros(startNow: true)
                    } label: {
                        Label("만들고 감시 시작", systemImage: "play.circle")
                    }
                    .disabled(autoCandidates.isEmpty)
                }
            }

            builderStep(number: 4, title: "주기적으로 스스로 바꾸기") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("자동 리밸런싱", isOn: Binding(
                        get: { session.autoRebalanceSettings.isEnabled },
                        set: { value in
                            session.autoRebalanceSettings.isEnabled = value
                            session.saveAppState()
                            if value {
                                session.setAutomationEnabled(true)
                                Task {
                                    await session.runAutoRebalanceNow()
                                }
                            }
                        }
                    ))

                    Text("켜두면 앱이 정해진 주기마다 후보군의 거래대금과 최근 분봉을 다시 보고, 자동선택으로 만든 매크로만 갱신·추가·비활성화합니다. 직접 만든 매크로는 건드리지 않습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: 12) {
                        easyNumberField("자동 예산", value: Binding(
                            get: { session.autoRebalanceSettings.budget },
                            set: { value in
                                session.autoRebalanceSettings.budget = value
                                session.saveAppState()
                            }
                        ), suffix: "원")

                        Stepper("나눌 종목 \(session.autoRebalanceSettings.pickCount)개", value: Binding(
                            get: { session.autoRebalanceSettings.pickCount },
                            set: { value in
                                session.autoRebalanceSettings.pickCount = max(1, min(value, 8))
                                session.saveAppState()
                            }
                        ), in: 1...8)

                        Stepper("훑을 후보 \(session.autoRebalanceSettings.scanLimit)개", value: Binding(
                            get: { session.autoRebalanceSettings.scanLimit },
                            set: { value in
                                session.autoRebalanceSettings.scanLimit = max(1, min(value, 20))
                                session.saveAppState()
                            }
                        ), in: 1...20)
                    }

                    HStack(spacing: 12) {
                        Stepper("주기 \(session.autoRebalanceSettings.intervalMinutes)분", value: Binding(
                            get: { session.autoRebalanceSettings.intervalMinutes },
                            set: { value in
                                session.autoRebalanceSettings.intervalMinutes = max(1, min(value, 240))
                                session.saveAppState()
                            }
                        ), in: 1...240)

                        Picker("시장", selection: Binding(
                            get: { session.autoRebalanceSettings.scope },
                            set: { value in
                                session.autoRebalanceSettings.scope = value
                                session.saveAppState()
                            }
                        )) {
                            ForEach(MarketScope.allCases) { scope in
                                Text(scope.title).tag(scope)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)

                        Picker("실행", selection: Binding(
                            get: { session.autoRebalanceSettings.operationMode },
                            set: { value in
                                session.autoRebalanceSettings.operationMode = value
                                session.saveAppState()
                            }
                        )) {
                            Text("완전 자동").tag(OperationMode.autoOrder)
                            Text("승인 후 주문").tag(OperationMode.confirmBeforeOrder)
                            Text("알림만").tag(OperationMode.alertOnly)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 300)
                    }

                    HStack(spacing: 10) {
                        Button {
                            Task {
                                await session.runAutoRebalanceNow()
                            }
                        } label: {
                            Label(session.isAutoRebalancing ? "리밸런싱 중" : "지금 리밸런싱", systemImage: "arrow.triangle.2.circlepath")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(session.isAutoRebalancing)

                        if session.isAutoRebalancing {
                            ProgressView()
                                .controlSize(.small)
                        }

                        Text(autoRebalanceStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var autoRebalanceStatusText: String {
        if let date = session.autoRebalanceSettings.lastRebalancedAt {
            return "\(session.lastAutoRebalanceMessage) · 최근 \(date.formatted(date: .omitted, time: .shortened))"
        }
        return session.lastAutoRebalanceMessage
    }

    private var mechanicalBuilder: some View {
        let preview = mechanicalPreviewData
        return VStack(alignment: .leading, spacing: 18) {
            Text("GitHub 인기 백테스트 프로젝트에서 자주 보이는 지표 패턴을 앱 안에서 보수적으로 검산해 매크로를 만듭니다.")
                .font(.callout)
                .foregroundStyle(.secondary)

            builderStep(number: 1, title: "종목 선택") {
                StockSearchField(text: $symbolDraft, placeholder: "예: 엔비디아, 삼성전자, 애플", width: 340, showsSelectedName: true) { symbol in
                    selectPreviewSymbol(symbol)
                }
            }

            builderStep(number: 2, title: "공식 선택") {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210), spacing: 10)], spacing: 10) {
                    ForEach(MechanicalStrategyTemplate.allCases) { template in
                        Button {
                            selectedMechanicalTemplate = template
                        } label: {
                            MechanicalTemplateCard(
                                template: template,
                                isSelected: selectedMechanicalTemplate == template
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                MechanicalRankingPanel(
                    rankings: preview.rankings,
                    selectedTemplate: selectedMechanicalTemplate
                ) { template in
                    selectedMechanicalTemplate = template
                }
            }

            builderStep(number: 3, title: "숫자 조절") {
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 12) {
                        mechanicalParameterControls

                        HStack(spacing: 10) {
                            easyNumberField("금액", value: $buyAmount, suffix: "원")
                            easyNumberField("손절", value: $stopLossPercent, suffix: "%")
                            easyNumberField("익절", value: $takeProfitPercent, suffix: "%")
                            Stepper("쉬는 시간 \(cooldownMinutes)분", value: $cooldownMinutes, in: 1...240)
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                                .help("같은 공식 신호가 반복으로 나올 때 바로 또 주문하지 않고 쉬는 시간입니다.")
                        }

                        Picker("실행 방식", selection: $selectedMode) {
                            ForEach(SimpleMacroMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 360)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    MechanicalAITuningPanel(
                        engine: $reviewEngine,
                        payloadMode: $aiChartPayloadMode,
                        isRunning: isMechanicalAITuning,
                        suggestion: mechanicalAITuningSuggestion,
                        output: mechanicalAITuningOutput,
                        errorMessage: mechanicalAITuningError,
                        onRun: {
                            Task {
                                await runMechanicalAITuning()
                            }
                        },
                        onApply: applyMechanicalAITuningSuggestion
                    )
                    .frame(width: 390)
                }
            }

            builderStep(number: 4, title: "공식 미리보기") {
                BacktestDataStatus(
                    symbolText: session.stockDisplayText(for: session.selectedSymbol),
                    timeframeText: session.chartTimeframe.title,
                    candleCount: preview.candles.count,
                    isRefreshing: isPreviewRefreshing
                ) {
                    Task { await refreshPreviewCandles() }
                }
                SimpleBacktestPreview(
                    summary: preview.summary,
                    templateTitle: selectedMechanicalTemplate.title,
                    note: selectedMechanicalTemplate.formula,
                    candles: preview.candles,
                    signalIndexes: preview.signalIndexes,
                    exitSignalIndexes: preview.exitSignalIndexes,
                    tradeAmount: buyAmount,
                    stopLossPercent: stopLossPercent,
                    takeProfitPercent: takeProfitPercent
                )
                SimpleExecutionGuard(mode: selectedMode, allowLiveOrders: session.safetySettings.allowLiveOrders)

                HStack(spacing: 10) {
                    Button {
                        createMechanicalMacro(startNow: false)
                    } label: {
                        Label("공식 매크로 만들기", systemImage: "function")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        createMechanicalMacro(startNow: true)
                    } label: {
                        Label("만들고 감시 시작", systemImage: "play.circle")
                    }

                    Button {
                        reviewMechanicalMacro()
                    } label: {
                        Label("AI에게 공식 점검", systemImage: "brain.head.profile")
                    }
                }
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var aiBuilder: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("AI에게 말로 설명하면 앱이 조건 초안을 만들고 위험을 검토합니다.")
                .font(.callout)
                .foregroundStyle(.secondary)

            builderStep(number: 1, title: "AI에게 원하는 전략 말하기") {
                TextEditor(text: $aiStrategyInput)
                    .font(.callout)
                    .lineSpacing(4)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25))
                    )
            }

            builderStep(number: 2, title: "AI로 초안 만들기") {
                HStack(spacing: 10) {
                    Picker("AI", selection: $reviewEngine) {
                        ForEach(AIEngineKind.allCases) { engine in
                            Text(engine.displayName).tag(engine)
                        }
                    }
                    .frame(width: 180)

                    Button {
                        Task {
                            await session.buildStrategyFromNaturalLanguage(input: aiStrategyInput, engine: reviewEngine)
                        }
                    } label: {
                        Label("AI 초안 만들기", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var simpleBuilder: some View {
        let preview = simplePreviewData
        return VStack(alignment: .leading, spacing: 18) {
            Text("종목 하나 고르고, 언제 사고팔지 간단히 정하면 됩니다.")
                .font(.callout)
                .foregroundStyle(.secondary)

            builderStep(number: 1, title: "어떤 종목을 볼까요?") {
                StockSearchField(text: $symbolDraft, placeholder: "예: 엔비디아, 삼성전자, 애플", width: 340, showsSelectedName: true) { symbol in
                    selectPreviewSymbol(symbol)
                }
            }

            builderStep(number: 2, title: "무엇을 해볼까요?") {
                HStack(spacing: 10) {
                    ForEach(SimpleMacroTemplate.allCases) { template in
                        Button {
                            selectedTemplate = template
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(template.title)
                                    .font(.headline)
                                Text(template.detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, minHeight: 86, alignment: .leading)
                            .padding(12)
                            .background(selectedTemplate == template ? Color.accentColor.opacity(0.13) : Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedTemplate == template ? Color.accentColor.opacity(0.7) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            builderStep(number: 3, title: "얼마나 조심스럽게 할까요?") {
                Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 12) {
                    GridRow {
                        easyNumberField("내려오면", value: $triggerPercent, suffix: "%")
                        easyNumberField("금액", value: $buyAmount, suffix: "원")
                        easyNumberField("손절", value: $stopLossPercent, suffix: "%")
                        easyNumberField("익절", value: $takeProfitPercent, suffix: "%")
                    }
                }

                HStack(spacing: 10) {
                    Stepper("쉬는 시간 \(cooldownMinutes)분", value: $cooldownMinutes, in: 1...240)
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                        .help("쿨다운은 같은 조건이 반복으로 걸렸을 때 바로 또 주문하지 않고 쉬는 시간입니다. 예: 10분이면 한 번 신호가 난 뒤 10분 동안 같은 매크로가 다시 실행되지 않습니다.")
                    Spacer()
                }

                Picker("실행 방식", selection: $selectedMode) {
                    ForEach(SimpleMacroMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 360)
            }

            builderStep(number: 4, title: "시작하기") {
                BacktestDataStatus(
                    symbolText: session.stockDisplayText(for: session.selectedSymbol),
                    timeframeText: session.chartTimeframe.title,
                    candleCount: preview.candles.count,
                    isRefreshing: isPreviewRefreshing
                ) {
                    Task { await refreshPreviewCandles() }
                }
                SimpleBacktestPreview(
                    summary: preview.summary,
                    template: selectedTemplate,
                    candles: preview.candles,
                    signalIndexes: preview.signalIndexes,
                    tradeAmount: buyAmount,
                    stopLossPercent: stopLossPercent,
                    takeProfitPercent: takeProfitPercent
                )
                SimpleExecutionGuard(mode: selectedMode, allowLiveOrders: session.safetySettings.allowLiveOrders)

                HStack(spacing: 10) {
                    Button {
                        createSimpleMacro(startNow: false)
                    } label: {
                        Label("매크로 만들기", systemImage: "plus.circle")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        createSimpleMacro(startNow: true)
                    } label: {
                        Label("만들고 감시 시작", systemImage: "play.circle")
                    }

                    Button {
                        reviewSimpleMacro()
                    } label: {
                        Label("AI에게 물어보기", systemImage: "brain.head.profile")
                    }
                }
            }
        }
        .padding(18)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var myMacros: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("내 매크로", systemImage: "list.bullet.rectangle")
                    .font(.headline)
                Spacer()
                Text("\(session.strategies.count)개")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if session.strategies.isEmpty {
                Text("아직 만든 매크로가 없습니다.")
                    .foregroundStyle(.secondary)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach($session.strategies) { $strategy in
                    SimpleMacroCard(strategy: $strategy) {
                        session.strategies.removeAll { $0.id == strategy.id }
                        session.saveAppState()
                    } onChanged: {
                        session.saveAppState()
                    }
                }
            }
        }
    }

    private var mechanicalParameterControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            switch selectedMechanicalTemplate {
            case .movingAverageCross:
                HStack(spacing: 12) {
                    easyNumberField("짧은 평균", value: $shortPeriod, suffix: "봉")
                    easyNumberField("긴 평균", value: $longPeriod, suffix: "봉")
                }
            case .rsiRebound:
                HStack(spacing: 12) {
                    easyNumberField("RSI 기간", value: $rsiPeriod, suffix: "봉")
                    easyNumberField("과매도", value: $rsiLevel, suffix: "이하")
                }
            case .bollingerRebound:
                HStack(spacing: 12) {
                    easyNumberField("평균 기간", value: $bandPeriod, suffix: "봉")
                    easyNumberField("폭", value: $bandStdDev, suffix: "배")
                }
            case .breakout:
                HStack(spacing: 12) {
                    easyNumberField("돌파 기준", value: $breakoutLookback, suffix: "봉")
                    Text("최근 \(formattedDouble(breakoutLookback, fractionDigits: 0))봉의 고점을 종가가 넘으면 신호로 봅니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .macdCross:
                Text("기본값 12 / 26 / 9를 사용합니다. 초보자용으로 숫자는 숨겨두었습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .surgeVolumeMomentum:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        easyNumberField("급등 기준", value: $triggerPercent, suffix: "%")
                        easyNumberField("거래 강도", value: $volumeMultiplier, suffix: "배")
                        easyNumberField("평균 기간", value: $breakoutLookback, suffix: "봉")
                    }
                    Text("예: 2.5% 이상 오르면서 거래량이 평소보다 1.8배 이상 붙으면 봅니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .plungeRebound:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        easyNumberField("급락 기준", value: $triggerPercent, suffix: "%")
                        easyNumberField("확인 기간", value: $breakoutLookback, suffix: "봉")
                    }
                    Text("급락한 바로 다음 봉에서 반등이 나올 때만 봅니다. 바로 추격하지 않기 위한 룰입니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .tradeValueFocus:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        easyNumberField("거래대금 강도", value: $volumeMultiplier, suffix: "배")
                        easyNumberField("평균 기간", value: $breakoutLookback, suffix: "봉")
                    }
                    Text("거래량이 아니라 가격까지 곱한 거래대금이 평소보다 커졌는지 봅니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .fixedGridTrading:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        easyNumberField("가격 간격", value: $triggerPercent, suffix: "%")
                    }
                    Text("기준가보다 아래에서 \(formattedDouble(triggerPercent, fractionDigits: 1))% 간격을 한 칸 더 내려가면 분할매수, 기준가보다 위에서 한 칸 더 올라가면 분할매도 후보를 만듭니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .bollingerBandChannel:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        easyNumberField("평균 기간", value: $bandPeriod, suffix: "봉")
                        easyNumberField("밴드 폭", value: $bandStdDev, suffix: "배")
                    }
                    Text("하단 밴드 터치는 매수 후보, 상단 밴드 터치는 매도 후보입니다. 횡보장에서 더 잘 맞습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .rsiBandChannel:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        easyNumberField("RSI 기간", value: $rsiPeriod, suffix: "봉")
                        easyNumberField("과매도", value: $rsiLevel, suffix: "이하")
                    }
                    Text("RSI \(formattedDouble(rsiLevel, fractionDigits: 0)) 이하는 매수 후보, \(formattedDouble(100 - rsiLevel, fractionDigits: 0)) 이상은 매도 후보입니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .meanReversionCombo:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        easyNumberField("밴드 기간", value: $bandPeriod, suffix: "봉")
                        easyNumberField("밴드 폭", value: $bandStdDev, suffix: "배")
                        easyNumberField("RSI 과매도", value: $rsiLevel, suffix: "이하")
                    }
                    Text("볼린저 하단과 RSI 과매도를 같이 확인해서 단독 지표보다 신호를 줄입니다. 상단 밴드나 과매수에서 매도 후보를 만듭니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .marketMakingLite:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        easyNumberField("스프레드", value: $triggerPercent, suffix: "%")
                        easyNumberField("중심 기간", value: $breakoutLookback, suffix: "봉")
                    }
                    Text("최근 평균가격 아래 \(formattedDouble(triggerPercent, fractionDigits: 1))%는 매수 후보, 위 \(formattedDouble(triggerPercent, fractionDigits: 1))%는 매도 후보입니다. 실제 호가 제출은 안전 설정 안에서만 동작합니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .koquantMinuteMomentum:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        easyNumberField("평균 기간", value: $breakoutLookback, suffix: "봉")
                        easyNumberField("거래대금 강도", value: $volumeMultiplier, suffix: "배")

                        Button {
                            breakoutLookback = 20
                            volumeMultiplier = 2
                            stopLossPercent = -1
                            takeProfitPercent = 1.5
                            cooldownMinutes = 1
                        } label: {
                            Label("KOQUANT 기본값", systemImage: "slider.horizontal.below.rectangle")
                        }
                    }

                    Text("최근 \(formattedDouble(breakoutLookback, fractionDigits: 0))봉 평균 거래대금보다 \(formattedDouble(volumeMultiplier, fractionDigits: 1))배 이상 커지고, 종가가 VWAP 위에 있을 때만 봅니다. VWAP은 그 구간의 평균 체결가에 가까운 기준선입니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .rangeSwingRebound:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        easyNumberField("왕복 폭", value: $triggerPercent, suffix: "%")
                        easyNumberField("박스 확인", value: $breakoutLookback, suffix: "봉")
                    }
                    Text("2~3%씩 왔다갔다 하는 구간의 아래쪽에서 반등할 때만 봅니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .rangeUpperWarning:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        easyNumberField("왕복 폭", value: $triggerPercent, suffix: "%")
                        easyNumberField("박스 확인", value: $breakoutLookback, suffix: "봉")
                    }
                    Text("박스권 위쪽에 닿으면 추격매수 주의 알림으로만 쓰는 걸 권장합니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .semiconductorValueBreakout:
                HStack(spacing: 12) {
                    easyNumberField("돌파 기준", value: $breakoutLookback, suffix: "봉")
                    Text("최근 고점을 넘고 거래량이 평소보다 1.5배 이상 붙는지 봅니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .semiconductorDipStabilize:
                HStack(spacing: 12) {
                    easyNumberField("급락 확인", value: $breakoutLookback, suffix: "봉")
                    Text("짧게 크게 빠진 뒤 첫 반등이 나오는지 확인합니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .semiconductorTrendRestart:
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        easyNumberField("짧은 추세", value: $shortPeriod, suffix: "봉")
                        easyNumberField("긴 추세", value: $longPeriod, suffix: "봉")
                        easyNumberField("저항 확인", value: $breakoutLookback, suffix: "봉")
                    }
                    Text("짧은 추세가 긴 추세보다 강하고, 최근 저항을 다시 넘을 때만 봅니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(selectedMechanicalTemplate.formula)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func builderStep<Content: View>(number: Int, title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("\(number)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 22, height: 22)
                    .background(Color.accentColor, in: Circle())
                Text(title)
                    .font(.headline)
            }
            content()
        }
    }

    private func easyNumberField(_ title: String, value: Binding<Double>, suffix: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(spacing: 4) {
                TextField(title, value: value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 110)
                Text(suffix)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func selectPreviewSymbol(_ symbol: String) {
        symbolDraft = session.stockDisplayText(for: symbol)
        session.selectedSymbol = symbol
        Task {
            await refreshPreviewCandles()
        }
    }

    private func prepareMacroPreview() {
        guard session.chartTimeframe != .oneMinuteExtended else {
            return
        }
        session.chartTimeframe = .oneMinuteExtended
        Task {
            await refreshPreviewCandles()
        }
    }

    private func refreshPreviewCandles() async {
        isPreviewRefreshing = true
        await session.refreshMarketData()
        isPreviewRefreshing = false
    }

    private func aggregatePreviewCandles(_ candles: [Candle], by component: Calendar.Component) -> [Candle] {
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

    private func createSimpleMacro(startNow: Bool) {
        let symbol = session.resolveSymbol(from: symbolDraft)
        let name = session.stockName(for: symbol) ?? symbol
        let referencePrice = NSDecimalNumber(decimal: session.prices.first {
            $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame
        }?.lastPriceValue ?? 0).doubleValue

        let conditions = simpleConditions()
        let strategy = TradingStrategy(
            name: "\(name) \(selectedTemplate.title)",
            symbol: symbol,
            isEnabled: startNow,
            mode: selectedMode.operationMode,
            referencePrice: referencePrice,
            maxDailyAmount: buyAmount,
            stopLossPercent: stopLossPercent,
            takeProfitPercent: takeProfitPercent,
            cooldownMinutes: cooldownMinutes,
            conditions: conditions,
            createdAt: Date(),
            updatedAt: Date(),
            riskNotes: "쉬운 매크로에서 생성"
        )
        session.strategies.insert(strategy, at: 0)
        session.selectedSymbol = symbol
        session.saveAppState()
        if startNow {
            session.setAutomationEnabled(true)
        }
    }

    private func createMechanicalMacro(startNow: Bool) {
        let symbol = session.resolveSymbol(from: symbolDraft)
        let name = session.stockName(for: symbol) ?? symbol
        let referencePrice = NSDecimalNumber(decimal: session.prices.first {
            $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame
        }?.lastPriceValue ?? 0).doubleValue

        let strategy = TradingStrategy(
            name: "\(name) \(selectedMechanicalTemplate.title)",
            symbol: symbol,
            isEnabled: startNow,
            mode: selectedMode.operationMode,
            referencePrice: referencePrice,
            maxDailyAmount: buyAmount,
            stopLossPercent: stopLossPercent,
            takeProfitPercent: takeProfitPercent,
            cooldownMinutes: cooldownMinutes,
            conditions: mechanicalConditions(template: selectedMechanicalTemplate, amount: buyAmount, referencePrice: referencePrice),
            createdAt: Date(),
            updatedAt: Date(),
            riskNotes: "기계적 매매 공식: \(selectedMechanicalTemplate.title). \(selectedMechanicalTemplate.formula)"
        )

        session.strategies.insert(strategy, at: 0)
        session.selectedSymbol = symbol
        session.saveAppState()
        if startNow {
            session.setAutomationEnabled(true)
        }
    }

    @MainActor
    private func runAutoAllocationScan() async {
        guard !isAutoScanning else {
            return
        }
        isAutoScanning = true
        autoScanError = nil
        autoCandidates = []
        defer { isAutoScanning = false }

        let picks = max(1, Int(autoPickCount.rounded()))
        let scanLimit = max(picks, Int(autoScanLimit.rounded()))
        let perPositionBudget = max(0, autoAllocationBudget) / Double(picks)
        let candidates = await session.scanAutoAllocationCandidates(
            budgetPerPosition: perPositionBudget,
            scope: autoScope,
            maxSymbols: scanLimit,
            maxResults: picks
        )

        autoCandidates = candidates
        if candidates.isEmpty {
            autoScanError = session.marketActivityAutomationBlockReason(scope: autoScope)
                ?? "조건에 맞는 후보를 찾지 못했습니다. 후보 종목 랭킹을 새로고침하거나 후보 수를 늘려보세요."
        }
    }

    private func createAutoAllocationMacros(startNow: Bool) {
        let picks = Array(autoCandidates.prefix(max(1, Int(autoPickCount.rounded()))))
        guard !picks.isEmpty else {
            autoScanError = "먼저 후보를 찾아주세요."
            return
        }

        for candidate in picks.reversed() {
            let referencePrice = NSDecimalNumber(decimal: decimalValue(candidate.lastPrice)).doubleValue
            let orderAmount = autoPickOrderAmount(for: candidate, referencePrice: referencePrice)
            let requestedMode = selectedMode.operationMode
            let effectiveMode: OperationMode = requestedMode == .autoOrder && !candidate.allowsAutoOrder
                ? .confirmBeforeOrder
                : requestedMode
            let strategy = TradingStrategy(
                name: "\(candidate.name) 자동 선택 \(candidate.template.title)",
                symbol: candidate.symbol,
                isEnabled: startNow,
                mode: effectiveMode,
                referencePrice: referencePrice,
                maxDailyAmount: orderAmount,
                stopLossPercent: stopLossPercent,
                takeProfitPercent: takeProfitPercent,
                cooldownMinutes: cooldownMinutes,
                conditions: orderAmount > 0 ? mechanicalConditions(
                    template: candidate.template,
                    amount: orderAmount,
                    referencePrice: referencePrice
                ) : [],
                createdAt: Date(),
                updatedAt: Date(),
                riskNotes: "자동 종목 선택: 점수 \(formattedDouble(candidate.trendScore, fractionDigits: 0))점. \(candidate.reason) \(candidate.berkshireGuardText) 계좌 반영 주문예산 \(formattedDouble(orderAmount, fractionDigits: 0))원. 실행 모드: \(effectiveMode.title)\(effectiveMode != requestedMode ? " (Berkshire Guard 때문에 자동주문에서 낮춤)" : "")."
            )
            session.strategies.insert(strategy, at: 0)
        }

        session.saveAppState()
        if selectedMode.operationMode == .autoOrder, picks.contains(where: { !$0.allowsAutoOrder }) {
            autoScanError = "Berkshire Guard가 통과하지 않은 후보는 승인 후 주문으로 낮췄습니다."
        }
        if startNow {
            session.setAutomationEnabled(true)
        }
    }

    private func autoPickOrderAmount(for candidate: AutoAllocationCandidate, referencePrice: Double) -> Double {
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

    private func holdingValue(for symbol: String) -> Double {
        session.holdings
            .filter { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
            .reduce(0.0) { total, holding in
                total + NSDecimalNumber(decimal: decimalValue(holding.value)).doubleValue
            }
    }

    private func mechanicalAction() -> StrategyAction {
        if selectedMechanicalTemplate == .rangeUpperWarning {
            return .notify
        }
        return selectedMode == .alert ? .notify : .buy
    }

    private func mechanicalConditions(referencePrice: Double) -> [StrategyCondition] {
        mechanicalConditions(template: selectedMechanicalTemplate, amount: buyAmount, referencePrice: referencePrice)
    }

    private func mechanicalAction(for template: MechanicalStrategyTemplate) -> StrategyAction {
        if template == .rangeUpperWarning {
            return .notify
        }
        return selectedMode == .alert ? .notify : .buy
    }

    private func mechanicalConditions(template: MechanicalStrategyTemplate, amount: Double, referencePrice: Double) -> [StrategyCondition] {
        if template.isTwoSided {
            return [
                StrategyCondition(
                    metric: .priceAbove,
                    threshold: 0,
                    action: selectedMode == .alert ? .notify : .buy,
                    amount: amount,
                    quantity: 0,
                    orderType: .limit,
                    note: mechanicalNote(template: template, side: .buy, referencePrice: referencePrice)
                ),
                StrategyCondition(
                    metric: .priceAbove,
                    threshold: 0,
                    action: selectedMode == .alert ? .notify : .sell,
                    amount: amount,
                    quantity: 0,
                    orderType: .limit,
                    note: mechanicalNote(template: template, side: .sell, referencePrice: referencePrice)
                )
            ]
        }

        return [
            StrategyCondition(
                metric: .priceAbove,
                threshold: 0,
                action: mechanicalAction(for: template),
                amount: amount,
                quantity: 0,
                orderType: .limit,
                note: mechanicalNote(template: template, side: .buy, referencePrice: referencePrice)
            )
        ]
    }

    private func simpleConditions() -> [StrategyCondition] {
        switch selectedTemplate {
        case .buyDip:
            [
                StrategyCondition(
                    metric: .dropPercent,
                    threshold: triggerPercent,
                    action: selectedMode == .alert ? .notify : .buy,
                    amount: buyAmount,
                    quantity: 0,
                    orderType: .limit,
                    note: "\(formattedDouble(triggerPercent, fractionDigits: 1))% 내려오면 확인"
                )
            ]
        case .watchExit:
            [
                StrategyCondition(metric: .profitRateBelow, threshold: stopLossPercent, action: .notify, amount: 0, quantity: 0, orderType: .limit, note: "손절 구간 알림"),
                StrategyCondition(metric: .profitRateAbove, threshold: takeProfitPercent, action: .notify, amount: 0, quantity: 0, orderType: .limit, note: "익절 구간 알림")
            ]
        case .priceAlert:
            [
                StrategyCondition(metric: .gainPercent, threshold: triggerPercent, action: .notify, amount: 0, quantity: 0, orderType: .limit, note: "\(formattedDouble(triggerPercent, fractionDigits: 1))% 움직이면 알림")
            ]
        }
    }

    private func reviewSimpleMacro() {
        let symbol = session.resolveSymbol(from: symbolDraft)
        let prompt = """
        \(symbol) 초보자용 단기 매크로를 검토해줘.
        방식: \(selectedTemplate.title)
        실행 방식: \(selectedMode.title)
        기준 움직임: \(triggerPercent)%
        금액: \(buyAmount)원
        손절: \(stopLossPercent)%
        익절: \(takeProfitPercent)%
        쉬는 시간: \(cooldownMinutes)분

        초보자가 이해할 수 있게 위험한 점, 더 안전한 설정, 시작 전 확인할 것을 짧게 말해줘.
        """
        Task {
            await session.runAIAnalysis(engine: reviewEngine, symbol: symbol, prompt: prompt)
        }
    }

    private func reviewMechanicalMacro() {
        let symbol = session.resolveSymbol(from: symbolDraft)
        let prompt = """
        \(symbol) 기계적 매매 공식을 검토해줘.
        공식: \(selectedMechanicalTemplate.title)
        설명: \(selectedMechanicalTemplate.formula)
        파라미터: \(mechanicalNote())
        실행 방식: \(selectedMode.title)
        금액: \(formattedDouble(buyAmount, fractionDigits: 0))원
        손절: \(formattedDouble(stopLossPercent, fractionDigits: 1))%
        익절: \(formattedDouble(takeProfitPercent, fractionDigits: 1))%
        쉬는 시간: \(cooldownMinutes)분

        초보자가 이해할 수 있게 이 공식이 언제 강하고 언제 위험한지, 추천 보완 조건을 짧게 정리해줘.
        """
        Task {
            await session.runAIAnalysis(engine: reviewEngine, symbol: symbol, prompt: prompt)
        }
    }

    @MainActor
    private func runMechanicalAITuning() async {
        guard !isMechanicalAITuning else {
            return
        }

        isMechanicalAITuning = true
        mechanicalAITuningSuggestion = nil
        mechanicalAITuningError = nil
        mechanicalAITuningOutput = ""
        defer { isMechanicalAITuning = false }

        let symbol = session.resolveSymbol(from: symbolDraft)
        session.selectedSymbol = symbol
        if previewCandles.count < 30 {
            await refreshPreviewCandles()
        }

        let preview = mechanicalPreviewData
        let prompt = mechanicalAITuningPrompt(symbol: symbol, preview: preview)
        guard let result = await session.runAIAnalysis(
            engine: reviewEngine,
            symbol: symbol,
            prompt: prompt,
            wrapForReport: false
        ) else {
            mechanicalAITuningError = "AI 실행 결과를 받지 못했습니다."
            return
        }

        mechanicalAITuningOutput = result.output
        if let suggestion = parseMechanicalAITuningSuggestion(from: result.output) {
            mechanicalAITuningSuggestion = suggestion
        } else {
            mechanicalAITuningError = "추천값 JSON을 찾지 못했습니다. 아래 원문을 확인하세요."
        }
    }

    private func applyMechanicalAITuningSuggestion() {
        guard let suggestion = mechanicalAITuningSuggestion else {
            return
        }

        if let templateRaw = suggestion.template,
           let template = MechanicalStrategyTemplate(rawValue: templateRaw) {
            selectedMechanicalTemplate = template
        }
        if let value = suggestion.triggerPercent {
            triggerPercent = clamped(value, min: 0.1, max: 30)
        }
        if let value = suggestion.shortPeriod {
            shortPeriod = clamped(value.rounded(), min: 2, max: 120)
        }
        if let value = suggestion.longPeriod {
            longPeriod = clamped(value.rounded(), min: 3, max: 240)
        }
        if longPeriod <= shortPeriod {
            longPeriod = min(240, shortPeriod + 1)
        }
        if let value = suggestion.rsiPeriod {
            rsiPeriod = clamped(value.rounded(), min: 2, max: 80)
        }
        if let value = suggestion.rsiLevel {
            rsiLevel = clamped(value, min: 5, max: 45)
        }
        if let value = suggestion.bandPeriod {
            bandPeriod = clamped(value.rounded(), min: 3, max: 120)
        }
        if let value = suggestion.bandStdDev {
            bandStdDev = clamped(value, min: 0.5, max: 4)
        }
        if let value = suggestion.breakoutLookback {
            breakoutLookback = clamped(value.rounded(), min: 2, max: 240)
        }
        if let value = suggestion.volumeMultiplier {
            volumeMultiplier = clamped(value, min: 0.5, max: 10)
        }
        if let value = suggestion.stopLossPercent {
            stopLossPercent = -abs(clamped(value, min: -30, max: 30))
        }
        if let value = suggestion.takeProfitPercent {
            takeProfitPercent = abs(clamped(value, min: -50, max: 50))
        }
        if let value = suggestion.buyAmount {
            buyAmount = clamped(value, min: 0, max: 1_000_000_000)
        }
        if let value = suggestion.cooldownMinutes {
            cooldownMinutes = Int(clamped(value.rounded(), min: 1, max: 240))
        }
    }

    private func mechanicalAITuningPrompt(symbol: String, preview: MechanicalPreviewData) -> String {
        let candles = preview.candles
        let selectedRows = Array(candles.suffix(aiChartPayloadMode.candleLimit))
        return """
        당신은 주식 자동매매 전략을 튜닝하는 보조 분석가입니다.
        투자 수익을 보장하거나 확정적인 매수/매도 지시를 하지 마세요.
        아래 데이터만 보고 현재 기계적 매매 공식의 숫자 파라미터를 더 보수적으로 제안하세요.

        종목: \(symbol)
        차트 기준: \(session.chartTimeframe.title)
        차트 데이터 모드: \(aiChartPayloadMode.title)
        전달 캔들 수: \(selectedRows.count) / 전체 \(candles.count)

        현재 공식:
        template rawValue: \(selectedMechanicalTemplate.rawValue)
        title: \(selectedMechanicalTemplate.title)
        formula: \(selectedMechanicalTemplate.formula)
        note: \(mechanicalNote())

        현재 파라미터:
        triggerPercent=\(triggerPercent)
        shortPeriod=\(shortPeriod)
        longPeriod=\(longPeriod)
        rsiPeriod=\(rsiPeriod)
        rsiLevel=\(rsiLevel)
        bandPeriod=\(bandPeriod)
        bandStdDev=\(bandStdDev)
        breakoutLookback=\(breakoutLookback)
        volumeMultiplier=\(volumeMultiplier)
        stopLossPercent=\(stopLossPercent)
        takeProfitPercent=\(takeProfitPercent)
        buyAmount=\(buyAmount)
        cooldownMinutes=\(cooldownMinutes)

        현재 백테스트:
        trades=\(preview.summary.signalCount)
        winRate=\(formattedDouble(preview.summary.winRate, fractionDigits: 2))%
        averageReturn=\(formattedDouble(preview.summary.averageReturn, fractionDigits: 2))%
        worstReturn=\(formattedDouble(preview.summary.worstReturn, fractionDigits: 2))%
        estimatedPnL=\(formattedDouble(preview.summary.estimatedPnL, fractionDigits: 0))

        공식별 최근 순위:
        \(preview.rankings.prefix(8).map { "- \($0.template.rawValue): 거래 \($0.summary.signalCount), 승률 \(formattedDouble($0.summary.winRate, fractionDigits: 1))%, 평균 \(formattedDouble($0.summary.averageReturn, fractionDigits: 2))%, 예상손익 \(formattedDouble($0.summary.estimatedPnL, fractionDigits: 0))" }.joined(separator: "\n"))

        차트 요약:
        \(mechanicalAIChartSummary(candles: candles))

        차트 데이터 CSV:
        index,timestamp,open,high,low,close,volume
        \(selectedRows.enumerated().map { index, candle in "\(index),\(candle.timestamp),\(candle.openPrice),\(candle.highPrice),\(candle.lowPrice),\(candle.closePrice),\(candle.volume)" }.joined(separator: "\n"))

        출력 규칙:
        설명은 짧게 쓰고, 반드시 아래 JSON 블록 하나를 포함하세요.
        template은 바꿀 필요가 없으면 현재 rawValue를 그대로 쓰세요.
        사용하지 않는 값은 null로 두세요.

        ```json
        {
          "template": "\(selectedMechanicalTemplate.rawValue)",
          "triggerPercent": null,
          "shortPeriod": null,
          "longPeriod": null,
          "rsiPeriod": null,
          "rsiLevel": null,
          "bandPeriod": null,
          "bandStdDev": null,
          "breakoutLookback": null,
          "volumeMultiplier": null,
          "stopLossPercent": null,
          "takeProfitPercent": null,
          "buyAmount": null,
          "cooldownMinutes": null,
          "reason": "왜 이 숫자가 더 적절한지 한두 문장",
          "riskNote": "초보자가 특히 조심할 점 한두 문장"
        }
        ```
        """
    }

    private func mechanicalAIChartSummary(candles: [Candle]) -> String {
        guard let first = candles.first, let last = candles.last else {
            return "캔들 없음"
        }
        let closes = candles.map { NSDecimalNumber(decimal: $0.closeValue).doubleValue }
        let highs = candles.map { NSDecimalNumber(decimal: $0.highValue).doubleValue }
        let lows = candles.map { NSDecimalNumber(decimal: $0.lowValue).doubleValue }
        let volumes = candles.map { NSDecimalNumber(decimal: $0.volumeValue).doubleValue }
        let firstClose = NSDecimalNumber(decimal: first.closeValue).doubleValue
        let lastClose = NSDecimalNumber(decimal: last.closeValue).doubleValue
        let move = firstClose > 0 ? ((lastClose - firstClose) / firstClose) * 100 : 0
        let averageVolume = volumes.isEmpty ? 0 : volumes.reduce(0, +) / Double(volumes.count)
        let averageClose = closes.isEmpty ? 0 : closes.reduce(0, +) / Double(closes.count)
        return """
        시작=\(first.timestamp), 끝=\(last.timestamp)
        첫 종가=\(formattedDouble(firstClose, fractionDigits: 4)), 마지막 종가=\(formattedDouble(lastClose, fractionDigits: 4)), 변화율=\(formattedDouble(move, fractionDigits: 2))%
        최고=\(formattedDouble(highs.max() ?? 0, fractionDigits: 4)), 최저=\(formattedDouble(lows.min() ?? 0, fractionDigits: 4)), 평균종가=\(formattedDouble(averageClose, fractionDigits: 4))
        평균거래량=\(formattedDouble(averageVolume, fractionDigits: 0))
        """
    }

    private func parseMechanicalAITuningSuggestion(from text: String) -> MechanicalAITuningSuggestion? {
        let decoder = JSONDecoder()
        for candidate in jsonCandidates(in: text) {
            guard let data = candidate.data(using: .utf8),
                  let suggestion = try? decoder.decode(MechanicalAITuningSuggestion.self, from: data) else {
                continue
            }
            return suggestion
        }
        return nil
    }

    private func jsonCandidates(in text: String) -> [String] {
        var candidates: [String] = []
        if let fenceStart = text.range(of: "```json") ?? text.range(of: "```JSON") {
            let afterStart = text[fenceStart.upperBound...]
            if let fenceEnd = afterStart.range(of: "```") {
                candidates.append(String(afterStart[..<fenceEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }

        if let firstBrace = text.firstIndex(of: "{"),
           let lastBrace = text.lastIndex(of: "}"),
           firstBrace <= lastBrace {
            candidates.append(String(text[firstBrace...lastBrace]))
        }
        return candidates
    }

    private func clamped(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        Swift.max(minimum, Swift.min(maximum, value))
    }

    private func simulateSimpleMacro(candles: [Candle], signalIndexes: [Int]) -> SimpleBacktestSummary {
        guard candles.count >= 3 else {
            return SimpleBacktestSummary(signalCount: 0, winCount: 0, averageReturn: 0, worstReturn: 0, estimatedPnL: 0)
        }

        return MechanicalSignalEngine.summary(
            candles: candles,
            signalIndexes: signalIndexes,
            tradeAmount: buyAmount,
            stopLossPercent: stopLossPercent,
            takeProfitPercent: takeProfitPercent
        )
    }

    private func simpleSignalIndexes(candles: [Candle]) -> [Int] {
        guard candles.count >= 3 else {
            return []
        }

        var indexes: [Int] = []
        for index in 1..<(candles.count - 1) {
            let previousClose = NSDecimalNumber(decimal: candles[index - 1].closeValue).doubleValue
            let currentClose = NSDecimalNumber(decimal: candles[index].closeValue).doubleValue
            guard previousClose > 0, currentClose > 0 else {
                continue
            }

            let move = ((currentClose - previousClose) / previousClose) * 100
            let triggered: Bool
            switch selectedTemplate {
            case .buyDip:
                triggered = move <= -triggerPercent
            case .watchExit:
                triggered = move <= stopLossPercent || move >= takeProfitPercent
            case .priceAlert:
                triggered = abs(move) >= triggerPercent
            }

            if triggered {
                indexes.append(index)
            }
        }
        return indexes
    }

    private func simulateMechanicalStrategy(candles: [Candle], signalIndexes: [Int], exitSignalIndexes: [Int]) -> SimpleBacktestSummary {
        MechanicalSignalEngine.summary(
            candles: candles,
            signalIndexes: signalIndexes,
            tradeAmount: buyAmount,
            exitSignalIndexes: exitSignalIndexes,
            stopLossPercent: stopLossPercent,
            takeProfitPercent: takeProfitPercent
        )
    }

    private func mechanicalSignalIndexes(for template: MechanicalStrategyTemplate, candles: [Candle]) -> [Int] {
        MechanicalSignalEngine.signalIndexes(
            candles: candles,
            template: template,
            shortPeriod: max(2, Int(shortPeriod)),
            longPeriod: max(3, Int(longPeriod)),
            rsiPeriod: max(2, Int(rsiPeriod)),
            rsiLevel: rsiLevel,
            bandPeriod: max(3, Int(bandPeriod)),
            bandStdDev: bandStdDev,
            breakoutLookback: max(2, Int(breakoutLookback)),
            movePercent: triggerPercent,
            volumeMultiplier: volumeMultiplier
        )
    }

    private func mechanicalExitSignalIndexes(for template: MechanicalStrategyTemplate, candles: [Candle]) -> [Int] {
        guard template.isTwoSided else {
            return []
        }
        return MechanicalSignalEngine.signalIndexes(
            candles: candles,
            template: template,
            shortPeriod: max(2, Int(shortPeriod)),
            longPeriod: max(3, Int(longPeriod)),
            rsiPeriod: max(2, Int(rsiPeriod)),
            rsiLevel: rsiLevel,
            bandPeriod: max(3, Int(bandPeriod)),
            bandStdDev: bandStdDev,
            breakoutLookback: max(2, Int(breakoutLookback)),
            movePercent: triggerPercent,
            volumeMultiplier: volumeMultiplier,
            side: .sell
        )
    }

    private func mechanicalNote(template: MechanicalStrategyTemplate? = nil, side: StrategyAction = .buy, referencePrice: Double? = nil) -> String {
        let selectedTemplate = template ?? selectedMechanicalTemplate
        let sideText = side == .sell ? "SELL" : "BUY"
        let anchor = max(0, referencePrice ?? 0)
        switch selectedTemplate {
        case .fixedGridTrading:
            let anchorPart = anchor > 0 ? ":anchor=\(formattedDouble(anchor, fractionDigits: 4))" : ""
            return "MECH:\(selectedTemplate.token):side=\(sideText):gap=\(formattedDouble(triggerPercent, fractionDigits: 2))\(anchorPart)"
        case .movingAverageCross:
            return "MECH:\(selectedTemplate.token):short=\(max(2, Int(shortPeriod))):long=\(max(3, Int(longPeriod)))"
        case .rsiRebound:
            return "MECH:\(selectedTemplate.token):period=\(max(2, Int(rsiPeriod))):level=\(formattedDouble(rsiLevel, fractionDigits: 1))"
        case .bollingerRebound:
            return "MECH:\(selectedTemplate.token):period=\(max(3, Int(bandPeriod))):std=\(formattedDouble(bandStdDev, fractionDigits: 2))"
        case .bollingerBandChannel:
            return "MECH:\(selectedTemplate.token):side=\(sideText):period=\(max(3, Int(bandPeriod))):std=\(formattedDouble(bandStdDev, fractionDigits: 2))"
        case .rsiBandChannel:
            return "MECH:\(selectedTemplate.token):side=\(sideText):period=\(max(2, Int(rsiPeriod))):oversold=\(formattedDouble(rsiLevel, fractionDigits: 1)):overbought=\(formattedDouble(100 - rsiLevel, fractionDigits: 1))"
        case .breakout:
            return "MECH:\(selectedTemplate.token):lookback=\(max(2, Int(breakoutLookback)))"
        case .macdCross:
            return "MECH:\(selectedTemplate.token):fast=12:slow=26:signal=9"
        case .surgeVolumeMomentum:
            return "MECH:\(selectedTemplate.token):move=\(formattedDouble(triggerPercent, fractionDigits: 1)):volume=\(formattedDouble(volumeMultiplier, fractionDigits: 1)):lookback=\(max(2, Int(breakoutLookback)))"
        case .plungeRebound:
            return "MECH:\(selectedTemplate.token):move=\(formattedDouble(triggerPercent, fractionDigits: 1)):volume=\(formattedDouble(volumeMultiplier, fractionDigits: 1)):lookback=\(max(3, Int(breakoutLookback)))"
        case .tradeValueFocus:
            return "MECH:\(selectedTemplate.token):value=\(formattedDouble(volumeMultiplier, fractionDigits: 1)):lookback=\(max(2, Int(breakoutLookback)))"
        case .meanReversionCombo:
            return "MECH:\(selectedTemplate.token):side=\(sideText):band=\(max(3, Int(bandPeriod))):std=\(formattedDouble(bandStdDev, fractionDigits: 2)):rsi=\(max(2, Int(rsiPeriod))):oversold=\(formattedDouble(rsiLevel, fractionDigits: 1)):overbought=\(formattedDouble(100 - rsiLevel, fractionDigits: 1))"
        case .marketMakingLite:
            return "MECH:\(selectedTemplate.token):side=\(sideText):period=\(max(5, Int(breakoutLookback))):spread=\(formattedDouble(triggerPercent, fractionDigits: 2))"
        case .koquantMinuteMomentum:
            return "MECH:\(selectedTemplate.token):lookback=\(max(2, Int(breakoutLookback))):value=\(formattedDouble(volumeMultiplier, fractionDigits: 2)):vwap=rolling"
        case .rangeSwingRebound:
            return "MECH:\(selectedTemplate.token):swing=\(formattedDouble(triggerPercent, fractionDigits: 1)):lookback=\(max(5, Int(breakoutLookback)))"
        case .rangeUpperWarning:
            return "MECH:\(selectedTemplate.token):swing=\(formattedDouble(triggerPercent, fractionDigits: 1)):lookback=\(max(5, Int(breakoutLookback)))"
        case .semiconductorValueBreakout:
            return "MECH:\(selectedTemplate.token):lookback=\(max(2, Int(breakoutLookback))):volume=1.5"
        case .semiconductorDipStabilize:
            return "MECH:\(selectedTemplate.token):lookback=\(max(3, Int(breakoutLookback)))"
        case .semiconductorTrendRestart:
            return "MECH:\(selectedTemplate.token):short=\(max(2, Int(shortPeriod))):long=\(max(3, Int(longPeriod))):lookback=\(max(5, Int(breakoutLookback)))"
        }
    }
}

struct MechanicalAITuningPanel: View {
    @Binding var engine: AIEngineKind
    @Binding var payloadMode: AIChartPayloadMode
    let isRunning: Bool
    let suggestion: MechanicalAITuningSuggestion?
    let output: String
    let errorMessage: String?
    let onRun: () -> Void
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI 추천 미리보기", systemImage: "sparkles")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Picker("엔진", selection: $engine) {
                        ForEach(AIEngineKind.allCases) { engine in
                            Text(engine.displayName).tag(engine)
                        }
                    }
                    .frame(width: 170)

                    Picker("데이터", selection: $payloadMode) {
                        ForEach(AIChartPayloadMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }

                HStack(spacing: 10) {
                    Button(action: onRun) {
                        Label(isRunning ? "분석 중" : "AI로 숫자 추천", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRunning)

                    if isRunning {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Spacer()
                }
            }

            if let suggestion {
                MechanicalAITuningSuggestionCard(suggestion: suggestion, onApply: onApply)
            } else if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "brain.head.profile")
                        .foregroundStyle(.blue)
                    Text("AI가 최근 차트, 공식별 순위, 현재 손절·익절 값을 보고 숫자 후보를 만듭니다. 전체 데이터는 느릴 수 있습니다.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !output.isEmpty {
                DisclosureGroup {
                    Text(output)
                        .font(.caption)
                        .lineSpacing(3)
                        .textSelection(.enabled)
                        .padding(.top, 6)
                } label: {
                    Label("AI 원문", systemImage: "text.quote")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct AutoAllocationCandidatePanel: View {
    let candidates: [AutoAllocationCandidate]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("자동 선택 후보", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.headline)
                Spacer()
                Text("\(candidates.count)개")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if candidates.isEmpty {
                Text("아직 후보가 없습니다. 예산과 범위를 정한 뒤 추세 좋은 종목 찾기를 눌러주세요.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(candidates.enumerated()), id: \.element.id) { index, candidate in
                        AutoAllocationCandidateRow(rank: index + 1, candidate: candidate)
                    }
                }
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct AutoAllocationCandidateRow: View {
    let rank: Int
    let candidate: AutoAllocationCandidate

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(rank)")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(scoreColor, in: Circle())

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(candidate.name)
                        .font(.headline)
                    Text(candidate.symbol)
                        .font(.caption.monospaced().weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(candidate.market)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                Text(candidate.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    tag("공식", candidate.template.title)
                    tag("가드", candidate.berkshireVerdict)
                    tag("예산", "\(formattedDouble(candidate.suggestedAmount, fractionDigits: 0))원")
                    tag("수량", candidate.expectedQuantity > 0 ? "\(formattedDouble(candidate.expectedQuantity, fractionDigits: 0))주" : "금액주문")
                    tag("예상", "\(signedMoney(candidate.expectedPnL))원")
                    tag("거래대금", candidate.tradeValueText)
                }

                Label(candidate.berkshireGuardText, systemImage: candidate.allowsAutoOrder ? "checkmark.shield" : "exclamationmark.shield")
                    .font(.caption2)
                    .foregroundStyle(guardColor)
                    .fixedSize(horizontal: false, vertical: true)

                Text(candidate.affordabilityText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(candidate.executionHint)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Text("\(formattedDouble(candidate.trendScore, fractionDigits: 0))점")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(scoreColor)
                Text("\(signed(candidate.trendPercent))%")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(candidate.trendPercent >= 0 ? .green : .red)
                Text(candidate.lastPrice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var scoreColor: Color {
        if candidate.trendScore >= 70 {
            return .green
        }
        if candidate.trendScore >= 50 {
            return .orange
        }
        return .secondary
    }

    private var guardColor: Color {
        if candidate.allowsAutoOrder {
            return .green
        }
        if candidate.berkshireVerdict == "조건부" {
            return .orange
        }
        return .red
    }

    private func tag(_ title: String, _ value: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .foregroundStyle(.secondary)
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.caption2)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.secondary.opacity(0.10), in: Capsule())
    }

    private func signed(_ value: Double) -> String {
        "\(value >= 0 ? "+" : "")\(formattedDouble(value, fractionDigits: 2))"
    }

    private func signedMoney(_ value: Double) -> String {
        "\(value >= 0 ? "+" : "")\(formattedDouble(value, fractionDigits: 0))"
    }
}

struct MechanicalAITuningSuggestionCard: View {
    let suggestion: MechanicalAITuningSuggestion
    let onApply: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("추천값", systemImage: "slider.horizontal.below.rectangle")
                    .font(.headline)
                Spacer()
                Button(action: onApply) {
                    Label("추천값 적용", systemImage: "checkmark.circle")
                }
                .buttonStyle(.borderedProminent)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 8)], spacing: 8) {
                suggestionTile("공식", suggestion.template)
                suggestionTile("간격/움직임", percentText(suggestion.triggerPercent))
                suggestionTile("짧은 평균", candleText(suggestion.shortPeriod))
                suggestionTile("긴 평균", candleText(suggestion.longPeriod))
                suggestionTile("RSI 기간", candleText(suggestion.rsiPeriod))
                suggestionTile("RSI 기준", numberText(suggestion.rsiLevel))
                suggestionTile("밴드 기간", candleText(suggestion.bandPeriod))
                suggestionTile("밴드 폭", numberText(suggestion.bandStdDev))
                suggestionTile("확인 봉", candleText(suggestion.breakoutLookback))
                suggestionTile("거래 강도", multiplierText(suggestion.volumeMultiplier))
                suggestionTile("손절", percentText(suggestion.stopLossPercent))
                suggestionTile("익절", percentText(suggestion.takeProfitPercent))
                suggestionTile("금액", moneyText(suggestion.buyAmount))
                suggestionTile("쉬는 시간", minuteText(suggestion.cooldownMinutes))
            }

            if let reason = suggestion.reason, !reason.isEmpty {
                Label(reason, systemImage: "lightbulb")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let riskNote = suggestion.riskNote, !riskNote.isEmpty {
                Label(riskNote, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func suggestionTile(_ title: String, _ value: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value ?? "-")
                .font(.caption.monospacedDigit().weight(.semibold))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 6))
    }

    private func numberText(_ value: Double?) -> String? {
        guard let value else { return nil }
        return formattedDouble(value, fractionDigits: 2)
    }

    private func percentText(_ value: Double?) -> String? {
        guard let value else { return nil }
        return "\(formattedDouble(value, fractionDigits: 2))%"
    }

    private func candleText(_ value: Double?) -> String? {
        guard let value else { return nil }
        return "\(formattedDouble(value, fractionDigits: 0))봉"
    }

    private func multiplierText(_ value: Double?) -> String? {
        guard let value else { return nil }
        return "\(formattedDouble(value, fractionDigits: 2))배"
    }

    private func moneyText(_ value: Double?) -> String? {
        guard let value else { return nil }
        return "\(formattedDouble(value, fractionDigits: 0))원"
    }

    private func minuteText(_ value: Double?) -> String? {
        guard let value else { return nil }
        return "\(formattedDouble(value, fractionDigits: 0))분"
    }
}

struct MechanicalTemplateCard: View {
    let template: MechanicalStrategyTemplate
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(template.title)
                .font(.headline)
            Text(template.formula)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Text(template.sourceNote)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 122, alignment: .leading)
        .padding(12)
        .background(isSelected ? Color.accentColor.opacity(0.13) : Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor.opacity(0.7) : Color.clear)
        )
    }
}

struct MechanicalRankingPanel: View {
    let rankings: [StrategyRankingResult]
    let selectedTemplate: MechanicalStrategyTemplate
    let onSelect: (MechanicalStrategyTemplate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("최근 분봉 수익률 순위", systemImage: "list.number")
                    .font(.headline)
                Spacer()
                Text("상위 \(min(rankings.count, 6))개")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("선택한 종목의 최근 분봉으로 모든 공식을 돌려본 순위입니다. 진입은 다음 봉 시가, 청산은 손절·익절·최대 보유 시간 기준으로 계산합니다.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                ForEach(Array(rankings.prefix(6).enumerated()), id: \.element.id) { index, item in
                    Button {
                        onSelect(item.template)
                    } label: {
                        HStack(spacing: 10) {
                            Text("\(index + 1)")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(rankColor(index), in: Circle())

                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.template.title)
                                    .font(.callout.weight(.semibold))
                                Text(item.summary.hasSignals ? "거래 \(item.summary.signalCount)번 · 승률 \(formattedDouble(item.summary.winRate, fractionDigits: 0))%" : "최근 분봉에서는 거래 없음")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 3) {
                                Text(item.summary.hasSignals ? "\(signed(item.summary.averageReturn))%" : "-")
                                    .font(.callout.monospacedDigit().weight(.semibold))
                                Text(item.summary.hasSignals ? "대략 \(signedMoney(item.summary.estimatedPnL))원" : "예상 없음")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(10)
                        .background(
                            selectedTemplate == item.template ? Color.accentColor.opacity(0.13) : Color.secondary.opacity(0.06),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedTemplate == item.template ? Color.accentColor.opacity(0.55) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(Color.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }

    private func rankColor(_ index: Int) -> Color {
        switch index {
        case 0: .green
        case 1: .blue
        case 2: .orange
        default: .secondary
        }
    }

    private func signed(_ value: Double) -> String {
        "\(value >= 0 ? "+" : "")\(formattedDouble(value, fractionDigits: 2))"
    }

    private func signedMoney(_ value: Double) -> String {
        "\(value >= 0 ? "+" : "")\(formattedDouble(value, fractionDigits: 0))"
    }
}

struct BacktestDataStatus: View {
    let symbolText: String
    let timeframeText: String
    let candleCount: Int
    let isRefreshing: Bool
    let onRefresh: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            if isRefreshing {
                ProgressView()
                    .controlSize(.small)
            } else {
                Image(systemName: "chart.xyaxis.line")
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("미리보기 기준")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(symbolText) · \(timeframeText) · 캔들 \(candleCount)개")
                    .font(.callout.weight(.medium))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: onRefresh) {
                Label("차트 새로고침", systemImage: "arrow.clockwise")
            }
            .disabled(isRefreshing)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct BacktestTradeMarker: Identifiable {
    enum Kind {
        case buy
        case sell
    }

    let id: String
    let date: Date
    let price: Double
    let kind: Kind
    let label: String
    let returnPercent: Double
}

struct BacktestTradeChart: View {
    let candles: [Candle]
    let signalIndexes: [Int]
    let exitSignalIndexes: [Int]
    let tradeAmount: Double
    let stopLossPercent: Double
    let takeProfitPercent: Double
    private let maxVisibleMinuteCandles = 1_440

    private var visibleStartIndex: Int {
        max(0, candles.count - maxVisibleMinuteCandles)
    }

    private var visibleCandles: [Candle] {
        Array(candles.suffix(maxVisibleMinuteCandles))
    }

    private var chartCandles: [Candle] {
        CandleSeriesReducer.sampledLine(visibleCandles, maxCount: 520)
    }

    private var simulatedTrades: [BacktestTrade] {
        MechanicalSignalEngine.trades(
            candles: candles,
            signalIndexes: signalIndexes,
            tradeAmount: tradeAmount,
            exitSignalIndexes: exitSignalIndexes,
            stopLossPercent: stopLossPercent,
            takeProfitPercent: takeProfitPercent
        )
    }

    private var visibleTrades: [BacktestTrade] {
        Array(simulatedTrades.filter { trade in
            trade.entryIndex >= visibleStartIndex || trade.exitIndex >= visibleStartIndex
        }.suffix(12))
    }

    private var buyMarkers: [BacktestTradeMarker] {
        visibleTrades.map { trade in
            return BacktestTradeMarker(
                id: "buy-\(trade.id)",
                date: trade.entryDate,
                price: trade.entryPrice,
                kind: .buy,
                label: "매수",
                returnPercent: trade.returnPercent
            )
        }
    }

    private var sellMarkers: [BacktestTradeMarker] {
        visibleTrades.map { trade in
            return BacktestTradeMarker(
                id: "sell-\(trade.id)",
                date: trade.exitDate,
                price: trade.exitPrice,
                kind: .sell,
                label: trade.exitReason.title,
                returnPercent: trade.returnPercent
            )
        }
    }

    var body: some View {
        let renderedCandles = chartCandles
        let visibleTrades = self.visibleTrades
        let buyMarkers = visibleTrades.map { trade in
            BacktestTradeMarker(
                id: "buy-\(trade.id)",
                date: trade.entryDate,
                price: trade.entryPrice,
                kind: .buy,
                label: "매수",
                returnPercent: trade.returnPercent
            )
        }
        let sellMarkers = visibleTrades.map { trade in
            BacktestTradeMarker(
                id: "sell-\(trade.id)",
                date: trade.exitDate,
                price: trade.exitPrice,
                kind: .sell,
                label: trade.exitReason.title,
                returnPercent: trade.returnPercent
            )
        }

        return VStack(alignment: .leading, spacing: 8) {
            if visibleCandles.isEmpty {
                Text("차트로 보여줄 분봉 데이터가 아직 없습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
            } else {
                Chart {
                    ForEach(renderedCandles) { candle in
                        LineMark(
                            x: .value("시간", candle.date),
                            y: .value("종가", double(candle.closeValue))
                        )
                        .foregroundStyle(Color.accentColor)
                        .lineStyle(StrokeStyle(lineWidth: 1.6))
                    }

                    ForEach(buyMarkers) { marker in
                        PointMark(
                            x: .value("매수 예상", marker.date),
                            y: .value("가격", marker.price)
                        )
                        .foregroundStyle(.green)
                        .symbolSize(72)
                        .annotation(position: .top) {
                            Text("매수")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(.green)
                        }
                    }

                    ForEach(sellMarkers) { marker in
                        let markerColor = marker.returnPercent >= 0 ? Color.orange : Color.red
                        PointMark(
                            x: .value("매도 예상", marker.date),
                            y: .value("가격", marker.price)
                        )
                        .foregroundStyle(markerColor)
                        .symbolSize(72)
                        .annotation(position: .bottom) {
                            Text(marker.label)
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(markerColor)
                        }
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .frame(height: 220)
                .padding(10)
                .background(.background, in: RoundedRectangle(cornerRadius: 8))

                HStack(spacing: 12) {
                    Label("매수 예상", systemImage: "circle.fill")
                        .foregroundStyle(.green)
                    Label("익절/시간청산", systemImage: "circle.fill")
                        .foregroundStyle(.orange)
                    Label("손절", systemImage: "circle.fill")
                        .foregroundStyle(.red)
                    Spacer()
                    Text("최근 \(visibleCandles.count)개 분봉 · 진입은 다음 봉 시가, 청산은 손절/익절/최대 \(MechanicalSignalEngine.defaultMaxHoldingBars)봉 기준")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)

                Text("예상 금액은 1회 \(formattedDouble(tradeAmount, fractionDigits: 0))원씩 들어가고 왕복 비용 \(formattedDouble(MechanicalSignalEngine.defaultRoundTripCostPercent, fractionDigits: 2))%를 뺀 단순 계산입니다.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func double(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}

struct SimpleBacktestPreview: View {
    let summary: SimpleBacktestSummary
    let templateTitle: String
    let note: String
    let candles: [Candle]
    let signalIndexes: [Int]
    let exitSignalIndexes: [Int]
    let tradeAmount: Double
    let stopLossPercent: Double
    let takeProfitPercent: Double
    @State private var isChartExpanded = false

    init(
        summary: SimpleBacktestSummary,
        template: SimpleMacroTemplate,
        candles: [Candle] = [],
        signalIndexes: [Int] = [],
        exitSignalIndexes: [Int] = [],
        tradeAmount: Double = 0,
        stopLossPercent: Double = -5,
        takeProfitPercent: Double = 6
    ) {
        self.summary = summary
        self.templateTitle = template.title
        self.note = template == .buyDip ? "이 미리보기는 떨어진 뒤 다음 봉 시가로 진입하고 손절·익절·시간청산을 적용해 단순 검산합니다. 실제 수익을 보장하지 않습니다." : "알림형 매크로는 수익보다 조건이 너무 자주 나오는지 확인하는 용도입니다."
        self.candles = candles
        self.signalIndexes = signalIndexes
        self.exitSignalIndexes = exitSignalIndexes
        self.tradeAmount = tradeAmount
        self.stopLossPercent = stopLossPercent
        self.takeProfitPercent = takeProfitPercent
    }

    init(
        summary: SimpleBacktestSummary,
        templateTitle: String,
        note: String,
        candles: [Candle] = [],
        signalIndexes: [Int] = [],
        exitSignalIndexes: [Int] = [],
        tradeAmount: Double = 0,
        stopLossPercent: Double = -5,
        takeProfitPercent: Double = 6
    ) {
        self.summary = summary
        self.templateTitle = templateTitle
        self.note = note
        self.candles = candles
        self.signalIndexes = signalIndexes
        self.exitSignalIndexes = exitSignalIndexes
        self.tradeAmount = tradeAmount
        self.stopLossPercent = stopLossPercent
        self.takeProfitPercent = takeProfitPercent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("최근 차트로 미리 보기", systemImage: "chart.xyaxis.line")
                    .font(.headline)
                Spacer()
                Text(templateTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        isChartExpanded.toggle()
                    }
                } label: {
                    Label(isChartExpanded ? "차트 접기" : "차트 펼치기", systemImage: isChartExpanded ? "chevron.up" : "chevron.down")
                }
                .buttonStyle(.bordered)
            }

            if summary.hasSignals {
                HStack(spacing: 12) {
                    previewTile("거래", "\(summary.signalCount)번", "겹친 신호는 제외")
                    previewTile("좋았던 비율", "\(formattedDouble(summary.winRate, fractionDigits: 0))%", "비용 차감 후 플러스")
                    previewTile("평균 수익률", "\(signed(summary.averageReturn))%", "손절/익절/시간청산 기준")
                    previewTile("최악", "\(signed(summary.worstReturn))%", "가장 안 좋았던 경우")
                }

                Text("예상 손익은 대략 \(signedMoney(summary.estimatedPnL))원입니다. 진입은 다음 봉 시가, 청산은 손절 \(formattedDouble(abs(stopLossPercent), fractionDigits: 1))% / 익절 \(formattedDouble(abs(takeProfitPercent), fractionDigits: 1))% / 최대 \(MechanicalSignalEngine.defaultMaxHoldingBars)봉 기준이고 왕복 비용 \(formattedDouble(MechanicalSignalEngine.defaultRoundTripCostPercent, fractionDigits: 2))%를 뺐습니다.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("최근 차트에서는 이 조건으로 끝까지 계산 가능한 거래가 거의 나오지 않았어요. 조건을 더 느슨하게 하거나 다른 기간을 확인해보세요.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            }

            if isChartExpanded {
                BacktestTradeChart(
                    candles: candles,
                    signalIndexes: signalIndexes,
                    exitSignalIndexes: exitSignalIndexes,
                    tradeAmount: tradeAmount,
                    stopLossPercent: stopLossPercent,
                    takeProfitPercent: takeProfitPercent
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            Text(note)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }

    private func previewTile(_ title: String, _ value: String, _ caption: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.monospacedDigit())
            Text(caption)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func signed(_ value: Double) -> String {
        "\(value >= 0 ? "+" : "")\(formattedDouble(value, fractionDigits: 2))"
    }

    private func signedMoney(_ value: Double) -> String {
        "\(value >= 0 ? "+" : "")\(formattedDouble(value, fractionDigits: 0))"
    }
}

struct SimpleExecutionGuard: View {
    let mode: SimpleMacroMode
    let allowLiveOrders: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.callout.weight(.semibold))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }

    private var icon: String {
        if mode == .auto && allowLiveOrders {
            return "exclamationmark.triangle"
        }
        return "lock.shield"
    }

    private var color: Color {
        if mode == .auto && allowLiveOrders {
            return .orange
        }
        return .green
    }

    private var title: String {
        if mode == .auto && allowLiveOrders {
            return "실전 주문 가능 상태"
        }
        return "모의/안전 우선"
    }

    private var message: String {
        switch mode {
        case .alert:
            return "알림만 보내고 주문은 만들지 않습니다."
        case .ask:
            return "조건이 맞아도 바로 주문하지 않고 승인 대기 목록에 올립니다."
        case .auto:
            if allowLiveOrders {
                return "라이브 주문 허용이 켜져 있습니다. 금액과 종목을 다시 확인하세요."
            }
            return "자동 주문을 골라도 설정에서 라이브 주문 허용이 꺼져 있으면 실제 주문은 막힙니다."
        }
    }
}

struct SimpleMacroCard: View {
    @Binding var strategy: TradingStrategy
    let onDelete: () -> Void
    let onChanged: () -> Void
    @State private var showsDeleteConfirmation = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Toggle("", isOn: Binding(
                get: { strategy.isEnabled },
                set: { value in
                    strategy.isEnabled = value
                    strategy.updatedAt = Date()
                    onChanged()
                }
            ))
            .toggleStyle(.switch)
            .labelsHidden()

            VStack(alignment: .leading, spacing: 6) {
                Text(strategy.name)
                    .font(.headline)
                Text("\(strategy.symbol) · \(strategy.mode.title) · \(strategy.enabledLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(simpleSummary)
                    .font(.callout)
            }

            Spacer()

            Button(role: .destructive) {
                showsDeleteConfirmation = true
            } label: {
                Label("삭제", systemImage: "trash")
            }
            .buttonStyle(.bordered)
            .confirmationDialog(
                "이 매크로를 삭제할까요?",
                isPresented: $showsDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("삭제", role: .destructive, action: onDelete)
                Button("취소", role: .cancel) {}
            } message: {
                Text("\(strategy.name)을 삭제합니다. 삭제한 매크로는 되돌릴 수 없습니다.")
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var simpleSummary: String {
        guard let condition = strategy.conditions.first else {
            return "조건이 없습니다."
        }
        if condition.action == .buy {
            return "\(formattedDouble(condition.threshold, fractionDigits: 1))% 움직이면 \(formattedDouble(condition.amount, fractionDigits: 0))원 매수 후보"
        }
        return "\(condition.metric.title) \(formattedDouble(condition.threshold, fractionDigits: 1))이면 알림"
    }
}

struct StrategyEditor: View {
    @EnvironmentObject private var session: AppSession
    @Binding var strategy: TradingStrategy
    @State private var selectedStep: StrategyEditorStep = .basic
    @State private var reviewEngine: AIEngineKind = .claude

    private var latestStrategyAIResult: AIAnalysisResult? {
        session.aiResults.first {
            $0.symbol.caseInsensitiveCompare(strategy.symbol) == .orderedSame
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                strategyHeader

                Picker("단계", selection: $selectedStep) {
                    ForEach(StrategyEditorStep.allCases) { step in
                        Text(step.title).tag(step)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedStep {
                case .basic:
                    basicStep
                case .conditions:
                    conditionsStep
                case .risk:
                    riskStep
                case .review:
                    reviewStep
                case .execution:
                    executionStep
                }
            }
            .padding(24)
        }
    }

    private var strategyHeader: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                TextField("전략 이름", text: $strategy.name)
                    .font(.title2.weight(.semibold))
                    .textFieldStyle(.plain)
                HStack(spacing: 8) {
                    Text(strategy.symbol)
                        .font(.callout.monospaced().weight(.semibold))
                    Text(strategy.mode.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("\(strategy.conditions.count)개 조건")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Toggle("사용", isOn: $strategy.isEnabled)
                .toggleStyle(.switch)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var basicStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("기본 설정", "scope")

            HStack(spacing: 12) {
                StockSearchField(text: $strategy.symbol, placeholder: "종목명 또는 코드", width: 260) { symbol in
                    strategy.symbol = symbol
                }

                Picker("모드", selection: $strategy.mode) {
                    ForEach(OperationMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 12) {
                GridRow {
                    numberField("기준가", value: $strategy.referencePrice)
                    numberField("일일 한도", value: $strategy.maxDailyAmount)
                    Stepper("쿨다운 \(strategy.cooldownMinutes)분", value: $strategy.cooldownMinutes, in: 1...240)
                }
            }

            strategyPreview
        }
    }

    private var conditionsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("조건", "line.3.horizontal.decrease.circle")
                Spacer()
                Button {
                    strategy.conditions.append(StrategyCondition())
                } label: {
                    Label("조건 추가", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }

            if strategy.conditions.isEmpty {
                ContentUnavailableView("조건이 없습니다", systemImage: "line.3.horizontal.decrease.circle")
                    .frame(maxWidth: .infinity, minHeight: 180)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach($strategy.conditions) { $condition in
                    let conditionID = condition.id
                    ConditionRow(condition: $condition) {
                        strategy.conditions.removeAll { $0.id == conditionID }
                    }
                }
            }
        }
    }

    private var riskStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("위험 설정", "shield.lefthalf.filled")

            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 12) {
                GridRow {
                    numberField("손절 %", value: $strategy.stopLossPercent)
                    numberField("익절 %", value: $strategy.takeProfitPercent)
                    numberField("일일 한도", value: $strategy.maxDailyAmount)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("위험 메모")
                    .font(.headline)
                TextEditor(text: $strategy.riskNotes)
                    .font(.callout)
                    .lineSpacing(3)
                    .frame(minHeight: 110)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.25))
                    )
            }

            StrategyRiskChecklist(strategy: strategy)
        }
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                sectionTitle("AI 검토", "brain.head.profile")
                Spacer()
                Picker("엔진", selection: $reviewEngine) {
                    ForEach(AIEngineKind.allCases) { engine in
                        Text(engine.displayName).tag(engine)
                    }
                }
                .frame(width: 180)
                Button {
                    runStrategyReview()
                } label: {
                    Label("검토 요청", systemImage: "paperplane")
                }
                .buttonStyle(.borderedProminent)
            }

            if let latestStrategyAIResult {
                LatestAIReportCard(result: latestStrategyAIResult) {
                    session.deleteAIResult(latestStrategyAIResult.id)
                }
            } else {
                AIEmptyReviewPanel(strategy: strategy)
            }
        }
    }

    private var executionStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle("실행", "play.circle")

            HStack(spacing: 12) {
                Button {
                    strategy.symbol = session.resolveSymbol(from: strategy.symbol)
                    strategy.updatedAt = Date()
                    session.saveAppState()
                } label: {
                    Label("전략 저장", systemImage: "tray.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    strategy.symbol = session.resolveSymbol(from: strategy.symbol)
                    session.setAutomationEnabled(true)
                } label: {
                    Label("지금 평가", systemImage: "play")
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                executionRow("전략 상태", strategy.enabledLabel, strategy.isEnabled ? "checkmark.circle" : "pause.circle")
                executionRow("주문 모드", strategy.mode.title, "switch.2")
                executionRow("다음 조건", session.nextTriggerText(for: strategy), "scope")
                executionRow("왜 안 사나", session.executionReadinessText(for: strategy), "info.circle")
                executionRow("승인 대기", "\(session.pendingOrderCount)건", "clock.badge.exclamationmark")
                executionRow("라이브 주문", session.safetySettings.allowLiveOrders ? "허용" : "잠김", session.safetySettings.allowLiveOrders ? "lock.open" : "lock")
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private var strategyPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("전략 요약")
                .font(.headline)
            Text("\(strategy.symbol) 기준가 \(formattedDecimal(Decimal(strategy.referencePrice), fractionDigits: 2)), \(strategy.mode.title), 조건 \(strategy.conditions.count)개")
                .font(.callout)
            Text("손절 \(formattedDecimal(Decimal(strategy.stopLossPercent), fractionDigits: 1))%, 익절 \(formattedDecimal(Decimal(strategy.takeProfitPercent), fractionDigits: 1))%, 쿨다운 \(strategy.cooldownMinutes)분")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func sectionTitle(_ title: String, _ icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.headline)
    }

    private func executionRow(_ title: String, _ value: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Label(title, systemImage: icon)
                .foregroundStyle(.secondary)
                .frame(width: 96, alignment: .leading)
            Spacer()
            Text(value)
                .font(.callout.weight(.semibold))
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func runStrategyReview() {
        strategy.symbol = session.resolveSymbol(from: strategy.symbol)
        let prompt = """
        \(strategy.symbol) 전략을 검토해줘.

        전략명: \(strategy.name)
        모드: \(strategy.mode.title)
        기준가: \(strategy.referencePrice)
        손절: \(strategy.stopLossPercent)%
        익절: \(strategy.takeProfitPercent)%
        일일 한도: \(strategy.maxDailyAmount)
        쿨다운: \(strategy.cooldownMinutes)분
        조건:
        \(strategy.conditions.map(conditionSummary).joined(separator: "\n"))
        위험 메모:
        \(strategy.riskNotes)

        출력은 AI 코멘트, 위험 요인, 중복 주문 가능성, 손절/익절 조정 의견, 실행 전 체크 순서로 나눠줘.
        매수·매도 확정 지시가 아니라 전략 검토 의견으로만 작성해줘.
        """
        Task {
            await session.runAIAnalysis(engine: reviewEngine, symbol: strategy.symbol, prompt: prompt)
        }
    }

    private func conditionSummary(_ condition: StrategyCondition) -> String {
        "- \(condition.metric.title) \(condition.threshold) → \(condition.action.title), \(condition.orderType.title), 금액 \(condition.amount), 수량 \(condition.quantity), \(condition.note)"
    }

    private func numberField(_ title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(title, value: value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 130)
        }
    }
}

struct ConditionRow: View {
    @Binding var condition: StrategyCondition
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(condition.metric.title)
                    .font(.callout.weight(.semibold))
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("조건 삭제")
            }

            HStack(spacing: 10) {
                Picker("지표", selection: $condition.metric) {
                    ForEach(TriggerMetric.allCases) { metric in
                        Text(metric.title).tag(metric)
                    }
                }
                .frame(width: 190)

                TextField("기준값", value: $condition.threshold, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 110)

                Picker("행동", selection: $condition.action) {
                    ForEach(StrategyAction.allCases) { action in
                        Text(action.title).tag(action)
                    }
                }
                .frame(width: 100)

                Picker("유형", selection: $condition.orderType) {
                    ForEach(DraftOrderType.allCases) { orderType in
                        Text(orderType.title).tag(orderType)
                    }
                }
                .frame(width: 100)

                TextField("금액", value: $condition.amount, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 110)

                TextField("수량", value: $condition.quantity, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
            }
            TextField("메모", text: $condition.note)
                .textFieldStyle(.roundedBorder)
        }
        .padding(12)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct StrategyRiskChecklist: View {
    let strategy: TradingStrategy

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("체크")
                .font(.headline)
            checkRow("조건 수", strategy.conditions.isEmpty ? "조건 없음" : "\(strategy.conditions.count)개")
            checkRow("손절", "\(formattedDecimal(Decimal(strategy.stopLossPercent), fractionDigits: 1))%")
            checkRow("익절", "\(formattedDecimal(Decimal(strategy.takeProfitPercent), fractionDigits: 1))%")
            checkRow("주문 방식", strategy.mode.title)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private func checkRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.callout.weight(.medium))
        }
    }
}

struct AIEmptyReviewPanel: View {
    let strategy: TradingStrategy

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI 코멘트 없음", systemImage: "brain.head.profile")
                .font(.headline)
            Text("\(strategy.symbol) 전략 검토 결과가 아직 없습니다.")
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 160, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct OrderLogView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("주문 로그", systemImage: "doc.text.magnifyingglass")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button {
                    session.orderLogs.removeAll()
                    session.saveAppState()
                } label: {
                    Label("비우기", systemImage: "trash")
                }
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    PendingOrdersPanel()
                        .environmentObject(session)

                    if session.orderLogs.isEmpty {
                        ContentUnavailableView("주문 로그가 없습니다", systemImage: "doc.text")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("판단 로그", systemImage: "list.bullet.clipboard")
                                .font(.headline)
                            ForEach(session.orderLogs) { log in
                                OrderLogRow(log: log)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
    }
}

struct PendingOrdersPanel: View {
    @EnvironmentObject private var session: AppSession

    private var visibleDrafts: [PendingOrderDraft] {
        session.pendingOrders.filter { draft in
            draft.status == .pendingReview || draft.status == .blocked
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("승인 대기 주문", systemImage: "checklist")
                    .font(.headline)
                Spacer()
                Text("\(visibleDrafts.count)건")
                    .foregroundStyle(.secondary)
            }

            if visibleDrafts.isEmpty {
                Text("승인 대기 중인 주문이 없습니다.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .background(.background, in: RoundedRectangle(cornerRadius: 8))
            } else {
                ForEach(visibleDrafts) { draft in
                    PendingOrderRow(draft: draft)
                        .environmentObject(session)
                }
            }
        }
    }
}

struct PendingOrderRow: View {
    @EnvironmentObject private var session: AppSession
    let draft: PendingOrderDraft

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(draft.orderSummary)
                        .font(.headline)
                    Text("\(draft.strategyName) · \(draft.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(draft.status.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(draft.status == .blocked ? .red : .orange)
            }

            Text("조건: \(draft.sourceEvent), 기준가 \(formattedDecimal(Decimal(draft.referencePrice), fractionDigits: 2)) \(draft.currency)")
                .font(.callout)

            if !draft.safetyWarnings.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(draft.safetyWarnings, id: \.self) { warning in
                        Label(warning, systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                    }
                }
                .font(.caption)
            }

            HStack {
                Button {
                    session.approvePendingOrderDryRun(draft)
                } label: {
                    Label("모의 승인", systemImage: "checkmark.circle")
                }

                Button {
                    session.cancelPendingOrder(draft)
                } label: {
                    Label("취소", systemImage: "xmark.circle")
                }

                Button {
                    Task { await session.submitPendingOrder(draft) }
                } label: {
                    Label("실주문 제출", systemImage: "bolt")
                }
                .disabled(!session.safetySettings.allowLiveOrders || draft.status == .blocked)

                Spacer()
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct OrderLogRow: View {
    let log: OrderLogEntry

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: log.isLiveOrder ? "bolt.circle.fill" : "bell.badge")
                .font(.title3)
                .foregroundStyle(log.isLiveOrder ? .orange : .blue)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline) {
                    Text(log.symbol)
                        .font(.headline.monospaced())
                    Text(log.strategyName)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(log.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(easyTitle)
                    .font(.headline)
                Text(easyDetail)
                    .font(.callout)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Label(log.mode.title, systemImage: "switch.2")
                    Label(log.isLiveOrder ? "실제 주문" : "주문 안 함", systemImage: log.isLiveOrder ? "bolt" : "lock")
                    Spacer()
                    Text(cleanedLogText(log.result))
                        .lineLimit(2)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var easyTitle: String {
        if log.event.contains("조건 충족") {
            return "조건이 맞아서 앱이 확인했어요"
        }
        if log.event.contains("취소") {
            return "주문 후보를 취소했어요"
        }
        if log.event.contains("승인") {
            return "사용자가 주문 후보를 확인했어요"
        }
        if log.event.contains("손절") || log.event.contains("익절") {
            return "위험 구간에 가까워졌어요"
        }
        return cleanedLogText(log.event)
    }

    private var easyDetail: String {
        let request = cleanedLogText(log.orderRequest)
        if request == "주문 없음" || request.isEmpty {
            return cleanedLogText(log.event)
        }
        return request
    }
}
