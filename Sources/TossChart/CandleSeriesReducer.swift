import Foundation

enum CandleSeriesReducer {
    static func bucketedOHLC(_ candles: [Candle], maxCount: Int) -> [Candle] {
        guard maxCount > 0, candles.count > maxCount else {
            return candles
        }

        let bucketSize = max(1, Int(ceil(Double(candles.count) / Double(maxCount))))
        var result: [Candle] = []
        result.reserveCapacity(maxCount + 1)

        var index = 0
        while index < candles.count {
            let endIndex = min(candles.count, index + bucketSize)
            let bucket = candles[index..<endIndex]
            guard let first = bucket.first, let last = bucket.last else {
                index = endIndex
                continue
            }

            let high = bucket.map(\.highValue).max() ?? first.highValue
            let low = bucket.map(\.lowValue).min() ?? first.lowValue
            let volume = bucket.reduce(Decimal(0)) { partialResult, candle in
                partialResult + candle.volumeValue
            }

            result.append(
                Candle(
                    timestamp: last.timestamp,
                    openPrice: first.openPrice,
                    highPrice: formattedDecimal(high, fractionDigits: 4),
                    lowPrice: formattedDecimal(low, fractionDigits: 4),
                    closePrice: last.closePrice,
                    volume: formattedDecimal(volume, fractionDigits: 0),
                    currency: last.currency
                )
            )
            index = endIndex
        }

        return result
    }

    static func sampledLine(_ candles: [Candle], maxCount: Int) -> [Candle] {
        guard maxCount > 1, candles.count > maxCount else {
            return candles
        }

        let step = Double(candles.count - 1) / Double(maxCount - 1)
        var result: [Candle] = []
        result.reserveCapacity(maxCount)
        var previousIndex = -1

        for sampleIndex in 0..<maxCount {
            let sourceIndex = min(candles.count - 1, Int(round(Double(sampleIndex) * step)))
            guard sourceIndex != previousIndex else {
                continue
            }
            result.append(candles[sourceIndex])
            previousIndex = sourceIndex
        }

        return result
    }
}
