import Foundation
import Combine

// ─────────────────────────────────────────────
// MARK: - DashboardViewModel
// ─────────────────────────────────────────────
@MainActor
class DashboardViewModel: ObservableObject {
    @Published var summary: DashboardSummary?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedPeriod = "monthly"

    private let api = APIService.shared
    private var task: Task<Void, Never>?

    func load() {
        task?.cancel()
        task = Task {
            isLoading = true; errorMessage = nil
            do {
                let res = try await api.getDashboard(period: selectedPeriod)
                if res.success { summary = res.data }
                else { errorMessage = res.message }
            } catch { errorMessage = error.localizedDescription }
            isLoading = false
        }
    }

    func setPeriod(_ period: String) {
        selectedPeriod = period
        load()
    }
}

// ─────────────────────────────────────────────
// MARK: - TransactionsViewModel
// ─────────────────────────────────────────────
@MainActor
class TransactionsViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published var filterType: String? = nil
    @Published var filterCategory: String? = nil
    @Published var filterStart: String? = nil
    @Published var filterEnd: String? = nil

    private let api = APIService.shared

    func load() {
        Task {
            isLoading = true; errorMessage = nil
            do {
                let res = try await api.getTransactions(
                    type: filterType,
                    category: filterCategory,
                    startDate: filterStart,
                    endDate: filterEnd
                )
                if res.success { transactions = res.data ?? [] }
                else { errorMessage = res.message }
            } catch { errorMessage = error.localizedDescription }
            isLoading = false
        }
    }

    func add(
        type: String, description: String, amount: Double,
        category: String, date: String, note: String
    ) async -> Bool {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let res = try await api.createTransaction(
                type: type, description: description, amount: amount,
                category: category, date: date, note: note
            )
            if res.success {
                successMessage = "\(type == "income" ? "Income" : "Expense") added!"
                load()
                return true
            } else { errorMessage = res.message ?? "Failed." }
        } catch { errorMessage = error.localizedDescription }
        return false
    }

    func delete(id: Int) async {
        do {
            let _ = try await api.deleteTransaction(id: id)
            transactions.removeAll { $0.id == id }
        } catch { errorMessage = error.localizedDescription }
    }

    var incomeTotal: Double {
        transactions.filter { $0.isIncome }.reduce(0) { $0 + $1.amount }
    }
    var expenseTotal: Double {
        transactions.filter { !$0.isIncome }.reduce(0) { $0 + $1.amount }
    }
    var balance: Double { incomeTotal - expenseTotal }
}

// ─────────────────────────────────────────────
// MARK: - BudgetViewModel
// ─────────────────────────────────────────────
@MainActor
class BudgetViewModel: ObservableObject {
    @Published var budgets: [Budget] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let api = APIService.shared

    func load() {
        Task {
            isLoading = true; errorMessage = nil
            do {
                let now = Calendar.current.dateComponents([.month, .year], from: Date())
                let res = try await api.getBudgets(month: now.month, year: now.year)
                if res.success { budgets = res.data ?? [] }
                else { errorMessage = res.message }
            } catch { errorMessage = error.localizedDescription }
            isLoading = false
        }
    }

    func add(name: String, emoji: String, totalAmount: Double, category: String) async -> Bool {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let now = Calendar.current.dateComponents([.month, .year], from: Date())
            let res = try await api.createBudget(
                name: name, emoji: emoji, totalAmount: totalAmount,
                category: category,
                month: now.month ?? 1, year: now.year ?? 2025
            )
            if res.success {
                successMessage = "Budget created!"
                load()
                return true
            } else { errorMessage = res.message ?? "Failed." }
        } catch { errorMessage = error.localizedDescription }
        return false
    }

    func delete(id: Int) async {
        do {
            let _ = try await api.deleteBudget(id: id)
            budgets.removeAll { $0.id == id }
        } catch { errorMessage = error.localizedDescription }
    }

    var totalBudgeted: Double { budgets.reduce(0) { $0 + $1.totalAmount } }
    var totalSpent: Double    { budgets.reduce(0) { $0 + $1.spent } }
    var totalRemaining: Double { budgets.reduce(0) { $0 + $1.remaining } }
}

// ─────────────────────────────────────────────
// MARK: - NotificationsViewModel
// ─────────────────────────────────────────────
@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var unreadCount = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let api = APIService.shared

    func load() {
        Task {
            isLoading = true
            do {
                let res = try await api.getNotifications()
                if res.success {
                    notifications = res.data ?? []
                    unreadCount   = res.unreadCount ?? 0
                }
            } catch { errorMessage = error.localizedDescription }
            isLoading = false
        }
    }

    func markAllRead() {
        Task {
            do {
                let _ = try await api.markAllNotificationsRead()
                for i in notifications.indices { notifications[i].isRead = true }
                unreadCount = 0
            } catch {}
        }
    }

    func delete(id: Int) async {
        do {
            let _ = try await api.deleteNotification(id: id)
            notifications.removeAll { $0.id == id }
        } catch { errorMessage = error.localizedDescription }
    }
}
