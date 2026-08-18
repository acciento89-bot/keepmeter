import Foundation
import UserNotifications

enum NotificationManager {
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    static func scheduleReturnReminders(for purchase: Purchase, calendar: Calendar = .current) async {
        let center = UNUserNotificationCenter.current()
        let prefix = reminderPrefix(for: purchase)

        center.removePendingNotificationRequests(withIdentifiers: [
            "\(prefix)-3d",
            "\(prefix)-1d",
            "\(prefix)-day"
        ])

        let reminders: [(daysBefore: Int, suffix: String)] = [
            (3, "3d"),
            (1, "1d"),
            (0, "day")
        ]

        for reminder in reminders {
            guard let reminderDate = calendar.date(byAdding: .day, value: -reminder.daysBefore, to: purchase.returnDeadline) else {
                continue
            }

            var components = calendar.dateComponents([.year, .month, .day], from: reminderDate)
            components.hour = 10
            components.minute = 0

            guard let fireDate = calendar.date(from: components), fireDate > .now else {
                continue
            }

            let content = UNMutableNotificationContent()
            content.title = NSLocalizedString("notification.returnWindow.title", comment: "Return deadline notification title")
            content.body = reminderBody(for: purchase.name, daysBefore: reminder.daysBefore)
            content.sound = .default

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(prefix)-\(reminder.suffix)",
                content: content,
                trigger: trigger
            )

            try? await center.add(request)
        }
    }

    static func cancelReturnReminders(for purchase: Purchase) {
        let prefix = reminderPrefix(for: purchase)
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
            "\(prefix)-3d",
            "\(prefix)-1d",
            "\(prefix)-day"
        ])
    }

    private static func reminderPrefix(for purchase: Purchase) -> String {
        "return-\(purchase.id.uuidString)"
    }

    private static func reminderBody(for name: String, daysBefore: Int) -> String {
        switch daysBefore {
        case 0:
            return String(
                format: NSLocalizedString(
                    "notification.returnWindow.today",
                    comment: "Body for a notification fired on the return deadline; %@ is the purchase name"
                ),
                locale: Locale.current,
                name
            )
        case 1:
            return String(
                format: NSLocalizedString(
                    "notification.returnWindow.tomorrow",
                    comment: "Body for a notification one day before the return deadline; %@ is the purchase name"
                ),
                locale: Locale.current,
                name
            )
        default:
            return String(
                format: NSLocalizedString(
                    "notification.returnWindow.days",
                    comment: "Body for a return notification; first %@ is the purchase name and %ld is the number of days remaining"
                ),
                locale: Locale.current,
                name,
                daysBefore
            )
        }
    }
}
