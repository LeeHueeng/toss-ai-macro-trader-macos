import Foundation

private struct YahooScreenerResponse: Decodable {
    let finance: YahooFinanceEnvelope
}

private struct YahooFinanceEnvelope: Decodable {
    let result: [YahooScreenerResult]?
}

private struct YahooScreenerResult: Decodable {
    let quotes: [YahooQuote]?
}

private struct YahooQuote: Decodable {
    let symbol: String?
    let shortName: String?
    let longName: String?
    let regularMarketPrice: Double?
    let regularMarketChange: Double?
    let regularMarketChangePercent: Double?
    let regularMarketVolume: Int64?
    let marketCap: Int64?
    let exchange: String?
    let fullExchangeName: String?
    let quoteType: String?
    let currency: String?
}

private struct YahooSearchResponse: Decodable {
    let quotes: [YahooSearchQuote]?
}

private struct YahooSearchQuote: Decodable {
    let symbol: String?
    let shortname: String?
    let longname: String?
    let exchange: String?
    let exchDisp: String?
    let quoteType: String?
}

private struct YahooChartResponse: Decodable {
    let chart: YahooChartEnvelope
}

private struct YahooChartEnvelope: Decodable {
    let result: [YahooChartResult]?
}

private struct YahooChartResult: Decodable {
    let meta: YahooChartMeta
    let timestamp: [Int]?
    let indicators: YahooChartIndicators
}

private struct YahooChartMeta: Decodable {
    let currency: String?
    let symbol: String?
    let exchangeName: String?
    let fullExchangeName: String?
    let instrumentType: String?
    let regularMarketPrice: Double?
    let regularMarketVolume: Int64?
    let longName: String?
    let shortName: String?
}

private struct YahooChartIndicators: Decodable {
    let quote: [YahooChartQuote]?
}

private struct YahooChartQuote: Decodable {
    let close: [Double?]?
    let volume: [Int64?]?
}

private struct YahooKnownStock {
    let symbol: String
    let name: String
    let englishName: String
    let market: String
    let aliases: [String]
}

struct YahooFinanceClient {
    private let decoder = JSONDecoder()
    private let semiconductorUniverse: [YahooKnownStock] = [
        YahooKnownStock(symbol: "NVDA", name: "엔비디아", englishName: "NVIDIA", market: "NASDAQ", aliases: ["nvidia", "gpu", "ai semiconductor"]),
        YahooKnownStock(symbol: "AMD", name: "AMD", englishName: "Advanced Micro Devices", market: "NASDAQ", aliases: ["advanced micro devices", "cpu", "gpu"]),
        YahooKnownStock(symbol: "AVGO", name: "브로드컴", englishName: "Broadcom", market: "NASDAQ", aliases: ["broadcom", "network chip"]),
        YahooKnownStock(symbol: "TSM", name: "TSMC", englishName: "Taiwan Semiconductor", market: "NYSE", aliases: ["taiwan semiconductor", "foundry", "파운드리"]),
        YahooKnownStock(symbol: "ASML", name: "ASML", englishName: "ASML Holding", market: "NASDAQ", aliases: ["euv", "semiconductor equipment", "노광"]),
        YahooKnownStock(symbol: "AMAT", name: "어플라이드 머티어리얼즈", englishName: "Applied Materials", market: "NASDAQ", aliases: ["applied materials", "semiconductor equipment", "장비"]),
        YahooKnownStock(symbol: "LRCX", name: "램리서치", englishName: "Lam Research", market: "NASDAQ", aliases: ["lam research", "etch", "반도체 장비"]),
        YahooKnownStock(symbol: "KLAC", name: "KLA", englishName: "KLA Corporation", market: "NASDAQ", aliases: ["kla", "inspection", "metrology"]),
        YahooKnownStock(symbol: "MU", name: "마이크론", englishName: "Micron Technology", market: "NASDAQ", aliases: ["micron", "memory", "dram", "nand"]),
        YahooKnownStock(symbol: "INTC", name: "인텔", englishName: "Intel", market: "NASDAQ", aliases: ["intel", "cpu", "foundry"]),
        YahooKnownStock(symbol: "QCOM", name: "퀄컴", englishName: "Qualcomm", market: "NASDAQ", aliases: ["qualcomm", "mobile chip"]),
        YahooKnownStock(symbol: "ARM", name: "ARM", englishName: "Arm Holdings", market: "NASDAQ", aliases: ["arm holdings", "chip ip"]),
        YahooKnownStock(symbol: "MRVL", name: "마벨", englishName: "Marvell Technology", market: "NASDAQ", aliases: ["marvell", "data center chip"]),
        YahooKnownStock(symbol: "ON", name: "온세미", englishName: "ON Semiconductor", market: "NASDAQ", aliases: ["onsemi", "power semiconductor"]),
        YahooKnownStock(symbol: "NXPI", name: "NXP", englishName: "NXP Semiconductors", market: "NASDAQ", aliases: ["nxp", "automotive chip"]),
        YahooKnownStock(symbol: "MCHP", name: "마이크로칩", englishName: "Microchip Technology", market: "NASDAQ", aliases: ["microchip", "mcu"]),
        YahooKnownStock(symbol: "TXN", name: "텍사스 인스트루먼트", englishName: "Texas Instruments", market: "NASDAQ", aliases: ["texas instruments", "analog chip"]),
        YahooKnownStock(symbol: "ADI", name: "아날로그 디바이시스", englishName: "Analog Devices", market: "NASDAQ", aliases: ["analog devices", "analog chip"]),
        YahooKnownStock(symbol: "MPWR", name: "모놀리식 파워", englishName: "Monolithic Power Systems", market: "NASDAQ", aliases: ["monolithic power", "power management"]),
        YahooKnownStock(symbol: "GFS", name: "글로벌파운드리스", englishName: "GlobalFoundries", market: "NASDAQ", aliases: ["globalfoundries", "foundry"]),
        YahooKnownStock(symbol: "UMC", name: "UMC", englishName: "United Microelectronics", market: "NYSE", aliases: ["united microelectronics", "foundry"]),
        YahooKnownStock(symbol: "AMKR", name: "앰코", englishName: "Amkor Technology", market: "NASDAQ", aliases: ["amkor", "packaging", "후공정"]),
        YahooKnownStock(symbol: "COHR", name: "코히런트", englishName: "Coherent", market: "NYSE", aliases: ["coherent", "silicon carbide", "optical"]),
        YahooKnownStock(symbol: "ACMR", name: "ACM 리서치", englishName: "ACM Research", market: "NASDAQ", aliases: ["acm research", "semiconductor equipment"])
    ]

    func marketActivityRanking(limit: Int = 160) async throws -> [MarketActivitySnapshot] {
        let screeners = ["most_actives", "day_gainers", "day_losers"]
        var rows: [MarketActivitySnapshot] = []

        for screener in screeners {
            rows.append(contentsOf: try await fetchScreener(id: screener, count: max(50, limit / screeners.count + 20)))
        }
        rows.append(contentsOf: await fetchKnownStocks(semiconductorUniverse))

        return Array(
            rows
                .reduce(into: [String: MarketActivitySnapshot]()) { partial, row in
                    let key = row.symbol.uppercased()
                    if partial[key] == nil {
                        partial[key] = row
                    }
                }
                .values
                .sorted { left, right in
                    let leftValue = NSDecimalNumber(decimal: left.tradeValue ?? 0).doubleValue
                    let rightValue = NSDecimalNumber(decimal: right.tradeValue ?? 0).doubleValue
                    if leftValue == rightValue {
                        return abs(left.changePercent ?? 0) > abs(right.changePercent ?? 0)
                    }
                    return leftValue > rightValue
                }
                .prefix(limit)
        )
    }

    func search(query: String, limit: Int = 8) async throws -> [StockSearchItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return []
        }

        var components = URLComponents(string: "https://query1.finance.yahoo.com/v1/finance/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: trimmed),
            URLQueryItem(name: "quotesCount", value: "\(limit)"),
            URLQueryItem(name: "newsCount", value: "0")
        ]
        guard let url = components?.url else {
            throw TossInvestClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 6
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.setValue("https://finance.yahoo.com/", forHTTPHeaderField: "Referer")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw TossInvestClientError.httpStatus(0, "Yahoo Finance 검색 응답을 받지 못했습니다.")
        }

        let decoded = try decoder.decode(YahooSearchResponse.self, from: data)
        return Array((decoded.quotes ?? []).compactMap(stockSearchItem(from:)).prefix(limit))
    }

    private func fetchScreener(id: String, count: Int) async throws -> [MarketActivitySnapshot] {
        var components = URLComponents(string: "https://query1.finance.yahoo.com/v1/finance/screener/predefined/saved")
        components?.queryItems = [
            URLQueryItem(name: "scrIds", value: id),
            URLQueryItem(name: "count", value: "\(count)")
        ]
        guard let url = components?.url else {
            throw TossInvestClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 8
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.setValue("https://finance.yahoo.com/", forHTTPHeaderField: "Referer")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw TossInvestClientError.httpStatus(0, "Yahoo Finance 공개 스크리너 응답을 받지 못했습니다.")
        }

        let decoded = try decoder.decode(YahooScreenerResponse.self, from: data)
        return decoded.finance.result?.flatMap { result in
            result.quotes?.compactMap(snapshot(from:)) ?? []
        } ?? []
    }

    private func fetchKnownStocks(_ stocks: [YahooKnownStock]) async -> [MarketActivitySnapshot] {
        await withTaskGroup(of: MarketActivitySnapshot?.self) { group in
            for stock in stocks {
                group.addTask {
                    try? await fetchChartSnapshot(for: stock)
                }
            }

            var snapshots: [MarketActivitySnapshot] = []
            for await snapshot in group {
                if let snapshot {
                    snapshots.append(snapshot)
                }
            }
            return snapshots
        }
    }

    private func fetchChartSnapshot(for stock: YahooKnownStock) async throws -> MarketActivitySnapshot {
        var components = URLComponents(string: "https://query1.finance.yahoo.com/v8/finance/chart/\(stock.symbol)")
        components?.queryItems = [
            URLQueryItem(name: "range", value: "5d"),
            URLQueryItem(name: "interval", value: "1d")
        ]
        guard let url = components?.url else {
            throw TossInvestClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 6
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.setValue("https://finance.yahoo.com/", forHTTPHeaderField: "Referer")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw TossInvestClientError.httpStatus(0, "Yahoo Finance 차트 응답을 받지 못했습니다.")
        }

        let decoded = try decoder.decode(YahooChartResponse.self, from: data)
        guard let result = decoded.chart.result?.first,
              result.meta.instrumentType?.uppercased() == "EQUITY",
              let price = result.meta.regularMarketPrice,
              price > 0 else {
            throw TossInvestClientError.httpStatus(0, "Yahoo Finance 차트 가격을 읽지 못했습니다.")
        }

        let closes = result.indicators.quote?.first?.close?.compactMap { $0 } ?? []
        let previousClose = closes.dropLast().last
        let change = previousClose.map { price - $0 }
        let changePercent = previousClose.flatMap { previous -> Double? in
            guard previous > 0 else {
                return nil
            }
            return (price - previous) / previous * 100
        }
        let chartVolume = result.indicators.quote?.first?.volume?.compactMap { $0 }.last
        let volume = result.meta.regularMarketVolume ?? chartVolume
        let currency = result.meta.currency ?? "USD"

        return MarketActivitySnapshot(
            symbol: stock.symbol,
            name: stock.name,
            englishName: result.meta.longName ?? result.meta.shortName ?? stock.englishName,
            market: result.meta.fullExchangeName ?? result.meta.exchangeName ?? stock.market,
            currency: currency,
            lastPrice: formattedYahooPrice(price, currency: currency),
            timestamp: nil,
            tradeVolume: volume.map { Decimal($0) },
            tradeValue: volume.map { Decimal(price) * Decimal($0) },
            tradeSampleCount: 0,
            updatedAt: Date(),
            priceChange: change.map { Decimal($0) },
            changePercent: changePercent
        )
    }

    private func snapshot(from quote: YahooQuote) -> MarketActivitySnapshot? {
        guard let rawSymbol = quote.symbol?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawSymbol.isEmpty,
              let price = quote.regularMarketPrice,
              price > 0 else {
            return nil
        }

        let quoteType = quote.quoteType?.uppercased()
        guard quoteType == nil || quoteType == "EQUITY" || quoteType == "ETF" else {
            return nil
        }

        let volume = quote.regularMarketVolume.map { Decimal($0) }
        let tradeValue = volume.map { Decimal(price) * $0 }
        let name = quote.shortName ?? quote.longName ?? rawSymbol
        let currency = quote.currency ?? "USD"

        return MarketActivitySnapshot(
            symbol: rawSymbol.uppercased(),
            name: koreanDisplayName(for: rawSymbol, fallback: name),
            englishName: quote.longName ?? name,
            market: quote.fullExchangeName ?? quote.exchange ?? "US",
            currency: currency,
            lastPrice: formattedYahooPrice(price, currency: currency),
            timestamp: nil,
            tradeVolume: volume,
            tradeValue: tradeValue,
            tradeSampleCount: 0,
            updatedAt: Date(),
            priceChange: quote.regularMarketChange.map { Decimal($0) },
            changePercent: quote.regularMarketChangePercent
        )
    }

    private func stockSearchItem(from quote: YahooSearchQuote) -> StockSearchItem? {
        guard let rawSymbol = quote.symbol?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawSymbol.isEmpty else {
            return nil
        }

        let quoteType = quote.quoteType?.uppercased()
        guard quoteType == nil || quoteType == "EQUITY" || quoteType == "ETF" else {
            return nil
        }

        let normalized = normalizedSearchSymbol(rawSymbol)
        let name = quote.shortname ?? quote.longname ?? normalized.symbol
        return StockSearchItem(
            symbol: normalized.symbol,
            name: koreanDisplayName(for: normalized.symbol, fallback: name),
            englishName: quote.longname ?? name,
            market: normalized.market ?? quote.exchDisp ?? quote.exchange ?? "US",
            currency: normalized.currency ?? "USD",
            aliases: [rawSymbol, name, quote.longname ?? ""].filter { !$0.isEmpty }
        )
    }

    private func normalizedSearchSymbol(_ rawSymbol: String) -> (symbol: String, market: String?, currency: String?) {
        let uppercased = rawSymbol.uppercased()
        if uppercased.hasSuffix(".KS") || uppercased.hasSuffix(".KQ") {
            let symbol = String(uppercased.prefix(6))
            let market = uppercased.hasSuffix(".KQ") ? "KOSDAQ" : "KOSPI"
            return (symbol, market, "KRW")
        }
        return (uppercased, nil, nil)
    }

    private func koreanDisplayName(for symbol: String, fallback: String) -> String {
        switch symbol.uppercased() {
        case "AAPL": "애플"
        case "MSFT": "마이크로소프트"
        case "NVDA": "엔비디아"
        case "TSLA": "테슬라"
        case "GOOGL", "GOOG": "알파벳"
        case "AMZN": "아마존"
        case "META": "메타"
        case "NFLX": "넷플릭스"
        case "AMD": "AMD"
        case "AVGO": "브로드컴"
        case "TSM": "TSMC"
        case "ASML": "ASML"
        case "AMAT": "어플라이드 머티어리얼즈"
        case "LRCX": "램리서치"
        case "KLAC": "KLA"
        case "MU": "마이크론"
        case "INTC": "인텔"
        case "QCOM": "퀄컴"
        case "ARM": "ARM"
        case "MRVL": "마벨"
        case "ON": "온세미"
        case "NXPI": "NXP"
        case "MCHP": "마이크로칩"
        case "TXN": "텍사스 인스트루먼트"
        case "ADI": "아날로그 디바이시스"
        case "MPWR": "모놀리식 파워"
        case "GFS": "글로벌파운드리스"
        case "UMC": "UMC"
        case "AMKR": "앰코"
        case "COHR": "코히런트"
        case "ACMR": "ACM 리서치"
        case "PLTR": "팔란티어"
        case "SPY": "SPDR S&P 500 ETF"
        case "QQQ": "Invesco QQQ ETF"
        default: fallback
        }
    }

    private func formattedYahooPrice(_ value: Double, currency: String) -> String {
        if currency.uppercased() == "KRW" {
            return String(format: "%.0f", value)
        }
        return String(format: "%.2f", value)
    }
}
