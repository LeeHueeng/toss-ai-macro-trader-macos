import Foundation

private struct NextradeMarketInfoResponse: Decodable {
    let aggDd: String?
    let creTime: String?
    let txBrdinfoTimeTbVOTopList: [NextradeTopStock]
}

private struct NextradeTopStock: Decodable {
    let mktNm: String?
    let isuAbwdNm: String
    let isuEnawNm: String?
    let nowDd: String?
    let nowTime: String?
    let curPrc: Decimal
    let accTdQty: Decimal
    let accTrval: Decimal
}

struct NextradeMarketRankingClient {
    private let mainURL = URL(string: "https://www.nextrade.co.kr/main.do")!
    private let refreshURL = URL(string: "https://www.nextrade.co.kr/refreshMarketInfo.do")!
    private let decoder = JSONDecoder()

    func tradeValueRanking(stockDirectory: [StockSearchItem]) async throws -> [MarketActivitySnapshot] {
        do {
            let response = try await fetchRefreshJSON()
            let snapshots = response.txBrdinfoTimeTbVOTopList.enumerated().map { index, row in
                snapshot(
                    rank: index + 1,
                    name: row.isuAbwdNm,
                    englishName: row.isuEnawNm,
                    market: row.mktNm,
                    price: row.curPrc,
                    volume: row.accTdQty,
                    tradeValue: row.accTrval,
                    date: row.nowDd ?? response.aggDd,
                    time: row.nowTime ?? response.creTime,
                    stockDirectory: stockDirectory
                )
            }
            if !snapshots.isEmpty {
                return snapshots
            }
        } catch {
            // Fall through to the server-rendered HTML table. The public site has
            // kept both surfaces, so this gives us a cheap schema-change fallback.
        }

        return try await fetchHTMLTable(stockDirectory: stockDirectory)
    }

    private func fetchRefreshJSON() async throws -> NextradeMarketInfoResponse {
        var request = URLRequest(url: refreshURL)
        request.httpMethod = "POST"
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.setValue("https://www.nextrade.co.kr/main.do", forHTTPHeaderField: "Referer")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "scLanguageSe=kor".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw TossInvestClientError.httpStatus(0, "NXT 거래대금 JSON 응답을 받지 못했습니다")
        }
        return try decoder.decode(NextradeMarketInfoResponse.self, from: data)
    }

    private func fetchHTMLTable(stockDirectory: [StockSearchItem]) async throws -> [MarketActivitySnapshot] {
        var request = URLRequest(url: mainURL)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        request.setValue("https://www.nextrade.co.kr/main.do", forHTTPHeaderField: "Referer")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode),
              let html = String(data: data, encoding: .utf8) else {
            throw TossInvestClientError.httpStatus(0, "NXT 거래대금 HTML 응답을 읽지 못했습니다")
        }

        guard let tableBody = firstMatch(
            in: html,
            pattern: #"<tbody\s+id=\"topListTbody\">([\s\S]*?)</tbody>"#
        ) else {
            return []
        }

        return matches(in: tableBody, pattern: #"<tr[\s\S]*?</tr>"#).enumerated().compactMap { index, rowHTML in
            let columns = matches(in: rowHTML, pattern: #"<span[^>]*>([\s\S]*?)</span>"#)
                .map(cleanHTMLText)
            guard columns.count >= 7 else {
                return nil
            }
            return snapshot(
                rank: index + 1,
                name: columns[0],
                englishName: nil,
                market: columns[1],
                price: numericDecimal(columns[2]),
                volume: numericDecimal(columns[5]),
                tradeValue: numericDecimal(columns[6]),
                date: nil,
                time: nil,
                stockDirectory: stockDirectory
            )
        }
    }

    private func snapshot(
        rank: Int,
        name: String,
        englishName: String?,
        market: String?,
        price: Decimal,
        volume: Decimal,
        tradeValue: Decimal,
        date: String?,
        time: String?,
        stockDirectory: [StockSearchItem]
    ) -> MarketActivitySnapshot {
        let item = stockItem(name: name, stockDirectory: stockDirectory)
        let symbol = item?.symbol ?? Self.fallbackSymbolsByName[name] ?? "NXT-\(rank)"
        let displayMarket = item?.market ?? market ?? "NXT"
        let displayEnglishName = item?.englishName ?? englishName ?? name
        let timestamp = timestampText(date: date, time: time)

        return MarketActivitySnapshot(
            symbol: symbol,
            name: item?.name ?? name,
            englishName: displayEnglishName,
            market: displayMarket,
            currency: "KRW",
            lastPrice: NSDecimalNumber(decimal: price).stringValue,
            timestamp: timestamp,
            tradeVolume: volume,
            tradeValue: tradeValue,
            tradeSampleCount: 0,
            updatedAt: Date()
        )
    }

    private func stockItem(name: String, stockDirectory: [StockSearchItem]) -> StockSearchItem? {
        let normalizedName = normalized(name)
        return stockDirectory.first { item in
            normalized(item.name) == normalizedName ||
            normalized(item.englishName) == normalizedName ||
            item.aliases.contains { normalized($0) == normalizedName }
        }
    }

    private func timestampText(date: String?, time: String?) -> String? {
        guard let date, date.count == 8 else {
            return nil
        }
        let year = date.prefix(4)
        let month = date.dropFirst(4).prefix(2)
        let day = date.suffix(2)

        guard let time, time.count >= 4 else {
            return "\(year)-\(month)-\(day)"
        }
        let hour = time.prefix(2)
        let minute = time.dropFirst(2).prefix(2)
        return "\(year)-\(month)-\(day) \(hour):\(minute)"
    }

    private func normalized(_ value: String) -> String {
        value
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .lowercased()
    }

    private func numericDecimal(_ value: String) -> Decimal {
        decimalValue(value.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "%", with: ""))
    }

    private func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              match.numberOfRanges > 1,
              let matchRange = Range(match.range(at: 1), in: text) else {
            return nil
        }
        return String(text[matchRange])
    }

    private func matches(in text: String, pattern: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            let captureIndex = match.numberOfRanges > 1 ? 1 : 0
            guard let matchRange = Range(match.range(at: captureIndex), in: text) else {
                return nil
            }
            return String(text[matchRange])
        }
    }

    private func cleanHTMLText(_ value: String) -> String {
        value
            .replacingOccurrences(of: #"<[^>]+>"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private static let fallbackSymbolsByName: [String: String] = [
        "삼성전자": "005930",
        "SK하이닉스": "000660",
        "삼성전기": "009150",
        "현대차": "005380",
        "SK스퀘어": "402340",
        "한미반도체": "042700",
        "LG이노텍": "011070",
        "LS ELECTRIC": "010120",
        "LG전자": "066570"
    ]
}
