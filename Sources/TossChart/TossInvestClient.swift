import Foundation

enum TossInvestClientError: LocalizedError {
    case invalidURL
    case emptyCredentials
    case httpStatus(Int, String)
    case rateLimited(String, retryAfterSeconds: Int?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "API URL이 올바르지 않습니다"
        case .emptyCredentials:
            "클라이언트 인증 정보가 비어 있습니다"
        case .httpStatus(let status, let message):
            "HTTP \(status): \(message)"
        case .rateLimited(let message, let retryAfterSeconds):
            if let retryAfterSeconds {
                "요청 한도를 초과했습니다. \(retryAfterSeconds)초 후 다시 시도하세요. \(message)"
            } else {
                "요청 한도를 초과했습니다. 잠시 후 다시 시도하세요. \(message)"
            }
        }
    }
}

struct TossInvestClient {
    private let baseURL = URL(string: "https://openapi.tossinvest.com")!
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    func issueToken(credentials: Credentials) async throws -> OAuth2TokenResponse {
        guard credentials.isComplete else {
            throw TossInvestClientError.emptyCredentials
        }

        var request = URLRequest(url: try url(path: "/oauth2/token"))
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = formBody([
            "grant_type": "client_credentials",
            "client_id": credentials.clientID,
            "client_secret": credentials.clientSecret
        ])

        return try await perform(request)
    }

    func prices(symbols: [String], accessToken: String) async throws -> [PriceResponse] {
        var request = URLRequest(url: try url(
            path: "/api/v1/prices",
            queryItems: [URLQueryItem(name: "symbols", value: symbols.joined(separator: ","))]
        ))
        authorize(&request, accessToken: accessToken)
        let envelope: APIEnvelope<[PriceResponse]> = try await perform(request)
        return envelope.result
    }

    func stocks(symbols: [String], accessToken: String) async throws -> [StockInfo] {
        var request = URLRequest(url: try url(
            path: "/api/v1/stocks",
            queryItems: [URLQueryItem(name: "symbols", value: symbols.joined(separator: ","))]
        ))
        authorize(&request, accessToken: accessToken)
        let envelope: APIEnvelope<[StockInfo]> = try await perform(request)
        return envelope.result
    }

    func candles(symbol: String, interval: String, count: Int, before: String? = nil, accessToken: String) async throws -> CandlePageResponse {
        var queryItems = [
            URLQueryItem(name: "symbol", value: symbol),
            URLQueryItem(name: "interval", value: interval),
            URLQueryItem(name: "count", value: "\(count)"),
            URLQueryItem(name: "adjusted", value: "true")
        ]
        if let before {
            queryItems.append(URLQueryItem(name: "before", value: before))
        }

        var request = URLRequest(url: try url(
            path: "/api/v1/candles",
            queryItems: queryItems
        ))
        authorize(&request, accessToken: accessToken)
        let envelope: APIEnvelope<CandlePageResponse> = try await perform(request)
        return envelope.result
    }

    func orderbook(symbol: String, accessToken: String) async throws -> OrderbookResponse {
        var request = URLRequest(url: try url(
            path: "/api/v1/orderbook",
            queryItems: [URLQueryItem(name: "symbol", value: symbol)]
        ))
        authorize(&request, accessToken: accessToken)
        let envelope: APIEnvelope<OrderbookResponse> = try await perform(request)
        return envelope.result
    }

    func trades(symbol: String, count: Int = 50, accessToken: String) async throws -> [Trade] {
        var request = URLRequest(url: try url(
            path: "/api/v1/trades",
            queryItems: [
                URLQueryItem(name: "symbol", value: symbol),
                URLQueryItem(name: "count", value: "\(count)")
            ]
        ))
        authorize(&request, accessToken: accessToken)
        let envelope: APIEnvelope<[Trade]> = try await perform(request)
        return envelope.result
    }

    func exchangeRate(baseCurrency: String, quoteCurrency: String, accessToken: String) async throws -> ExchangeRateResponse {
        var request = URLRequest(url: try url(
            path: "/api/v1/exchange-rate",
            queryItems: [
                URLQueryItem(name: "baseCurrency", value: baseCurrency),
                URLQueryItem(name: "quoteCurrency", value: quoteCurrency)
            ]
        ))
        authorize(&request, accessToken: accessToken)
        let envelope: APIEnvelope<ExchangeRateResponse> = try await perform(request)
        return envelope.result
    }

    func buyingPower(accountSeq: Int64, currency: String, accessToken: String) async throws -> BuyingPowerResponse {
        var request = URLRequest(url: try url(
            path: "/api/v1/buying-power",
            queryItems: [URLQueryItem(name: "currency", value: currency)]
        ))
        request.setValue("\(accountSeq)", forHTTPHeaderField: "X-Tossinvest-Account")
        authorize(&request, accessToken: accessToken)
        let envelope: APIEnvelope<BuyingPowerResponse> = try await perform(request)
        return envelope.result
    }

    func sellableQuantity(accountSeq: Int64, symbol: String, accessToken: String) async throws -> SellableQuantityResponse {
        var request = URLRequest(url: try url(
            path: "/api/v1/sellable-quantity",
            queryItems: [URLQueryItem(name: "symbol", value: symbol)]
        ))
        request.setValue("\(accountSeq)", forHTTPHeaderField: "X-Tossinvest-Account")
        authorize(&request, accessToken: accessToken)
        let envelope: APIEnvelope<SellableQuantityResponse> = try await perform(request)
        return envelope.result
    }

    func accounts(accessToken: String) async throws -> [Account] {
        var request = URLRequest(url: try url(path: "/api/v1/accounts"))
        authorize(&request, accessToken: accessToken)
        let envelope: APIEnvelope<[Account]> = try await perform(request)
        return envelope.result
    }

    func holdings(accountSeq: Int64, accessToken: String, symbol: String? = nil) async throws -> HoldingsOverviewResponse {
        var queryItems: [URLQueryItem] = []
        if let symbol, !symbol.isEmpty {
            queryItems.append(URLQueryItem(name: "symbol", value: symbol))
        }

        var request = URLRequest(url: try url(path: "/api/v1/holdings", queryItems: queryItems))
        authorize(&request, accessToken: accessToken)
        request.setValue("\(accountSeq)", forHTTPHeaderField: "X-Tossinvest-Account")
        let envelope: APIEnvelope<HoldingsOverviewResponse> = try await perform(request)
        return envelope.result
    }

    func createOrder(accountSeq: Int64, payload: OrderCreatePayload, accessToken: String) async throws -> OrderResponse {
        var request = URLRequest(url: try url(path: "/api/v1/orders"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("\(accountSeq)", forHTTPHeaderField: "X-Tossinvest-Account")
        authorize(&request, accessToken: accessToken)
        request.httpBody = try encoder.encode(payload)
        let envelope: APIEnvelope<OrderResponse> = try await perform(request)
        return envelope.result
    }

    private func authorize(_ request: inout URLRequest, accessToken: String) {
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    private func url(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
        var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
        components?.path = path
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        if let encodedQuery = components?.percentEncodedQuery {
            components?.percentEncodedQuery = encodedQuery.replacingOccurrences(of: "+", with: "%2B")
        }
        guard let url = components?.url else {
            throw TossInvestClientError.invalidURL
        }
        return url
    }

    private func formBody(_ values: [String: String]) -> Data {
        values
            .map { key, value in
                "\(escapeFormValue(key))=\(escapeFormValue(value))"
            }
            .joined(separator: "&")
            .data(using: .utf8) ?? Data()
    }

    private func escapeFormValue(_ value: String) -> String {
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "&+=")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    private func perform<Response: Decodable>(_ request: URLRequest) async throws -> Response {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TossInvestClientError.httpStatus(0, "HTTP 응답이 없습니다")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            if let envelope = try? decoder.decode(ErrorEnvelope.self, from: data) {
                if httpResponse.statusCode == 429 {
                    throw TossInvestClientError.rateLimited(
                        envelope.error.message,
                        retryAfterSeconds: retryAfterSeconds(from: httpResponse, payload: envelope.error)
                    )
                }
                throw TossInvestClientError.httpStatus(httpResponse.statusCode, envelope.error.message)
            }
            let body = String(data: data, encoding: .utf8) ?? "요청에 실패했습니다"
            if httpResponse.statusCode == 429 {
                throw TossInvestClientError.rateLimited(body, retryAfterSeconds: retryAfterSeconds(from: httpResponse, payload: nil))
            }
            throw TossInvestClientError.httpStatus(httpResponse.statusCode, body)
        }

        return try decoder.decode(Response.self, from: data)
    }

    private func retryAfterSeconds(from response: HTTPURLResponse, payload: APIErrorPayload?) -> Int? {
        if let seconds = payload?.data?.retryAfterSeconds {
            return max(1, seconds)
        }

        if let retryAfterAt = payload?.data?.retryAfterAt,
           let date = parseAPIDate(retryAfterAt) {
            return max(1, Int(ceil(date.timeIntervalSinceNow)))
        }

        if let header = response.value(forHTTPHeaderField: "Retry-After") {
            if let seconds = Int(header.trimmingCharacters(in: .whitespacesAndNewlines)) {
                return max(1, seconds)
            }
            if let date = parseAPIDate(header) {
                return max(1, Int(ceil(date.timeIntervalSinceNow)))
            }
        }

        return nil
    }
}
