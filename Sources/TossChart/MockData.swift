import Foundation

enum MockData {
    static var stockDirectory: [StockSearchItem] {
        [
            StockSearchItem(symbol: "005930", name: "삼성전자", englishName: "Samsung Electronics", market: "KOSPI", currency: "KRW", aliases: ["삼전", "삼성", "samsung", "samsung elec"]),
            StockSearchItem(symbol: "000660", name: "SK하이닉스", englishName: "SK Hynix", market: "KOSPI", currency: "KRW", aliases: ["하이닉스", "sk hynix", "hynix"]),
            StockSearchItem(symbol: "035420", name: "NAVER", englishName: "NAVER", market: "KOSPI", currency: "KRW", aliases: ["네이버", "naver"]),
            StockSearchItem(symbol: "009150", name: "삼성전기", englishName: "Samsung Electro-Mechanics", market: "KOSPI", currency: "KRW", aliases: ["삼성전기", "semco", "samsung electro"]),
            StockSearchItem(symbol: "035720", name: "카카오", englishName: "Kakao", market: "KOSPI", currency: "KRW", aliases: ["kakao"]),
            StockSearchItem(symbol: "005380", name: "현대차", englishName: "Hyundai Motor", market: "KOSPI", currency: "KRW", aliases: ["현대자동차", "hyundai"]),
            StockSearchItem(symbol: "000270", name: "기아", englishName: "Kia", market: "KOSPI", currency: "KRW", aliases: ["kia"]),
            StockSearchItem(symbol: "402340", name: "SK스퀘어", englishName: "SK Square", market: "KOSPI", currency: "KRW", aliases: ["sk square", "에스케이스퀘어"]),
            StockSearchItem(symbol: "042700", name: "한미반도체", englishName: "Hanmi Semiconductor", market: "KOSPI", currency: "KRW", aliases: ["hanmi semiconductor", "한미"]),
            StockSearchItem(symbol: "011070", name: "LG이노텍", englishName: "LG Innotek", market: "KOSPI", currency: "KRW", aliases: ["엘지이노텍", "lg innotek"]),
            StockSearchItem(symbol: "010120", name: "LS ELECTRIC", englishName: "LS Electric", market: "KOSPI", currency: "KRW", aliases: ["ls electric", "ls일렉트릭", "엘에스일렉트릭"]),
            StockSearchItem(symbol: "066570", name: "LG전자", englishName: "LG Electronics", market: "KOSPI", currency: "KRW", aliases: ["엘지전자", "lg electronics"]),
            StockSearchItem(symbol: "068270", name: "셀트리온", englishName: "Celltrion", market: "KOSPI", currency: "KRW", aliases: ["celltrion"]),
            StockSearchItem(symbol: "373220", name: "LG에너지솔루션", englishName: "LG Energy Solution", market: "KOSPI", currency: "KRW", aliases: ["엘지에너지솔루션", "lg엔솔", "lg energy"]),
            StockSearchItem(symbol: "005490", name: "POSCO홀딩스", englishName: "POSCO Holdings", market: "KOSPI", currency: "KRW", aliases: ["포스코", "posco"]),
            StockSearchItem(symbol: "006400", name: "삼성SDI", englishName: "Samsung SDI", market: "KOSPI", currency: "KRW", aliases: ["sdi", "삼성에스디아이"]),
            StockSearchItem(symbol: "AAPL", name: "애플", englishName: "Apple", market: "NASDAQ", currency: "USD", aliases: ["apple", "아이폰"]),
            StockSearchItem(symbol: "MSFT", name: "마이크로소프트", englishName: "Microsoft", market: "NASDAQ", currency: "USD", aliases: ["microsoft", "ms", "마소"]),
            StockSearchItem(symbol: "NVDA", name: "엔비디아", englishName: "NVIDIA", market: "NASDAQ", currency: "USD", aliases: ["nvidia", "젠슨황"]),
            StockSearchItem(symbol: "TSLA", name: "테슬라", englishName: "Tesla", market: "NASDAQ", currency: "USD", aliases: ["tesla"]),
            StockSearchItem(symbol: "GOOGL", name: "알파벳 A", englishName: "Alphabet A", market: "NASDAQ", currency: "USD", aliases: ["구글", "google", "alphabet"]),
            StockSearchItem(symbol: "AMZN", name: "아마존", englishName: "Amazon", market: "NASDAQ", currency: "USD", aliases: ["amazon"]),
            StockSearchItem(symbol: "META", name: "메타", englishName: "Meta Platforms", market: "NASDAQ", currency: "USD", aliases: ["facebook", "페이스북"]),
            StockSearchItem(symbol: "NFLX", name: "넷플릭스", englishName: "Netflix", market: "NASDAQ", currency: "USD", aliases: ["netflix"]),
            StockSearchItem(symbol: "AMD", name: "AMD", englishName: "Advanced Micro Devices", market: "NASDAQ", currency: "USD", aliases: ["어드밴스드 마이크로 디바이시스"]),
            StockSearchItem(symbol: "AVGO", name: "브로드컴", englishName: "Broadcom", market: "NASDAQ", currency: "USD", aliases: ["broadcom", "반도체"]),
            StockSearchItem(symbol: "TSM", name: "TSMC", englishName: "Taiwan Semiconductor", market: "NYSE", currency: "USD", aliases: ["taiwan semiconductor", "대만반도체", "파운드리"]),
            StockSearchItem(symbol: "PLTR", name: "팔란티어", englishName: "Palantir", market: "NYSE", currency: "USD", aliases: ["palantir", "ai software"]),
            StockSearchItem(symbol: "RKLB", name: "로켓랩", englishName: "Rocket Lab", market: "NASDAQ", currency: "USD", aliases: ["rocket lab", "우주", "space stock", "space"]),
            StockSearchItem(symbol: "LUNR", name: "인튜이티브 머신스", englishName: "Intuitive Machines", market: "NASDAQ", currency: "USD", aliases: ["intuitive machines", "달착륙", "우주"]),
            StockSearchItem(symbol: "LMT", name: "록히드마틴", englishName: "Lockheed Martin", market: "NYSE", currency: "USD", aliases: ["lockheed", "우주항공", "방산"]),
            StockSearchItem(symbol: "SPY", name: "SPDR S&P 500 ETF", englishName: "SPDR S&P 500 ETF", market: "NYSE", currency: "USD", aliases: ["s&p500", "에스앤피", "스파이"])
        ]
    }

    static var prices: [PriceResponse] {
        [
            PriceResponse(symbol: "005930", timestamp: nil, lastPrice: "72000", currency: "KRW", volume: "15200000"),
            PriceResponse(symbol: "000660", timestamp: nil, lastPrice: "184500", currency: "KRW", volume: "6840000"),
            PriceResponse(symbol: "AAPL", timestamp: nil, lastPrice: "213.18", currency: "USD", volume: "42150000"),
            PriceResponse(symbol: "MSFT", timestamp: nil, lastPrice: "478.42", currency: "USD", volume: "18420000"),
            PriceResponse(symbol: "NVDA", timestamp: nil, lastPrice: "140.22", currency: "USD", volume: "52400000")
        ]
    }

    static func demoPrice(for symbol: String) -> PriceResponse {
        if let price = prices.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
            return price
        }

        let item = stockDirectory.first { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }
        let currency = item?.currency ?? (symbol.count == 6 ? "KRW" : "USD")
        let price = currency == "KRW" ? "50000" : "100.00"
        return PriceResponse(symbol: symbol.uppercased(), timestamp: nil, lastPrice: price, currency: currency, volume: "1000000")
    }

    static var marketActivities: [MarketActivitySnapshot] {
        let lastPrices: [String: String] = [
            "005930": "72000",
            "000660": "184500",
            "035420": "213500",
            "009150": "173000",
            "035720": "48900",
            "005380": "247000",
            "000270": "112400",
            "402340": "176000",
            "042700": "291000",
            "011070": "117000",
            "010120": "248000",
            "066570": "209500",
            "068270": "184200",
            "373220": "329000",
            "005490": "386500",
            "006400": "411000",
            "AAPL": "213.18",
            "MSFT": "478.42",
            "NVDA": "140.22",
            "TSLA": "184.95",
            "GOOGL": "176.50",
            "AMZN": "186.24",
            "META": "508.18",
            "NFLX": "647.31",
            "AMD": "158.74",
            "SPY": "548.02"
        ]

        return stockDirectory.enumerated().map { index, item in
            let price = lastPrices[item.symbol] ?? (item.currency == "KRW" ? "50000" : "100.00")
            let baseVolume = item.currency == "KRW"
                ? Decimal(18_000_000 - index * 820_000)
                : Decimal(52_000_000 - max(0, index - 10) * 2_450_000)
            let volume = max(baseVolume, Decimal(720_000))
            let tradeValue = decimalValue(price) * volume
            return MarketActivitySnapshot(
                symbol: item.symbol,
                name: item.name,
                englishName: item.englishName,
                market: item.market,
                currency: item.currency,
                lastPrice: price,
                timestamp: nil,
                tradeVolume: volume,
                tradeValue: tradeValue,
                tradeSampleCount: 50,
                updatedAt: Date()
            )
        }
    }

    static var candles: [Candle] {
        demoCandles(for: "005930", timeframe: .oneMinuteExtended)
    }

    static func demoCandles(for symbol: String, timeframe: ChartTimeframe = .daily) -> [Candle] {
        let price = demoPrice(for: symbol)
        let basePrice = NSDecimalNumber(decimal: price.lastPriceValue).doubleValue
        let currency = price.currency
        let count = timeframe.candleCount
        let volatilityScale: Double
        let trendScale: Double
        switch timeframe {
        case .oneMinuteRegular:
            volatilityScale = 0.28
            trendScale = 0.18
        case .oneMinuteExtended:
            volatilityScale = 0.32
            trendScale = 0.2
        case .daily:
            volatilityScale = 1
            trendScale = 1
        case .weekly:
            volatilityScale = 2.2
            trendScale = 4.5
        case .monthly:
            volatilityScale = 5.5
            trendScale = 13
        }

        let wave = (currency == "KRW" ? max(basePrice * 0.02, 700) : max(basePrice * 0.025, 2.0)) * volatilityScale
        let slope = (currency == "KRW" ? max(basePrice * 0.00045, 20) : max(basePrice * 0.00055, 0.05)) * trendScale

        return (0..<count).map { index in
            let offset = index - (count - 1)
            let date = demoCandleDate(offset: offset, timeframe: timeframe)
            let base = basePrice + sin(Double(index) * 0.24) * wave + Double(offset) * slope
            let open = base - wave * 0.12
            let high = base + wave * 0.42
            let low = base - wave * 0.48
            let close = base + cos(Double(index) * 0.31) * wave * 0.18
            let volume = demoCandleVolume(index: index, timeframe: timeframe, currency: currency)
            return Candle(
                timestamp: ISO8601DateFormatter().string(from: date),
                openPrice: currency == "KRW" ? String(format: "%.0f", open) : String(format: "%.2f", open),
                highPrice: currency == "KRW" ? String(format: "%.0f", high) : String(format: "%.2f", high),
                lowPrice: currency == "KRW" ? String(format: "%.0f", low) : String(format: "%.2f", low),
                closePrice: currency == "KRW" ? String(format: "%.0f", close) : String(format: "%.2f", close),
                volume: String(format: "%.0f", volume),
                currency: currency
            )
        }
    }

    private static func demoCandleDate(offset: Int, timeframe: ChartTimeframe) -> Date {
        switch timeframe {
        case .oneMinuteRegular, .oneMinuteExtended:
            return Calendar.current.date(byAdding: .minute, value: offset, to: Date()) ?? Date()
        case .daily:
            return Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
        case .weekly:
            return Calendar.current.date(byAdding: .day, value: offset * 7, to: Date()) ?? Date()
        case .monthly:
            return Calendar.current.date(byAdding: .month, value: offset, to: Date()) ?? Date()
        }
    }

    private static func demoCandleVolume(index: Int, timeframe: ChartTimeframe, currency: String) -> Double {
        let base = currency == "KRW" ? 2_800_000.0 : 38_000_000.0
        let multiplier: Double
        switch timeframe {
        case .oneMinuteRegular:
            multiplier = 0.018
        case .oneMinuteExtended:
            multiplier = 0.012
        case .daily:
            multiplier = 1
        case .weekly:
            multiplier = 4.7
        case .monthly:
            multiplier = 19
        }
        return (base + Double(index % 12) * base * 0.034) * multiplier
    }

    static var orderbook: OrderbookResponse {
        let asks = (0..<8).map { index in
            OrderbookEntry(
                price: "\(72400 + index * 100)",
                volume: "\(8200 - index * 420)"
            )
        }
        let bids = (0..<8).map { index in
            OrderbookEntry(
                price: "\(72300 - index * 100)",
                volume: "\(9100 - index * 360)"
            )
        }
        return OrderbookResponse(timestamp: nil, currency: "KRW", asks: asks, bids: bids)
    }

    static var holdings: [Holding] {
        [
            Holding(symbol: "005930", name: "삼성전자", quantity: "32", value: "2304000", currency: "KRW", profitLoss: "+4.8%"),
            Holding(symbol: "AAPL", name: "애플", quantity: "11", value: "2344.98", currency: "USD", profitLoss: "+2.1%"),
            Holding(symbol: "MSFT", name: "마이크로소프트", quantity: "6", value: "2870.52", currency: "USD", profitLoss: "-0.7%")
        ]
    }

    static var strategies: [TradingStrategy] {
        [
            TradingStrategy(
                name: "NVDA 분할매수",
                symbol: "NVDA",
                isEnabled: true,
                mode: .aiReviewMode,
                referencePrice: 145,
                maxDailyAmount: 1_000_000,
                stopLossPercent: -8,
                takeProfitPercent: 12,
                cooldownMinutes: 30,
                conditions: [
                    StrategyCondition(
                        metric: .dropPercent,
                        threshold: 3,
                        action: .buy,
                        amount: 300_000,
                        quantity: 0,
                        orderType: .limit,
                        note: "1차 분할매수"
                    ),
                    StrategyCondition(
                        metric: .dropPercent,
                        threshold: 5,
                        action: .buy,
                        amount: 500_000,
                        quantity: 0,
                        orderType: .limit,
                        note: "2차 분할매수"
                    )
                ],
                createdAt: Date(),
                updatedAt: Date(),
                riskNotes: "AI 검토 후 승인 모드로 시작"
            ),
            TradingStrategy(
                name: "삼성전자 가격 알림",
                symbol: "005930",
                isEnabled: true,
                mode: .alertOnly,
                referencePrice: 72_000,
                maxDailyAmount: 500_000,
                stopLossPercent: -6,
                takeProfitPercent: 10,
                cooldownMinutes: 15,
                conditions: [
                    StrategyCondition(
                        metric: .priceBelow,
                        threshold: 70_000,
                        action: .notify,
                        amount: 0,
                        quantity: 0,
                        orderType: .limit,
                        note: "가격 도달 알림"
                    )
                ],
                createdAt: Date(),
                updatedAt: Date(),
                riskNotes: "알림 전용"
            )
        ]
    }

    static var aiEngines: [AIEngineConfig] {
        [
            AIEngineConfig(
                engine: .codex,
                isEnabled: true,
                analysisCommand: #"tmp=$(mktemp); err=$(mktemp); codex exec -C /Volumes/develop/toss_chart --skip-git-repo-check --sandbox read-only --color never --output-last-message "$tmp" - >/dev/null 2>"$err"; exit_code=$?; if [ -s "$tmp" ]; then cat "$tmp"; elif [ -s "$err" ]; then cat "$err"; fi; rm -f "$tmp" "$err"; exit $exit_code"#,
                versionCommand: "codex --version",
                lastStatus: "미테스트"
            ),
            AIEngineConfig(
                engine: .claude,
                isEnabled: true,
                analysisCommand: "claude -p",
                versionCommand: "claude --version",
                lastStatus: "미테스트"
            ),
            AIEngineConfig(
                engine: .gemini,
                isEnabled: true,
                analysisCommand: "gemini -p",
                versionCommand: "gemini --version",
                lastStatus: "미테스트"
            )
        ]
    }

    static var orderLogs: [OrderLogEntry] {
        [
            OrderLogEntry(
                symbol: "005930",
                strategyName: "삼성전자 가격 알림",
                mode: .alertOnly,
                event: "데모 알림 준비 완료",
                aiReview: "AI 검토 요청 없음",
                orderRequest: "주문 없음",
                result: "조건 충족 대기 중",
                isLiveOrder: false
            )
        ]
    }

    static var aiResults: [AIAnalysisResult] {
        [
            AIAnalysisResult(
                engine: .codex,
                symbol: "NVDA",
                prompt: "분할매수 전략을 검토해줘.",
                output: "데모 결과: 라이브 주문 한도와 장 운영 시간을 확인하기 전까지 승인 모드로 유지하는 편이 안전합니다.",
                riskScore: 62,
                createdAt: Date()
            )
        ]
    }
}
