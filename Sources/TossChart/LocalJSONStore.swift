import Foundation

struct AppStorageSnapshot: Codable {
    var watchedSymbols: [String]
    var priceAlerts: [PriceAlert]
    var strategies: [TradingStrategy]
    var orderLogs: [OrderLogEntry]
    var pendingOrders: [PendingOrderDraft]
    var selectedAccountSeq: Int64?
    var safetySettings: SafetySettings
    var autoRebalanceSettings: AutoRebalanceSettings
    var tossCLISettings: TossCLISettings
    var investorProfile: InvestorProfileSettings
    var aiEngines: [AIEngineConfig]
    var aiResults: [AIAnalysisResult]

    init(
        watchedSymbols: [String],
        priceAlerts: [PriceAlert],
        strategies: [TradingStrategy],
        orderLogs: [OrderLogEntry],
        pendingOrders: [PendingOrderDraft],
        selectedAccountSeq: Int64?,
        safetySettings: SafetySettings,
        autoRebalanceSettings: AutoRebalanceSettings,
        tossCLISettings: TossCLISettings,
        investorProfile: InvestorProfileSettings,
        aiEngines: [AIEngineConfig],
        aiResults: [AIAnalysisResult]
    ) {
        self.watchedSymbols = watchedSymbols
        self.priceAlerts = priceAlerts
        self.strategies = strategies
        self.orderLogs = orderLogs
        self.pendingOrders = pendingOrders
        self.selectedAccountSeq = selectedAccountSeq
        self.safetySettings = safetySettings
        self.autoRebalanceSettings = autoRebalanceSettings
        self.tossCLISettings = tossCLISettings
        self.investorProfile = investorProfile
        self.aiEngines = aiEngines
        self.aiResults = aiResults
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        watchedSymbols = try container.decodeIfPresent([String].self, forKey: .watchedSymbols) ?? []
        priceAlerts = try container.decodeIfPresent([PriceAlert].self, forKey: .priceAlerts) ?? []
        strategies = try container.decodeIfPresent([TradingStrategy].self, forKey: .strategies) ?? []
        orderLogs = try container.decodeIfPresent([OrderLogEntry].self, forKey: .orderLogs) ?? []
        pendingOrders = try container.decodeIfPresent([PendingOrderDraft].self, forKey: .pendingOrders) ?? []
        selectedAccountSeq = try container.decodeIfPresent(Int64.self, forKey: .selectedAccountSeq)
        safetySettings = try container.decodeIfPresent(SafetySettings.self, forKey: .safetySettings) ?? .defaults
        autoRebalanceSettings = try container.decodeIfPresent(AutoRebalanceSettings.self, forKey: .autoRebalanceSettings) ?? .defaults
        tossCLISettings = try container.decodeIfPresent(TossCLISettings.self, forKey: .tossCLISettings) ?? .defaults
        investorProfile = try container.decodeIfPresent(InvestorProfileSettings.self, forKey: .investorProfile) ?? .defaults
        aiEngines = try container.decodeIfPresent([AIEngineConfig].self, forKey: .aiEngines) ?? MockData.aiEngines
        aiResults = try container.decodeIfPresent([AIAnalysisResult].self, forKey: .aiResults) ?? []
    }
}

struct LocalJSONStore {
    private let fileManager = FileManager.default
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    var stateURL: URL {
        let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appending(path: "TossAIMacroTrader", directoryHint: .isDirectory)
            .appending(path: "state.json")
    }

    func load() -> AppStorageSnapshot? {
        let url = stateURL
        guard fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(AppStorageSnapshot.self, from: data)
        } catch {
            return nil
        }
    }

    func save(_ snapshot: AppStorageSnapshot) throws {
        let url = stateURL
        try fileManager.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(snapshot)
        try data.write(to: url, options: [.atomic])
    }
}
