import Foundation
import SwiftData

@Model
final class UsageEvent {
    var id: UUID
    var timestamp: Date

    init(id: UUID = UUID(), timestamp: Date = .now) {
        self.id = id
        self.timestamp = timestamp
    }
}
