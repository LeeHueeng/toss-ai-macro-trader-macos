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

struct YahooFinanceClient {
    private let decoder = JSONDecoder()

    func marketActivityRanking(limit: Int = 160) async throws -> [MarketActivitySnapshot] {
        let screeners = ["most_actives", "day_gainers", "day_losers"]
        var rows: [MarketActivitySnapshot] = []

        for screener in screeners {
            rows.append(contentsOf: try await fetchScreener(id: screener, count: max(50, limit / screeners.count + 20)))
        }

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
