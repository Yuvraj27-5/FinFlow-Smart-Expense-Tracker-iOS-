import Foundation

// MARK: - User
struct User: Codable, Identifiable {
    let id: Int
    var name: String
    var email: String
    var plan: String?
    var currency: String?
    var currencySymbol: String?
    var darkMode: Bool?
    var financialGoal: String?
    var occupation: String?
    var location: String?
    var phone: String?
    var monthlyBudget: Double?
    var notifEmail: Bool?
    var notifBudget: Bool?
    var notifWeekly: Bool?
    var notifMonthly: Bool?

    var displayCurrency: String { currency ?? "INR" }
    var displaySymbol: String { currencySymbol ?? "₹" }
}

// MARK: - Transaction
struct Transaction: Codable, Identifiable {
    let id: Int
    let userId: Int
    var type: String       // "income" | "expense"
    var description: String
    var amount: Double
    var category: String
    var date: String
    var note: String?
    var createdAt: String?

    var isIncome: Bool { type == "income" }

    var categoryEmoji: String {
        switch category {
        case "Salary": return "💼"
        case "Freelance": return "💻"
        case "Investment": return "📈"
        case "Bonus": return "🎁"
        case "Gift": return "🎀"
        case "Food": return "🍔"
        case "Housing": return "🏠"
        case "Transport": return "🚗"
        case "Shopping": return "🛍"
        case "Entertainment": return "🎬"
        case "Utilities": return "💡"
        case "Healthcare": return "🏥"
        default: return isIncome ? "💰" : "💸"
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let d = formatter.date(from: date) {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: d)
        }
        return date
    }
}

// MARK: - Budget
struct Budget: Codable, Identifiable {
    let id: Int
    let userId: Int
    var name: String
    var emoji: String?
    var totalAmount: Double
    var spent: Double
    var category: String?
    var month: Int?
    var year: Int?
    var warningThreshold: Int?

    var remaining: Double { max(0, totalAmount - spent) }
    var percentUsed: Double { totalAmount > 0 ? min((spent / totalAmount) * 100, 100) : 0 }
    var isExceeded: Bool { spent > totalAmount }
    var isWarning: Bool { percentUsed >= Double(warningThreshold ?? 80) && !isExceeded }
    var displayEmoji: String { emoji ?? "💰" }
}

// MARK: - AppNotification
struct AppNotification: Codable, Identifiable {
    let id: Int
    let userId: Int
    var title: String
    var message: String
    var type: String   // "success" | "warning" | "error" | "info"
    var icon: String?
    var isRead: Bool?
    var createdAt: String?

    var displayIcon: String { icon ?? "🔔" }

    var timeAgo: String {
        guard let dateStr = createdAt else { return "" }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateStr) else { return "" }
        let diff = Date().timeIntervalSince(date)
        if diff < 60 { return "Just now" }
        if diff < 3600 { return "\(Int(diff/60))m ago" }
        if diff < 86400 { return "\(Int(diff/3600))h ago" }
        return "\(Int(diff/86400))d ago"
    }
}

// MARK: - Dashboard
struct DashboardSummary: Codable {
    var totalIncome: Double?
    var totalExpenses: Double?
    var balance: Double?
    var savingsRate: Double?
    var healthScore: Double?
    var incomeByCategory: [CategoryStat]?
    var expenseByCategory: [CategoryStat]?
    var trend: [TrendPoint]?
    var budgetsSummary: [Budget]?
}

struct CategoryStat: Codable, Identifiable {
    var id: String { category }
    var category: String
    var total: Double
}

struct TrendPoint: Codable {
    var year: Int
    var month: Int
    var type: String
    var total: Double

    var monthLabel: String {
        let months = ["","Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        return months[safe: month] ?? "\(month)"
    }
}

// MARK: - API Responses
struct AuthResponse: Codable {
    var success: Bool
    var token: String?
    var user: User?
    var message: String?
}

struct TransactionsResponse: Codable {
    var success: Bool
    var data: [Transaction]?
    var total: Int?
    var message: String?
}

struct SingleTransactionResponse: Codable {
    var success: Bool
    var data: Transaction?
    var message: String?
}

struct BudgetsResponse: Codable {
    var success: Bool
    var data: [Budget]?
    var message: String?
}

struct SingleBudgetResponse: Codable {
    var success: Bool
    var data: Budget?
    var message: String?
}

struct NotificationsResponse: Codable {
    var success: Bool
    var data: [AppNotification]?
    var unreadCount: Int?
    var message: String?
}

struct DashboardResponse: Codable {
    var success: Bool
    var data: DashboardSummary?
    var message: String?
}

struct GenericResponse: Codable {
    var success: Bool
    var message: String?
}

// MARK: - Helpers
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Categories
enum IncomeCategory: String, CaseIterable {
    case salary = "Salary", freelance = "Freelance", investment = "Investment"
    case bonus = "Bonus", gift = "Gift", other = "Other"
}

enum ExpenseCategory: String, CaseIterable {
    case food = "Food", housing = "Housing", transport = "Transport"
    case shopping = "Shopping", entertainment = "Entertainment"
    case utilities = "Utilities", healthcare = "Healthcare", other = "Other"
}
