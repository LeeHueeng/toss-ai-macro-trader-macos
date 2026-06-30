import SwiftUI

struct RuntimeStatusPanel: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        HStack(spacing: 12) {
            statusTile(
                title: "자동매매",
                value: session.automationEnabled ? "켜짐" : "꺼짐",
                icon: "power",
                color: session.automationEnabled ? .green : .secondary
            )
            statusTile(
                title: "자동 감시",
                value: automationMonitorText,
                icon: "arrow.clockwise",
                color: session.automationEnabled ? .blue : .secondary
            )
            statusTile(
                title: "전략",
                value: "\(session.activeStrategyCount)개 활성",
                icon: "slider.horizontal.3",
                color: .blue
            )
            statusTile(
                title: "승인 대기",
                value: "\(session.pendingOrderCount)건",
                icon: "checklist",
                color: session.pendingOrderCount > 0 ? .orange : .secondary
            )
            statusTile(
                title: "AI",
                value: session.latestAIStatus,
                icon: "brain.head.profile",
                color: .purple
            )
            statusTile(
                title: "라이브 주문",
                value: session.safetySettings.allowLiveOrders ? "해제됨" : "잠김",
                icon: session.safetySettings.allowLiveOrders ? "lock.open" : "lock",
                color: session.safetySettings.allowLiveOrders ? .red : .green
            )
        }
    }

    private var automationMonitorText: String {
        guard session.automationEnabled else {
            return "중지"
        }
        if let next = session.nextAutomationScanAt {
            return "다음 \(next.formatted(date: .omitted, time: .standard))"
        }
        if let last = session.lastAutomationScanAt {
            return "최근 \(last.formatted(date: .omitted, time: .standard))"
        }
        return "60초마다"
    }

    private func statusTile(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.callout.weight(.semibold))
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 70)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct StrategySnapshotPanel: View {
    @EnvironmentObject private var session: AppSession

    private var activeStrategies: [TradingStrategy] {
        session.strategies.filter(\.isEnabled)
    }

    private var inactiveCount: Int {
        max(0, session.strategies.count - activeStrategies.count)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label("감시 중인 매크로", systemImage: "scope")
                        .font(.headline)
                    Spacer()
                    Text("\(activeStrategies.count)개 활성")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(activeStrategies.isEmpty ? Color.secondary : Color.green)
                }

                if activeStrategies.isEmpty {
                    Label("켜진 매크로가 없어 실제 감시는 하지 않습니다.", systemImage: "pause.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 6)
                } else {
                    ForEach(activeStrategies.prefix(3)) { strategy in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(strategy.name)
                                    .font(.callout.weight(.medium))
                                Text("\(strategy.symbol) · \(strategy.mode.title)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(session.nextTriggerText(for: strategy))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            Spacer()
                            Text("감시 중")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 3)
                    }
                }

                if inactiveCount > 0 {
                    Text("꺼진 전략 \(inactiveCount)개는 감시하지 않습니다.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 10) {
                Label("위험 가드", systemImage: "shield.lefthalf.filled")
                    .font(.headline)

                ForEach(session.riskWarnings.prefix(4), id: \.self) { warning in
                    Label(warning, systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.background, in: RoundedRectangle(cornerRadius: 8))
        }
    }
}
