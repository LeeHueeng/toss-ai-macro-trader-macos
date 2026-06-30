import SwiftUI

struct StockSearchField: View {
    @EnvironmentObject private var session: AppSession
    @Binding var text: String

    let placeholder: String
    var width: CGFloat = 240
    var showsSelectedName = false
    var onSelect: (String) -> Void = { _ in }

    @FocusState private var isFocused: Bool

    private var suggestions: [StockSearchItem] {
        session.stockSuggestions(for: text)
    }

    private var unavailableHint: String? {
        let normalized = text
            .lowercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")

        if normalized.contains("spacex") || normalized.contains("스페이스x") || normalized.contains("스페이스엑스") || normalized == "스페이스" {
            return "SpaceX는 아직 상장되지 않은 비상장 회사라 이 앱에서 바로 매매할 수 없어요."
        }
        return nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            TextField(placeholder, text: $text)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)
                .frame(width: width)
                .onSubmit {
                    choose(session.resolveSymbol(from: text))
                }

            if isFocused, !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(suggestions) { item in
                        Button {
                            choose(item)
                        } label: {
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.name)
                                        .font(.callout.weight(.medium))
                                    Text(item.englishName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(item.symbol)
                                        .font(.callout.monospacedDigit())
                                    Text(item.market)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                        }
                        .buttonStyle(.plain)

                        if item.id != suggestions.last?.id {
                            Divider()
                        }
                    }
                }
                .frame(width: width)
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2))
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            } else if isFocused, let unavailableHint, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label(unavailableHint, systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("우주 관련 상장 종목은 로켓랩(RKLB), 인튜이티브 머신스(LUNR), 록히드마틴(LMT)처럼 검색해볼 수 있어요.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .frame(width: width, alignment: .leading)
                .background(.background, in: RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2))
                )
            }
        }
    }

    private func choose(_ item: StockSearchItem) {
        text = showsSelectedName ? item.displayText : item.symbol
        isFocused = false
        onSelect(item.symbol)
    }

    private func choose(_ symbol: String) {
        if showsSelectedName, let item = session.stockDirectory.first(where: { $0.symbol.caseInsensitiveCompare(symbol) == .orderedSame }) {
            text = item.displayText
        } else {
            text = symbol
        }
        isFocused = false
        onSelect(symbol)
    }
}
