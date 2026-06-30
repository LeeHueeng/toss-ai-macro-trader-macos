import Foundation

private struct NaverMarketValueResponse: Decodable {
    let stocks: [NaverMarketStock]
    let totalCount: Int?
    let page: Int?
    let pageSize: Int?
    let localOpenTimeDesc: String?
    let marketStatus: String?
}

private struct NaverMarketStock: Decodable {
    let itemCode: String
    let stockName: String
    let stockEndType: String?
    let closePrice: String
    let compareToPreviousClosePrice: String?
    let compareToPreviousPrice: NaverCompareToPreviousPrice?
    let fluctuationsRatio: String?
    let accumulatedTradingVolume: String
    let accumulatedTradingValue: String
    let accumulatedTradingValueKrwHangeul: String?
    let localTradedAt: String?
    let stockExchangeType: NaverStockExchangeType?
}

private struct NaverCompareToPreviousPrice: Decodable {
    let name: String?
}

private struct NaverStockExchangeType: Decodable {
    let nameKor: String?
    let nameEng: String?
}

struct NaverMarketRankingClient {
    private let baseURL = URL(string: "https://m.stock.naver.com/api/stocks/marketValue")!
    private let decoder = JSONDecoder()

    func tradeValueRanking(limit: Int = 150, maxPagesPerCategory: Int? = nil) async throws -> [MarketActivitySnapshot] {
        var snapshots: [MarketActivitySnapshot] = []
        for category in ["KOSPI", "KOSDAQ"] {
            snapshots.append(contentsOf: try await fetchCategory(category, maxPages: maxPagesPerCategory))
        }

        return Array(
            snapshots
                .filter { ($0.tradeValue ?? 0) > 0 }
                .sorted { ($0.tradeValue ?? 0) > ($1.tradeValue ?? 0) }
                .prefix(limit)
        )
    }

    private func fetchCategory(_ category: String, maxPages: Int?) async throws -> [MarketActivitySnapshot] {
        let pageSize = 100
        var page = 1
        var totalCount: Int?
        var snapshots: [MarketActivitySnapshot] = []

        while true {
            let response = try await fetchPage(category: category, page: page, pageSize: pageSize)
            totalCount = totalCount ?? response.totalCount

            let pageSnapshots = response.stocks.compactMap { stock -> MarketActivitySnapshot? in
                // Keep the automatic macro list focused on listed stocks first.
                // ETFs/ETNs can be added later with a separate risk warning.
                if let type = stock.stockEndType, type.lowercased() != "stock" {
                    return nil
                }

                let tradeValue = numericDecimal(stock.accumulatedTradingValue) * Decimal(1_000_000)
                let lastPrice = numericDecimal(stock.closePrice)
                let sign = stock.compareToPreviousPrice?.name == "FALLING" ? -1.0 : 1.0
                let priceChange = stock.compareToPreviousClosePrice.map { Decimal(sign) * numericDecimal($0) }
                let changePercent = stock.fluctuationsRatio.map { sign * numericDouble($0) }
                return MarketActivitySnapshot(
                    symbol: stock.itemCode,
                    name: stock.stockName,
                    englishName: stock.stockName,
                    market: stock.stockExchangeType?.nameEng ?? category,
                    currency: "KRW",
                    lastPrice: NSDecimalNumber(decimal: lastPrice).stringValue,
                    timestamp: stock.localTradedAt ?? response.localOpenTimeDesc,
                    tradeVolume: numericDecimal(stock.accumulatedTradingVolume),
                    tradeValue: tradeValue,
                    tradeSampleCount: 0,
                    updatedAt: Date(),
                    priceChange: priceChange,
                    changePercent: changePercent
                )
            }

            snapshots.append(contentsOf: pageSnapshots)

            let loadedCount = page * pageSize
            if response.stocks.isEmpty || response.stocks.count < pageSize {
                break
            }
            if let totalCount, loadedCount >= totalCount {
                break
            }
            if let maxPages, page >= maxPages {
                break
            }

            page += 1
        }

        return snapshots
    }

    private func fetchPage(category: String, page: Int, pageSize: Int) async throws -> NaverMarketValueResponse {
        var components = URLComponents(url: baseURL.appending(path: category), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "pageSize", value: "\(pageSize)")
        ]
        guard let url = components?.url else {
            throw TossInvestClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.setValue("https://m.stock.naver.com/", forHTTPHeaderField: "Referer")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw TossInvestClientError.httpStatus(0, "네이버 공개 시세 응답을 받지 못했습니다")
        }

        return try decoder.decode(NaverMarketValueResponse.self, from: data)
    }

    private func numericDecimal(_ value: String) -> Decimal {
        decimalValue(
            value
                .replacingOccurrences(of: ",", with: "")
                .replacingOccurrences(of: "N/A", with: "0")
        )
    }

    private func numericDouble(_ value: String) -> Double {
        NSDecimalNumber(decimal: numericDecimal(value)).doubleValue
    }
}
