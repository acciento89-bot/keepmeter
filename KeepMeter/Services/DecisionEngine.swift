import Foundation

enum DecisionStatus: String, CaseIterable {
    case keep
    case review
    case returnCandidate
}

enum DecisionReason: String, CaseIterable {
    case deadlinePassed
    case unusedUrgent
    case lightlyUsedUrgent
    case unusedLateWindow
    case repeatedUse
    case earlyWindow
    case needsMoreSignal
}

struct DecisionSnapshot {
    let status: DecisionStatus
    let reason: DecisionReason
    let daysRemaining: Int
    let useCount: Int
    let costPerUse: Double?
}

enum DecisionEngine {
    static func evaluate(_ purchase: Purchase, referenceDate: Date = .now) -> DecisionSnapshot {
        let daysRemaining = purchase.daysRemaining(referenceDate: referenceDate)
        let useCount = purchase.useCount
        let elapsedRatio = purchase.returnWindowElapsedRatio(referenceDate: referenceDate)

        let status: DecisionStatus
        let reason: DecisionReason

        if daysRemaining < 0 {
            status = .review
            reason = .deadlinePassed
        } else if useCount == 0 && daysRemaining <= 3 {
            status = .returnCandidate
            reason = .unusedUrgent
        } else if useCount <= 1 && daysRemaining <= 3 {
            status = .review
            reason = .lightlyUsedUrgent
        } else if useCount == 0 && elapsedRatio >= 0.60 {
            status = .review
            reason = .unusedLateWindow
        } else if useCount >= 3 {
            status = .keep
            reason = .repeatedUse
        } else if elapsedRatio < 0.35 {
            status = .review
            reason = .earlyWindow
        } else {
            status = .review
            reason = .needsMoreSignal
        }

        return DecisionSnapshot(
            status: status,
            reason: reason,
            daysRemaining: daysRemaining,
            useCount: useCount,
            costPerUse: purchase.costPerUse
        )
    }
}
