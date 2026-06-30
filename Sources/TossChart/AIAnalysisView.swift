import SwiftUI

enum AIReportKind: String, CaseIterable, Identifiable {
    case stockReport
    case riskReview
    case strategyReview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stockReport: "종목 리포트"
        case .riskReview: "위험 점검"
        case .strategyReview: "전략 검토"
        }
    }

    var systemImage: String {
        switch self {
        case .stockReport: "doc.text.magnifyingglass"
        case .riskReview: "shield.lefthalf.filled"
        case .strategyReview: "slider.horizontal.3"
        }
    }
}

enum AIReportDepth: String, CaseIterable, Identifiable {
    case quick
    case standard
    case deep

    var id: String { rawValue }

    var title: String {
        switch self {
        case .quick: "요약"
        case .standard: "표준"
        case .deep: "심층"
        }
    }

    var instruction: String {
        switch self {
        case .quick:
            "핵심만 짧게 정리해줘. 한 줄 요약, 위험도, 바로 확인할 가격 구간만 포함해줘."
        case .standard:
            "가격 흐름, 거래량, 보유/전략 리스크, 대응 시나리오를 균형 있게 정리해줘."
        case .deep:
            "가격 흐름, 거래량, 변동성, 전략 충돌 가능성, 손절/익절 구간, 시나리오별 대응까지 자세히 나눠줘."
        }
    }
}

struct AIAnalysisView: View {
    @EnvironmentObject private var session: AppSession
    @State private var selectedEngine: AIEngineKind = .codex
    @State private var selectedKind: AIReportKind = .stockReport
    @State private var selectedDepth: AIReportDepth = .standard
    @State private var symbol = "005930"
    @State private var note = "보유 여부, 진입가, 손절가가 있다면 여기에 적어줘."

    private var resolvedSymbol: String {
        session.resolveSymbol(from: symbol)
    }

    private var symbolResults: [AIAnalysisResult] {
        let target = resolvedSymbol
        return session.aiResults.filter {
            $0.symbol.caseInsensitiveCompare(target) == .orderedSame
        }
    }

    private var latestResult: AIAnalysisResult? {
        symbolResults.first
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            HStack(spacing: 0) {
                AIReportComposer(
                    symbol: $symbol,
                    note: $note,
                    selectedEngine: $selectedEngine,
                    selectedKind: $selectedKind,
                    selectedDepth: $selectedDepth,
                    engineStatuses: session.aiEngines,
                    onRunReport: runReport,
                    onRunCustom: runCustomPrompt
                )
                .frame(minWidth: 360, idealWidth: 390, maxWidth: 430)

                Divider()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        if let latestResult {
                            LatestAIReportCard(result: latestResult) {
                                session.deleteAIResult(latestResult.id)
                            }
                        } else {
                            ContentUnavailableView("종목 리포트가 없습니다", systemImage: "doc.text.magnifyingglass")
                                .frame(maxWidth: .infinity, minHeight: 260)
                                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                        }

                        AIResultHistoryPanel(results: symbolResults) { id in
                            session.deleteAIResult(id)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .onAppear {
            symbol = session.selectedSymbol
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Label("AI 분석", systemImage: "brain.head.profile")
                .font(.title3.weight(.semibold))

            Text(resolvedSymbol)
                .font(.callout.monospaced().weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                session.clearAIResults(for: resolvedSymbol)
            } label: {
                Label("이 종목 지우기", systemImage: "trash")
            }
            .disabled(symbolResults.isEmpty)

            Button {
                session.clearAIResults()
            } label: {
                Label("전체 지우기", systemImage: "trash.slash")
            }
            .disabled(session.aiResults.isEmpty)
        }
        .padding(20)
    }

    private func runReport() {
        let target = resolvedSymbol
        symbol = target
        session.selectedSymbol = target
        let prompt = reportPrompt(symbol: target)
        Task {
            await session.runAIAnalysis(engine: selectedEngine, symbol: target, prompt: prompt)
        }
    }

    private func runCustomPrompt() {
        let target = resolvedSymbol
        symbol = target
        session.selectedSymbol = target
        Task {
            await session.runAIAnalysis(engine: selectedEngine, symbol: target, prompt: note)
        }
    }

    private func reportPrompt(symbol: String) -> String {
        """
        \(symbol) \(selectedKind.title)를 작성해줘.
        분석 깊이: \(selectedDepth.title)
        깊이 지시: \(selectedDepth.instruction)

        추가 메모:
        \(note)

        초보자도 바로 읽을 수 있게 쉬운 말로 작성해줘.
        웹 링크, CLI 로그, 토큰 사용량, 모델명, workdir, 프롬프트 원문은 출력하지 마.
        제목은 아래 4개만 정확히 사용하고, 각 제목 아래에는 짧은 문장 2~4개만 써줘.

        요약
        주요 위험
        손절/익절 점검
        더 안전한 조건 제안

        매수·매도 확정 지시가 아니라 판단 보조 의견으로만 작성해줘.
        """
    }
}

struct AIReportComposer: View {
    @Binding var symbol: String
    @Binding var note: String
    @Binding var selectedEngine: AIEngineKind
    @Binding var selectedKind: AIReportKind
    @Binding var selectedDepth: AIReportDepth

    let engineStatuses: [AIEngineConfig]
    let onRunReport: () -> Void
    let onRunCustom: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("종목")
                    .font(.headline)
                StockSearchField(text: $symbol, placeholder: "종목명 또는 코드", width: 300) { selectedSymbol in
                    symbol = selectedSymbol
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("리포트")
                    .font(.headline)
                Picker("종류", selection: $selectedKind) {
                    ForEach(AIReportKind.allCases) { kind in
                        Label(kind.title, systemImage: kind.systemImage).tag(kind)
                    }
                }
                .pickerStyle(.segmented)

                Picker("깊이", selection: $selectedDepth) {
                    ForEach(AIReportDepth.allCases) { depth in
                        Text(depth.title).tag(depth)
                    }
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("엔진")
                    .font(.headline)
                Picker("엔진", selection: $selectedEngine) {
                    ForEach(AIEngineKind.allCases) { engine in
                        Text(engine.displayName).tag(engine)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("추가 메모")
                    .font(.headline)
                TextEditor(text: $note)
                    .font(.callout)
                    .lineSpacing(4)
                    .frame(minHeight: 130)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.22))
                    )
            }

            HStack {
                Button(action: onRunReport) {
                    Label("리포트 받기", systemImage: "doc.text.magnifyingglass")
                }
                .buttonStyle(.borderedProminent)

                Button(action: onRunCustom) {
                    Label("직접 실행", systemImage: "play")
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 9) {
                Text("엔진 상태")
                    .font(.headline)
                ForEach(engineStatuses) { engine in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(engine.engine.displayName)
                            .font(.caption.weight(.semibold))
                            .frame(width: 84, alignment: .leading)
                        Text(engine.lastStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

struct LatestAIReportCard: View {
    let result: AIAnalysisResult
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(result.symbol) 리포트")
                        .font(.title2.weight(.semibold))
                    Text("\(result.engine.displayName) · \(result.createdAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                RiskScoreBadge(score: result.riskScore)
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("삭제")
            }

            AICommentStrip(result: result)

            ReadableAIReportView(text: result.output)

            Divider()

            DisclosureGroup {
                Text(result.prompt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .textSelection(.enabled)
                    .padding(.top, 6)
            } label: {
                Label("요청 원문", systemImage: "text.quote")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct AICommentStrip: View {
    let result: AIAnalysisResult

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: commentIcon)
                .font(.title3)
                .foregroundStyle(commentColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text("AI 코멘트")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(commentText)
                    .font(.callout)
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(commentColor.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }

    private var commentIcon: String {
        if result.output.localizedCaseInsensitiveContains("명령어가 종료 코드") {
            return "exclamationmark.triangle"
        }
        if result.riskScore >= 70 {
            return "shield.lefthalf.filled"
        }
        if result.riskScore >= 45 {
            return "exclamationmark.circle"
        }
        return "checkmark.circle"
    }

    private var commentColor: Color {
        if result.output.localizedCaseInsensitiveContains("명령어가 종료 코드") || result.riskScore >= 70 {
            return .red
        }
        if result.riskScore >= 45 {
            return .orange
        }
        return .green
    }

    private var commentText: String {
        if result.output.localizedCaseInsensitiveContains("명령어가 종료 코드") {
            return "CLI 실행이 실패했습니다. 설정의 명령어 경로와 인증 상태를 먼저 확인해야 합니다."
        }
        if result.riskScore >= 70 {
            return "위험 신호가 강합니다. 자동 주문보다 알림 또는 승인 후 주문 모드로 낮춰서 보는 편이 안전합니다."
        }
        if result.riskScore >= 45 {
            return "주의 구간입니다. 손절가, 주문 금액, 중복 조건을 한 번 더 확인하세요."
        }
        return "현재 리포트 기준으로는 과도한 위험 표현이 적습니다. 그래도 실제 주문 전 가격과 수량을 다시 확인하세요."
    }
}

struct AIResultHistoryPanel: View {
    let results: [AIAnalysisResult]
    let onDelete: (UUID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("종목별 기록", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                Spacer()
                Text("\(results.count)건")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if results.isEmpty {
                Text("기록 없음")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(results) { result in
                    AIResultHistoryRow(result: result) {
                        onDelete(result.id)
                    }
                }
            }
        }
    }
}

struct AIResultHistoryRow: View {
    let result: AIAnalysisResult
    let onDelete: () -> Void
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                ReadableAIReportView(text: result.output, compact: true)
            }
            .padding(.top, 8)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(result.engine.displayName)
                        .font(.callout.weight(.semibold))
                    Text(result.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                RiskScoreBadge(score: result.riskScore)
                Button(action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .help("삭제")
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct ReadableAIReportView: View {
    let text: String
    var compact = false

    private var sections: [ReadableAIReportSection] {
        AIReportTextParser.sections(from: text)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            ForEach(sections) { section in
                ReadableAIReportSectionCard(section: section, compact: compact)
            }
        }
    }
}

struct ReadableAIReportSectionCard: View {
    let section: ReadableAIReportSection
    let compact: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: section.icon)
                .foregroundStyle(section.color)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 6) {
                Text(section.title)
                    .font(compact ? .callout.weight(.semibold) : .headline)
                Text(section.body)
                    .font(compact ? .callout : .body)
                    .lineSpacing(5)
                    .textSelection(.enabled)
            }
            Spacer(minLength: 0)
        }
        .padding(compact ? 12 : 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(section.color.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct ReadableAIReportSection: Identifiable {
    var id: String { "\(title)-\(body.prefix(24))" }
    let title: String
    let body: String

    var icon: String {
        switch title {
        case "요약": "text.alignleft"
        case "주요 위험", "핵심 리스크": "exclamationmark.triangle"
        case "손절/익절 점검": "arrow.up.arrow.down"
        case "더 안전한 조건 제안", "다음 확인 항목": "checklist"
        default: "doc.text"
        }
    }

    var color: Color {
        switch title {
        case "요약": .blue
        case "주요 위험", "핵심 리스크": .orange
        case "손절/익절 점검": .purple
        case "더 안전한 조건 제안", "다음 확인 항목": .green
        default: .secondary
        }
    }
}

enum AIReportTextParser {
    static func sections(from rawText: String) -> [ReadableAIReportSection] {
        let text = AIOutputCleaner.clean(rawText)
        let headings = [
            "요약",
            "현재 가격/거래량 해석",
            "주요 위험",
            "핵심 리스크",
            "손절/익절 점검",
            "더 안전한 조건 제안",
            "다음 확인 항목"
        ]

        let matches = headings.compactMap { heading -> (title: String, range: Range<String.Index>)? in
            guard let range = text.range(of: heading) else {
                return nil
            }
            return (heading, range)
        }
        .sorted { $0.range.lowerBound < $1.range.lowerBound }

        guard !matches.isEmpty else {
            return [ReadableAIReportSection(title: "요약", body: normalizedBody(text))]
        }

        var sections: [ReadableAIReportSection] = []
        for index in matches.indices {
            let match = matches[index]
            let bodyStart = match.range.upperBound
            let bodyEnd = index + 1 < matches.count ? matches[index + 1].range.lowerBound : text.endIndex
            let body = normalizedBody(String(text[bodyStart..<bodyEnd]))
            guard !body.isEmpty else {
                continue
            }
            sections.append(ReadableAIReportSection(title: match.title, body: body))
        }

        return sections.isEmpty ? [ReadableAIReportSection(title: "요약", body: normalizedBody(text))] : sections
    }

    private static func normalizedBody(_ text: String) -> String {
        text
            .replacingOccurrences(of: #"[\t ]+"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\n{3,}"#, with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ":-–—")))
    }
}

struct MarkdownOutputText: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        if let attributed = try? AttributedString(markdown: normalizedText) {
            Text(attributed)
        } else {
            Text(normalizedText)
        }
    }

    private var normalizedText: String {
        text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .replacingOccurrences(of: "\n|", with: "\n\n|")
            .replacingOccurrences(of: "\n###", with: "\n\n###")
            .replacingOccurrences(of: "\n##", with: "\n\n##")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

struct RiskScoreBadge: View {
    let score: Int

    var body: some View {
        Text("위험도 \(score)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(score >= 70 ? .red : score >= 45 ? .orange : .green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.quaternary.opacity(0.45), in: Capsule())
    }
}
