import Foundation
import UserNotifications

struct NotificationService {
    func requestAuthorization() async {
        guard canUseUserNotifications else {
            return
        }
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    func post(title: String, body: String) {
        guard canUseUserNotifications else {
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private var canUseUserNotifications: Bool {
        Bundle.main.bundleURL.pathExtension == "app" &&
            Bundle.main.bundleIdentifier?.isEmpty == false
    }
}
