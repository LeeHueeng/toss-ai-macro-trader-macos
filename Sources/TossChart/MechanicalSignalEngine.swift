import Foundation

enum BacktestExitReason {
    case takeProfit
    case stopLoss
    case strategyExit
    case timeLimit
    case endOfData

    var title: String {
        switch self {
        case .takeProfit: "익절"
        case .stopLoss: "손절"
        case .strategyExit: "전략매도"
        case .timeLimit: "시간청산"
        case .endOfData: "마지막봉"
        }
    }
}

struct BacktestTrade: Identifiable {
    let id: String
    let signalIndex: Int
    let entryIndex: Int
    let exitIndex: Int
    let entryDate: Date
    let exitDate: Date
    let entryPrice: Double
    let exitPrice: Double
    let returnPercent: Double
    let estimatedPnL: Double
    let exitReason: BacktestExitReason

    var isWin: Bool {
        returnPercent > 0
    }
}

enum MechanicalSignalEngine {
    static let defaultMaxHoldingBars = 30
    static let defaultRoundTripCostPercent = 0.1

    static func signalIndexes(
        candles: [Candle],
        template: MechanicalStrategyTemplate,
        shortPeriod: Int,
        longPeriod: Int,
        rsiPeriod: Int,
        rsiLevel: Double,
        bandPeriod: Int,
        bandStdDev: Double,
        breakoutLookback: Int,
        movePercent: Double = 2.5,
        volumeMultiplier: Double = 1.8,
        side: StrategyAction = .buy
    ) -> [Int] {
        switch template {
        case .movingAverageCross:
            return movingAverageCrossSignals(candles: candles, shortPeriod: shortPeriod, longPeriod: longPeriod)
        case .rsiRebound:
            return rsiReboundSignals(candles: candles, period: rsiPeriod, level: rsiLevel)
        case .bollingerRebound:
            return bollingerReboundSignals(candles: candles, period: bandPeriod, stdDev: bandStdDev)
        case .breakout:
            return breakoutSignals(candles: candles, lookback: breakoutLookback)
        case .macdCross:
            return macdCrossSignals(candles: candles)
        case .surgeVolumeMomentum:
            return surgeVolumeMomentumSignals(candles: candles, lookback: breakoutLookback, movePercent: movePercent, volumeMultiplier: volumeMultiplier)
        case .plungeRebound:
            return plungeReboundSignals(candles: candles, lookback: max(3, breakoutLookback), movePercent: movePercent, volumeMultiplier: volumeMultiplier)
        case .tradeValueFocus:
            return tradeValueFocusSignals(candles: candles, lookback: breakoutLookback, valueMultiplier: volumeMultiplier)
        case .fixedGridTrading:
            return fixedGridSignals(candles: candles, anchorPrice: nil, gapPercent: movePercent, side: side)
        case .bollingerBandChannel:
            return bollingerChannelSignals(candles: candles, period: bandPeriod, stdDev: bandStdDev, side: side)
        case .rsiBandChannel:
            return rsiChannelSignals(candles: candles, period: rsiPeriod, oversold: rsiLevel, overbought: 100 - rsiLevel, side: side)
        case .meanReversionCombo:
            return meanReversionComboSignals(candles: candles, bandPeriod: bandPeriod, stdDev: bandStdDev, rsiPeriod: rsiPeriod, oversold: rsiLevel, overbought: 100 - rsiLevel, side: side)
        case .marketMakingLite:
            return marketMakingLiteSignals(candles: candles, period: max(5, breakoutLookback), spreadPercent: movePercent, side: side)
        case .koquantMinuteMomentum:
            return koquantMinuteMomentumSignals(candles: candles, lookback: breakoutLookback, valueMultiplier: volumeMultiplier)
        case .rangeSwingRebound:
            return rangeSwingReboundSignals(candles: candles, lookback: max(5, breakoutLookback), swingPercent: movePercent)
        case .rangeUpperWarning:
            return rangeUpperWarningSignals(candles: candles, lookback: max(5, breakoutLookback), swingPercent: movePercent)
        case .semiconductorValueBreakout:
            return semiconductorValueBreakoutSignals(candles: candles, lookback: breakoutLookback, volumeMultiplier: 1.5)
        case .semiconductorDipStabilize:
            return semiconductorDipStabilizeSignals(candles: candles, lookback: max(3, breakoutLookback))
        case .semiconductorTrendRestart:
            return semiconductorTrendRestartSignals(candles: candles, shortPeriod: shortPeriod, longPeriod: longPeriod, lookback: max(5, breakoutLookback))
        }
    }

    static func signalIndexes(candles: [Candle], note: String) -> [Int] {
        guard note.hasPrefix("MECH:") else {
            return []
        }

        let parts = note.split(separator: ":").map(String.init)
        guard parts.count >= 2 else {
            return []
        }

        let params = Dictionary(uniqueKeysWithValues: parts.dropFirst(2).compactMap { part -> (String, String)? in
            let pair = part.split(separator: "=", maxSplits: 1).map(String.init)
            guard pair.count == 2 else { return nil }
            return (pair[0], pair[1])
        })

        switch parts[1] {
        case "FIXED_GRID":
            return fixedGridSignals(
                candles: candles,
                anchorPrice: Double(params["anchor"] ?? ""),
                gapPercent: Double(params["gap"] ?? "") ?? 1.5,
                side: strategySide(params["side"])
            )
        case "SMA_CROSS":
            return movingAverageCrossSignals(
                candles: candles,
                shortPeriod: Int(params["short"] ?? "") ?? 5,
                longPeriod: Int(params["long"] ?? "") ?? 20
            )
        case "RSI_REBOUND":
            return rsiReboundSignals(
                candles: candles,
                period: Int(params["period"] ?? "") ?? 14,
                level: Double(params["level"] ?? "") ?? 30
            )
        case "BOLLINGER_REBOUND":
            return bollingerReboundSignals(
                candles: candles,
                period: Int(params["period"] ?? "") ?? 20,
                stdDev: Double(params["std"] ?? "") ?? 2
            )
        case "BOLLINGER_CHANNEL":
            return bollingerChannelSignals(
                candles: candles,
                period: Int(params["period"] ?? "") ?? 20,
                stdDev: Double(params["std"] ?? "") ?? 2,
                side: strategySide(params["side"])
            )
        case "RSI_CHANNEL":
            let oversold = Double(params["oversold"] ?? "") ?? 30
            return rsiChannelSignals(
                candles: candles,
                period: Int(params["period"] ?? "") ?? 14,
                oversold: oversold,
                overbought: Double(params["overbought"] ?? "") ?? (100 - oversold),
                side: strategySide(params["side"])
            )
        case "BREAKOUT":
            return breakoutSignals(
                candles: candles,
                lookback: Int(params["lookback"] ?? "") ?? 20
            )
        case "MACD_CROSS":
            return macdCrossSignals(candles: candles)
        case "SURGE_VOLUME_MOMENTUM":
            return surgeVolumeMomentumSignals(
                candles: candles,
                lookback: Int(params["lookback"] ?? "") ?? 20,
                movePercent: Double(params["move"] ?? "") ?? 2.5,
                volumeMultiplier: Double(params["volume"] ?? "") ?? 1.8
            )
        case "PLUNGE_REBOUND":
            return plungeReboundSignals(
                candles: candles,
                lookback: Int(params["lookback"] ?? "") ?? 5,
                movePercent: Double(params["move"] ?? "") ?? 2.5,
                volumeMultiplier: Double(params["volume"] ?? "") ?? 1.8
            )
        case "TRADE_VALUE_FOCUS":
            return tradeValueFocusSignals(
                candles: candles,
                lookback: Int(params["lookback"] ?? "") ?? 20,
                valueMultiplier: Double(params["value"] ?? "") ?? 1.8
            )
        case "MEAN_REVERSION_COMBO":
            let oversold = Double(params["oversold"] ?? "") ?? 30
            return meanReversionComboSignals(
                candles: candles,
                bandPeriod: Int(params["band"] ?? "") ?? 20,
                stdDev: Double(params["std"] ?? "") ?? 2,
                rsiPeriod: Int(params["rsi"] ?? "") ?? 14,
                oversold: oversold,
                overbought: Double(params["overbought"] ?? "") ?? (100 - oversold),
                side: strategySide(params["side"])
            )
        case "MARKET_MAKING_LITE":
            return marketMakingLiteSignals(
                candles: candles,
                period: Int(params["period"] ?? "") ?? 20,
                spreadPercent: Double(params["spread"] ?? "") ?? 0.8,
                side: strategySide(params["side"])
            )
        case "KOQUANT_MINUTE_MOMENTUM":
            return koquantMinuteMomentumSignals(
                candles: candles,
                lookback: Int(params["lookback"] ?? "") ?? 20,
                valueMultiplier: Double(params["value"] ?? "") ?? 2
            )
        case "RANGE_SWING_REBOUND":
            return rangeSwingReboundSignals(
                candles: candles,
                lookback: Int(params["lookback"] ?? "") ?? 20,
                swingPercent: Double(params["swing"] ?? "") ?? 2.5
            )
        case "RANGE_UPPER_WARNING":
            return rangeUpperWarningSignals(
                candles: candles,
                lookback: Int(params["lookback"] ?? "") ?? 20,
                swingPercent: Double(params["swing"] ?? "") ?? 2.5
            )
        case "SEMI_VALUE_BREAKOUT":
            return semiconductorValueBreakoutSignals(
                candles: candles,
                lookback: Int(params["lookback"] ?? "") ?? 20,
                volumeMultiplier: Double(params["volume"] ?? "") ?? 1.5
            )
        case "SEMI_DIP_STABILIZE":
            return semiconductorDipStabilizeSignals(
                candles: candles,
                lookback: Int(params["lookback"] ?? "") ?? 5
            )
        case "SEMI_TREND_RESTART":
            return semiconductorTrendRestartSignals(
                candles: candles,
                shortPeriod: Int(params["short"] ?? "") ?? 5,
                longPeriod: Int(params["long"] ?? "") ?? 20,
                lookback: Int(params["lookback"] ?? "") ?? 10
            )
        default:
            return []
        }
    }

    static func latestSignal(candles: [Candle], note: String) -> Bool {
        guard candles.count >= 2 else {
            return false
        }
        return signalIndexes(candles: candles, note: note).last == candles.count - 1
    }

    static func summary(
        candles: [Candle],
        signalIndexes: [Int],
        tradeAmount: Double,
        exitSignalIndexes: [Int] = [],
        stopLossPercent: Double = -5,
        takeProfitPercent: Double = 6,
        maxHoldingBars: Int = defaultMaxHoldingBars,
        roundTripCostPercent: Double = defaultRoundTripCostPercent
    ) -> SimpleBacktestSummary {
        let simulatedTrades = trades(
            candles: candles,
            signalIndexes: signalIndexes,
            tradeAmount: tradeAmount,
            exitSignalIndexes: exitSignalIndexes,
            stopLossPercent: stopLossPercent,
            takeProfitPercent: takeProfitPercent,
            maxHoldingBars: maxHoldingBars,
            roundTripCostPercent: roundTripCostPercent
        )

        guard !simulatedTrades.isEmpty else {
            return SimpleBacktestSummary(signalCount: 0, winCount: 0, averageReturn: 0, worstReturn: 0, estimatedPnL: 0)
        }

        let returns = simulatedTrades.map(\.returnPercent)
        let estimatedPnL = simulatedTrades.reduce(0) { partialResult, trade in
            partialResult + trade.estimatedPnL
        }

        let averageReturn = returns.reduce(0, +) / Double(returns.count)
        let worstReturn = returns.min() ?? 0
        return SimpleBacktestSummary(
            signalCount: simulatedTrades.count,
            winCount: simulatedTrades.filter(\.isWin).count,
            averageReturn: averageReturn,
            worstReturn: worstReturn,
            estimatedPnL: estimatedPnL
        )
    }

    static func trades(
        candles: [Candle],
        signalIndexes: [Int],
        tradeAmount: Double,
        exitSignalIndexes: [Int] = [],
        stopLossPercent: Double = -5,
        takeProfitPercent: Double = 6,
        maxHoldingBars: Int = defaultMaxHoldingBars,
        roundTripCostPercent: Double = defaultRoundTripCostPercent
    ) -> [BacktestTrade] {
        guard candles.count >= 3, tradeAmount > 0 else {
            return []
        }

        let stopRate = -abs(stopLossPercent)
        let takeRate = max(0.1, abs(takeProfitPercent))
        let holdingBars = max(1, maxHoldingBars)
        let exitSignals = Set(exitSignalIndexes)
        var lastExitIndex = -1
        var result: [BacktestTrade] = []

        for signalIndex in Array(Set(signalIndexes)).sorted() {
            let entryIndex = signalIndex + 1
            guard candles.indices.contains(signalIndex),
                  candles.indices.contains(entryIndex),
                  entryIndex > lastExitIndex else {
                continue
            }

            let entryOpen = double(candles[entryIndex].openValue)
            let entryClose = double(candles[entryIndex].closeValue)
            let entryPrice = entryOpen > 0 ? entryOpen : entryClose
            guard entryPrice > 0 else {
                continue
            }

            let stopPrice = entryPrice * (1 + stopRate / 100)
            let takePrice = entryPrice * (1 + takeRate / 100)
            let maxExitIndex = min(candles.count - 1, entryIndex + holdingBars)
            var exitIndex = maxExitIndex
            var exitPrice = double(candles[maxExitIndex].closeValue)
            var exitReason: BacktestExitReason = maxExitIndex == candles.count - 1 ? .endOfData : .timeLimit

            for index in entryIndex...maxExitIndex {
                let low = double(candles[index].lowValue)
                let high = double(candles[index].highValue)
                if low <= stopPrice {
                    exitIndex = index
                    exitPrice = stopPrice
                    exitReason = .stopLoss
                    break
                }
                if high >= takePrice {
                    exitIndex = index
                    exitPrice = takePrice
                    exitReason = .takeProfit
                    break
                }
                if index > entryIndex, exitSignals.contains(index) {
                    exitIndex = index
                    exitPrice = double(candles[index].closeValue)
                    exitReason = .strategyExit
                    break
                }
            }

            guard exitPrice > 0 else {
                continue
            }

            let grossReturn = ((exitPrice - entryPrice) / entryPrice) * 100
            let netReturn = grossReturn - max(0, roundTripCostPercent)
            let estimatedPnL = tradeAmount * (netReturn / 100)
            result.append(
                BacktestTrade(
                    id: "\(signalIndex)-\(candles[entryIndex].timestamp)-\(candles[exitIndex].timestamp)",
                    signalIndex: signalIndex,
                    entryIndex: entryIndex,
                    exitIndex: exitIndex,
                    entryDate: candles[entryIndex].date,
                    exitDate: candles[exitIndex].date,
                    entryPrice: entryPrice,
                    exitPrice: exitPrice,
                    returnPercent: netReturn,
                    estimatedPnL: estimatedPnL,
                    exitReason: exitReason
                )
            )
            lastExitIndex = exitIndex
        }

        return result
    }

    private static func strategySide(_ value: String?) -> StrategyAction {
        guard let value else {
            return .buy
        }
        return value.uppercased() == "SELL" ? .sell : .buy
    }

    private static func fixedGridSignals(candles: [Candle], anchorPrice: Double?, gapPercent: Double, side: StrategyAction) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        guard closes.count >= 2 else {
            return []
        }

        let anchor = anchorPrice.flatMap { $0 > 0 ? $0 : nil } ?? closes[max(0, closes.count / 2)]
        let gap = anchor * max(0.1, abs(gapPercent)) / 100
        guard anchor > 0, gap > 0 else {
            return []
        }

        var indexes: [Int] = []
        for index in 1..<closes.count {
            let previousClose = closes[index - 1]
            let currentClose = closes[index]
            let previousBuyLevel = floor(max(0, anchor - previousClose) / gap)
            let currentBuyLevel = floor(max(0, anchor - currentClose) / gap)
            let previousSellLevel = floor(max(0, previousClose - anchor) / gap)
            let currentSellLevel = floor(max(0, currentClose - anchor) / gap)
            switch side {
            case .buy:
                if currentClose < anchor, currentBuyLevel > previousBuyLevel {
                    indexes.append(index)
                }
            case .sell:
                if currentClose > anchor, currentSellLevel > previousSellLevel {
                    indexes.append(index)
                }
            case .notify:
                break
            }
        }
        return indexes
    }

    private static func bollingerChannelSignals(candles: [Candle], period: Int, stdDev: Double, side: StrategyAction) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        guard closes.count >= period + 1 else {
            return []
        }

        var indexes: [Int] = []
        for index in period..<closes.count {
            guard let lower = bollingerBand(closes, endingAt: index, period: period, stdDev: stdDev)?.lower,
                  let previousLower = bollingerBand(closes, endingAt: index - 1, period: period, stdDev: stdDev)?.lower,
                  let upper = bollingerBand(closes, endingAt: index, period: period, stdDev: stdDev)?.upper,
                  let previousUpper = bollingerBand(closes, endingAt: index - 1, period: period, stdDev: stdDev)?.upper else {
                continue
            }

            switch side {
            case .buy:
                if closes[index - 1] > previousLower, closes[index] <= lower {
                    indexes.append(index)
                }
            case .sell:
                if closes[index - 1] < previousUpper, closes[index] >= upper {
                    indexes.append(index)
                }
            case .notify:
                break
            }
        }
        return indexes
    }

    private static func rsiChannelSignals(candles: [Candle], period: Int, oversold: Double, overbought: Double, side: StrategyAction) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        let values = rsi(closes: closes, period: period)
        guard values.count == closes.count else {
            return []
        }

        let lower = min(oversold, overbought)
        let upper = max(oversold, overbought)
        var indexes: [Int] = []
        for index in 1..<values.count {
            guard let previous = values[index - 1], let current = values[index] else {
                continue
            }

            switch side {
            case .buy:
                if previous > lower, current <= lower {
                    indexes.append(index)
                }
            case .sell:
                if previous < upper, current >= upper {
                    indexes.append(index)
                }
            case .notify:
                break
            }
        }
        return indexes
    }

    private static func meanReversionComboSignals(candles: [Candle], bandPeriod: Int, stdDev: Double, rsiPeriod: Int, oversold: Double, overbought: Double, side: StrategyAction) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        let rsiValues = rsi(closes: closes, period: rsiPeriod)
        guard closes.count >= max(bandPeriod, rsiPeriod) + 1, rsiValues.count == closes.count else {
            return []
        }

        let lowerRSI = min(oversold, overbought)
        let upperRSI = max(oversold, overbought)
        var indexes: [Int] = []
        for index in max(bandPeriod, rsiPeriod)..<closes.count {
            guard let band = bollingerBand(closes, endingAt: index, period: bandPeriod, stdDev: stdDev),
                  let currentRSI = rsiValues[index] else {
                continue
            }

            switch side {
            case .buy:
                if closes[index] <= band.lower, currentRSI <= lowerRSI {
                    indexes.append(index)
                }
            case .sell:
                if closes[index] >= band.upper || currentRSI >= upperRSI {
                    indexes.append(index)
                }
            case .notify:
                break
            }
        }
        return indexes
    }

    private static func marketMakingLiteSignals(candles: [Candle], period: Int, spreadPercent: Double, side: StrategyAction) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        guard period > 1, closes.count >= period + 1 else {
            return []
        }

        let spread = max(0.1, abs(spreadPercent))
        var indexes: [Int] = []
        for index in period..<closes.count {
            guard let mid = sma(closes, endingAt: index, period: period),
                  let previousMid = sma(closes, endingAt: index - 1, period: period),
                  previousMid > 0 else {
                continue
            }

            let midSlope = abs((mid - previousMid) / previousMid) * 100
            let isSidewaysEnough = midSlope <= spread * 0.55
            let bid = mid * (1 - spread / 100)
            let ask = mid * (1 + spread / 100)

            switch side {
            case .buy:
                if isSidewaysEnough, closes[index - 1] > bid, closes[index] <= bid {
                    indexes.append(index)
                }
            case .sell:
                if isSidewaysEnough, closes[index - 1] < ask, closes[index] >= ask {
                    indexes.append(index)
                }
            case .notify:
                break
            }
        }
        return indexes
    }

    private static func koquantMinuteMomentumSignals(candles: [Candle], lookback: Int, valueMultiplier: Double) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        let volumes = candles.map { double($0.volumeValue) }
        let tradeValues = zip(closes, volumes).map { close, volume in
            max(0, close) * max(0, volume)
        }
        let period = max(2, lookback)
        guard closes.count >= period + 1 else {
            return []
        }

        let multiplier = max(1.0, valueMultiplier)
        var indexes: [Int] = []
        for index in period..<closes.count {
            let historyRange = (index - period)..<index
            let averageTradeValue = average(tradeValues[historyRange])
            guard averageTradeValue > 0 else {
                continue
            }

            let vwapNumerator = historyRange.reduce(0.0) { partial, cursor in
                partial + closes[cursor] * volumes[cursor]
            }
            let volumeSum = average(volumes[historyRange]) * Double(period)
            guard volumeSum > 0 else {
                continue
            }

            let rollingVWAP = vwapNumerator / volumeSum
            if tradeValues[index] >= averageTradeValue * multiplier, closes[index] > rollingVWAP {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func movingAverageCrossSignals(candles: [Candle], shortPeriod: Int, longPeriod: Int) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        guard closes.count >= longPeriod + 1, shortPeriod < longPeriod else {
            return []
        }

        var indexes: [Int] = []
        for index in longPeriod..<closes.count {
            guard let previousShort = sma(closes, endingAt: index - 1, period: shortPeriod),
                  let previousLong = sma(closes, endingAt: index - 1, period: longPeriod),
                  let currentShort = sma(closes, endingAt: index, period: shortPeriod),
                  let currentLong = sma(closes, endingAt: index, period: longPeriod) else {
                continue
            }
            if previousShort <= previousLong, currentShort > currentLong {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func rsiReboundSignals(candles: [Candle], period: Int, level: Double) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        let values = rsi(closes: closes, period: period)
        guard values.count == closes.count else {
            return []
        }

        var indexes: [Int] = []
        for index in 1..<values.count {
            guard let previous = values[index - 1], let current = values[index] else {
                continue
            }
            if previous < level, current >= level {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func bollingerReboundSignals(candles: [Candle], period: Int, stdDev: Double) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        guard closes.count >= period + 1 else {
            return []
        }

        var indexes: [Int] = []
        for index in period..<closes.count {
            guard let previousBand = lowerBollinger(closes, endingAt: index - 1, period: period, stdDev: stdDev),
                  let currentBand = lowerBollinger(closes, endingAt: index, period: period, stdDev: stdDev) else {
                continue
            }
            if closes[index - 1] < previousBand, closes[index] >= currentBand {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func breakoutSignals(candles: [Candle], lookback: Int) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        guard closes.count >= lookback + 1 else {
            return []
        }

        var indexes: [Int] = []
        for index in lookback..<closes.count {
            let previousHigh = closes[(index - lookback)..<index].max() ?? closes[index]
            if closes[index] > previousHigh {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func macdCrossSignals(candles: [Candle]) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        let macdLine = zip(ema(closes, period: 12), ema(closes, period: 26)).map { fast, slow -> Double? in
            guard let fast, let slow else { return nil }
            return fast - slow
        }
        let signalLine = ema(macdLine.map { $0 ?? 0 }, period: 9)

        var indexes: [Int] = []
        for index in 1..<closes.count {
            guard let previousMacd = macdLine[index - 1],
                  let currentMacd = macdLine[index],
                  let previousSignal = signalLine[index - 1],
                  let currentSignal = signalLine[index] else {
                continue
            }
            if previousMacd <= previousSignal, currentMacd > currentSignal {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func surgeVolumeMomentumSignals(candles: [Candle], lookback: Int, movePercent: Double, volumeMultiplier: Double) -> [Int] {
        let opens = candles.map { double($0.openValue) }
        let closes = candles.map { double($0.closeValue) }
        let volumes = candles.map { double($0.volumeValue) }
        guard lookback > 1, closes.count >= lookback + 1 else {
            return []
        }

        var indexes: [Int] = []
        for index in lookback..<closes.count {
            let previous = closes[index - 1]
            guard previous > 0 else {
                continue
            }

            let move = ((closes[index] - previous) / previous) * 100
            let averageVolume = average(volumes[(index - lookback)..<index])
            if move >= movePercent, closes[index] >= opens[index], volumes[index] >= averageVolume * volumeMultiplier {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func plungeReboundSignals(candles: [Candle], lookback: Int, movePercent: Double, volumeMultiplier: Double) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        let volumes = candles.map { double($0.volumeValue) }
        guard lookback >= 3, closes.count >= lookback + 1 else {
            return []
        }

        var indexes: [Int] = []
        for index in max(lookback, 2)..<closes.count {
            let beforeDrop = closes[index - 2]
            let dropped = closes[index - 1]
            let current = closes[index]
            guard beforeDrop > 0, dropped > 0 else {
                continue
            }

            let drop = ((dropped - beforeDrop) / beforeDrop) * 100
            let rebound = ((current - dropped) / dropped) * 100
            let averageVolume = average(volumes[(index - lookback)..<index])
            if drop <= -movePercent, rebound > 0, volumes[index] <= averageVolume * volumeMultiplier {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func tradeValueFocusSignals(candles: [Candle], lookback: Int, valueMultiplier: Double) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        let tradeValues = candles.map { double($0.closeValue) * double($0.volumeValue) }
        guard lookback > 1, closes.count >= lookback + 1 else {
            return []
        }

        var indexes: [Int] = []
        for index in lookback..<closes.count {
            let averageValue = average(tradeValues[(index - lookback)..<index])
            if tradeValues[index] >= averageValue * valueMultiplier, closes[index] >= closes[index - 1] {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func rangeSwingReboundSignals(candles: [Candle], lookback: Int, swingPercent: Double) -> [Int] {
        let highs = candles.map { double($0.highValue) }
        let lows = candles.map { double($0.lowValue) }
        let closes = candles.map { double($0.closeValue) }
        guard lookback >= 5, closes.count >= lookback + 1 else {
            return []
        }

        var indexes: [Int] = []
        for index in lookback..<closes.count {
            let high = highs[(index - lookback)..<index].max() ?? highs[index]
            let low = lows[(index - lookback)..<index].min() ?? lows[index]
            guard low > 0 else {
                continue
            }

            let rangePercent = ((high - low) / low) * 100
            let lowerZone = low + (high - low) * 0.35
            let isTargetRange = rangePercent >= swingPercent * 1.4 && rangePercent <= swingPercent * 3.2
            if isTargetRange, closes[index - 1] <= lowerZone, closes[index] > closes[index - 1] {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func rangeUpperWarningSignals(candles: [Candle], lookback: Int, swingPercent: Double) -> [Int] {
        let highs = candles.map { double($0.highValue) }
        let lows = candles.map { double($0.lowValue) }
        let closes = candles.map { double($0.closeValue) }
        guard lookback >= 5, closes.count >= lookback + 1 else {
            return []
        }

        var indexes: [Int] = []
        for index in lookback..<closes.count {
            let high = highs[(index - lookback)..<index].max() ?? highs[index]
            let low = lows[(index - lookback)..<index].min() ?? lows[index]
            guard low > 0 else {
                continue
            }

            let rangePercent = ((high - low) / low) * 100
            let upperZone = low + (high - low) * 0.72
            let isTargetRange = rangePercent >= swingPercent * 1.4 && rangePercent <= swingPercent * 3.2
            if isTargetRange, closes[index - 1] < upperZone, closes[index] >= upperZone {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func semiconductorValueBreakoutSignals(candles: [Candle], lookback: Int, volumeMultiplier: Double) -> [Int] {
        let highs = candles.map { double($0.highValue) }
        let closes = candles.map { double($0.closeValue) }
        let volumes = candles.map { double($0.volumeValue) }
        guard lookback > 1, closes.count >= lookback + 1 else {
            return []
        }

        var indexes: [Int] = []
        for index in lookback..<closes.count {
            let previousHigh = highs[(index - lookback)..<index].max() ?? highs[index]
            let averageVolume = volumes[(index - lookback)..<index].reduce(0, +) / Double(lookback)
            if closes[index] > previousHigh, volumes[index] >= averageVolume * volumeMultiplier {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func semiconductorDipStabilizeSignals(candles: [Candle], lookback: Int) -> [Int] {
        let closes = candles.map { double($0.closeValue) }
        let volumes = candles.map { double($0.volumeValue) }
        guard lookback >= 3, closes.count >= lookback + 1 else {
            return []
        }

        var indexes: [Int] = []
        for index in lookback..<closes.count {
            let start = closes[index - lookback]
            let previous = closes[index - 1]
            let current = closes[index]
            guard start > 0, previous > 0 else {
                continue
            }

            let dropRate = ((previous - start) / start) * 100
            let reboundRate = ((current - previous) / previous) * 100
            let averageVolume = volumes[(index - lookback)..<index].reduce(0, +) / Double(lookback)

            if dropRate <= -3, reboundRate > 0, volumes[index] <= averageVolume * 1.4 {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func semiconductorTrendRestartSignals(candles: [Candle], shortPeriod: Int, longPeriod: Int, lookback: Int) -> [Int] {
        let highs = candles.map { double($0.highValue) }
        let closes = candles.map { double($0.closeValue) }
        guard shortPeriod < longPeriod, lookback > 1, closes.count >= max(longPeriod, lookback) + 1 else {
            return []
        }

        var indexes: [Int] = []
        for index in max(longPeriod, lookback)..<closes.count {
            guard let currentShort = sma(closes, endingAt: index, period: shortPeriod),
                  let currentLong = sma(closes, endingAt: index, period: longPeriod) else {
                continue
            }

            let previousHigh = highs[(index - lookback)..<index].max() ?? highs[index]
            if currentShort > currentLong, closes[index] > previousHigh, closes[index] > closes[index - 1] {
                indexes.append(index)
            }
        }
        return indexes
    }

    private static func sma(_ values: [Double], endingAt index: Int, period: Int) -> Double? {
        guard period > 0, index >= period - 1, index < values.count else {
            return nil
        }
        let slice = values[(index - period + 1)...index]
        return slice.reduce(0, +) / Double(period)
    }

    private static func average(_ values: ArraySlice<Double>) -> Double {
        guard !values.isEmpty else {
            return 0
        }
        return values.reduce(0, +) / Double(values.count)
    }

    private static func ema(_ values: [Double], period: Int) -> [Double?] {
        guard period > 0, !values.isEmpty else {
            return []
        }

        let multiplier = 2.0 / Double(period + 1)
        var result = Array<Double?>(repeating: nil, count: values.count)
        var current: Double?
        for index in values.indices {
            if index == period - 1 {
                current = values[0...index].reduce(0, +) / Double(period)
            } else if let previous = current, index >= period {
                current = (values[index] - previous) * multiplier + previous
            }
            result[index] = current
        }
        return result
    }

    private static func rsi(closes: [Double], period: Int) -> [Double?] {
        guard closes.count > period, period > 0 else {
            return Array(repeating: nil, count: closes.count)
        }

        var values = Array<Double?>(repeating: nil, count: closes.count)
        for index in period..<closes.count {
            var gains = 0.0
            var losses = 0.0
            for inner in (index - period + 1)...index {
                let change = closes[inner] - closes[inner - 1]
                if change >= 0 {
                    gains += change
                } else {
                    losses += abs(change)
                }
            }
            if losses == 0 {
                values[index] = 100
            } else {
                let relativeStrength = gains / losses
                values[index] = 100 - (100 / (1 + relativeStrength))
            }
        }
        return values
    }

    private static func lowerBollinger(_ values: [Double], endingAt index: Int, period: Int, stdDev: Double) -> Double? {
        bollingerBand(values, endingAt: index, period: period, stdDev: stdDev)?.lower
    }

    private static func bollingerBand(_ values: [Double], endingAt index: Int, period: Int, stdDev: Double) -> (lower: Double, middle: Double, upper: Double)? {
        guard let average = sma(values, endingAt: index, period: period) else {
            return nil
        }
        let slice = values[(index - period + 1)...index]
        let variance = slice.reduce(0) { partial, value in
            partial + pow(value - average, 2)
        } / Double(period)
        let width = sqrt(variance) * stdDev
        return (average - width, average, average + width)
    }

    private static func double(_ value: Decimal) -> Double {
        NSDecimalNumber(decimal: value).doubleValue
    }
}
