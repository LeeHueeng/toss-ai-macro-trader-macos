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
            StockSearchItem(symbol: "051910", name: "LG화학", englishName: "LG Chem", market: "KOSPI", currency: "KRW", aliases: ["엘지화학", "lg chem", "2차전지", "배터리"]),
            StockSearchItem(symbol: "005490", name: "POSCO홀딩스", englishName: "POSCO Holdings", market: "KOSPI", currency: "KRW", aliases: ["포스코", "posco"]),
            StockSearchItem(symbol: "006400", name: "삼성SDI", englishName: "Samsung SDI", market: "KOSPI", currency: "KRW", aliases: ["sdi", "삼성에스디아이"]),
            StockSearchItem(symbol: "086520", name: "에코프로", englishName: "EcoPro", market: "KOSDAQ", currency: "KRW", aliases: ["ecopro", "에코프로", "2차전지", "배터리"]),
            StockSearchItem(symbol: "247540", name: "에코프로비엠", englishName: "EcoPro BM", market: "KOSDAQ", currency: "KRW", aliases: ["ecopro bm", "에코프로bm", "에코프로비엠", "양극재", "2차전지"]),
            StockSearchItem(symbol: "450080", name: "에코프로머티", englishName: "EcoPro Materials", market: "KOSPI", currency: "KRW", aliases: ["ecopro materials", "에코프로머티리얼즈", "에코프로머티", "전구체", "2차전지"]),
            StockSearchItem(symbol: "003670", name: "포스코퓨처엠", englishName: "POSCO Future M", market: "KOSPI", currency: "KRW", aliases: ["posco future m", "퓨처엠", "포스코케미칼", "양극재", "2차전지"]),
            StockSearchItem(symbol: "066970", name: "엘앤에프", englishName: "L&F", market: "KOSDAQ", currency: "KRW", aliases: ["l&f", "lnf", "양극재", "2차전지"]),
            StockSearchItem(symbol: "361610", name: "SK아이이테크놀로지", englishName: "SK IE Technology", market: "KOSPI", currency: "KRW", aliases: ["sk iet", "sk아이이테크놀로지", "분리막", "2차전지"]),
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
            StockSearchItem(symbol: "ASML", name: "ASML", englishName: "ASML Holding", market: "NASDAQ", currency: "USD", aliases: ["euv", "노광", "반도체 장비"]),
            StockSearchItem(symbol: "AMAT", name: "어플라이드 머티어리얼즈", englishName: "Applied Materials", market: "NASDAQ", currency: "USD", aliases: ["applied materials", "반도체 장비", "장비"]),
            StockSearchItem(symbol: "LRCX", name: "램리서치", englishName: "Lam Research", market: "NASDAQ", currency: "USD", aliases: ["lam research", "etch", "식각", "반도체 장비"]),
            StockSearchItem(symbol: "KLAC", name: "KLA", englishName: "KLA Corporation", market: "NASDAQ", currency: "USD", aliases: ["kla", "검사장비", "metrology"]),
            StockSearchItem(symbol: "MU", name: "마이크론", englishName: "Micron Technology", market: "NASDAQ", currency: "USD", aliases: ["micron", "memory", "dram", "nand"]),
            StockSearchItem(symbol: "INTC", name: "인텔", englishName: "Intel", market: "NASDAQ", currency: "USD", aliases: ["intel", "cpu", "foundry"]),
            StockSearchItem(symbol: "QCOM", name: "퀄컴", englishName: "Qualcomm", market: "NASDAQ", currency: "USD", aliases: ["qualcomm", "mobile chip"]),
            StockSearchItem(symbol: "ARM", name: "ARM", englishName: "Arm Holdings", market: "NASDAQ", currency: "USD", aliases: ["arm holdings", "chip ip"]),
            StockSearchItem(symbol: "MRVL", name: "마벨", englishName: "Marvell Technology", market: "NASDAQ", currency: "USD", aliases: ["marvell", "data center chip"]),
            StockSearchItem(symbol: "ON", name: "온세미", englishName: "ON Semiconductor", market: "NASDAQ", currency: "USD", aliases: ["onsemi", "power semiconductor"]),
            StockSearchItem(symbol: "NXPI", name: "NXP", englishName: "NXP Semiconductors", market: "NASDAQ", currency: "USD", aliases: ["nxp", "automotive chip"]),
            StockSearchItem(symbol: "MCHP", name: "마이크로칩", englishName: "Microchip Technology", market: "NASDAQ", currency: "USD", aliases: ["microchip", "mcu"]),
            StockSearchItem(symbol: "TXN", name: "텍사스 인스트루먼트", englishName: "Texas Instruments", market: "NASDAQ", currency: "USD", aliases: ["texas instruments", "analog chip"]),
            StockSearchItem(symbol: "ADI", name: "아날로그 디바이시스", englishName: "Analog Devices", market: "NASDAQ", currency: "USD", aliases: ["analog devices", "analog chip"]),
            StockSearchItem(symbol: "MPWR", name: "모놀리식 파워", englishName: "Monolithic Power Systems", market: "NASDAQ", currency: "USD", aliases: ["monolithic power", "power management"]),
            StockSearchItem(symbol: "GFS", name: "글로벌파운드리스", englishName: "GlobalFoundries", market: "NASDAQ", currency: "USD", aliases: ["globalfoundries", "파운드리"]),
            StockSearchItem(symbol: "UMC", name: "UMC", englishName: "United Microelectronics", market: "NYSE", currency: "USD", aliases: ["united microelectronics", "파운드리"]),
            StockSearchItem(symbol: "AMKR", name: "앰코", englishName: "Amkor Technology", market: "NASDAQ", currency: "USD", aliases: ["amkor", "packaging", "후공정"]),
            StockSearchItem(symbol: "COHR", name: "코히런트", englishName: "Coherent", market: "NYSE", currency: "USD", aliases: ["coherent", "silicon carbide", "optical"]),
            StockSearchItem(symbol: "ACMR", name: "ACM 리서치", englishName: "ACM Research", market: "NASDAQ", currency: "USD", aliases: ["acm research", "반도체 장비"]),
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
            "051910": "361000",
            "005490": "386500",
            "006400": "411000",
            "086520": "76200",
            "247540": "184800",
            "450080": "92100",
            "003670": "247500",
            "066970": "138500",
            "361610": "31900",
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
        let changePercents: [String: Double] = [
            "005930": 3.41,
            "000660": 0.84,
            "035420": -1.18,
            "009150": 2.22,
            "035720": -0.92,
            "005380": -0.41,
            "000270": -0.65,
            "402340": 3.48,
            "042700": 4.12,
            "011070": 1.74,
            "010120": 2.08,
            "066570": -0.35,
            "068270": 1.32,
            "373220": -2.18,
            "051910": -0.84,
            "005490": -1.04,
            "006400": -1.74,
            "086520": 3.28,
            "247540": 2.74,
            "450080": -1.16,
            "003670": 1.45,
            "066970": 2.05,
            "361610": -0.48,
            "AAPL": 0.58,
            "MSFT": 0.24,
            "NVDA": 2.15,
            "TSLA": -1.42,
            "GOOGL": -0.31,
            "AMZN": 0.82,
            "META": 1.08,
            "NFLX": -0.77,
            "AMD": 1.94,
            "AVGO": 1.36,
            "TSM": 0.91,
            "PLTR": 2.44,
            "RKLB": -2.08,
            "LUNR": -3.36,
            "LMT": 0.43,
            "SPY": 0.35
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
                updatedAt: Date(),
                priceChange: nil,
                changePercent: changePercents[item.symbol]
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
