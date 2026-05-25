import Foundation

@Observable
final class UsageTracker {
    var usageCountThisMonth: Int = 0
    var freeLimit: Int { PurchaseManager.shared.freeMonthlyLimit }

    private let defaults = UserDefaults.standard
    private let usageCountKey = "usageCount"
    private let usageMonthKey = "usageMonth"

    static let shared = UsageTracker()

    init() {
        loadUsage()
    }

    var remainingFreeUses: Int {
        if PurchaseManager.shared.isPro { return -1 }
        return max(0, freeLimit - usageCountThisMonth)
    }

    var hasFreeUsesLeft: Bool {
        if PurchaseManager.shared.isPro { return true }
        return usageCountThisMonth < freeLimit
    }

    var isLimitReached: Bool {
        if PurchaseManager.shared.isPro { return false }
        return usageCountThisMonth >= freeLimit
    }

    func incrementUsage() {
        if PurchaseManager.shared.isPro { return }
        ensureCurrentMonth()
        usageCountThisMonth += 1
        defaults.set(usageCountThisMonth, forKey: usageCountKey)
    }

    private func ensureCurrentMonth() {
        let currentMonth = Calendar.current.component(.month, from: Date())
        let currentYear = Calendar.current.component(.year, from: Date())
        let storedMonth = defaults.integer(forKey: usageMonthKey)
        let storedYear = defaults.object(forKey: usageMonthKey + "_year") as? Int ?? 0

        if currentMonth != storedMonth || currentYear != storedYear {
            usageCountThisMonth = 0
            defaults.set(0, forKey: usageCountKey)
            defaults.set(currentMonth, forKey: usageMonthKey)
            defaults.set(currentYear, forKey: usageMonthKey + "_year")
        }
    }

    private func loadUsage() {
        ensureCurrentMonth()
        usageCountThisMonth = defaults.integer(forKey: usageCountKey)
    }
}
