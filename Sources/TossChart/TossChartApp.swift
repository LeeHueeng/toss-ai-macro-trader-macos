import SwiftUI

@main
struct TossChartApp: App {
    @StateObject private var session = AppSession()

    var body: some Scene {
        WindowGroup {
            AppShell()
                .environmentObject(session)
                .frame(minWidth: 1080, minHeight: 700)
        }
        .windowStyle(.titleBar)

        Settings {
            SettingsView()
                .environmentObject(session)
                .frame(width: 460)
        }
    }
}
