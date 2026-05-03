import Foundation

// ─────────────────────────────────────────────
// MARK: - Configuration
// ─────────────────────────────────────────────
/// Change this to your backend URL before running.
/// e.g. "https://your-railway-app.up.railway.app"
enum Config {
    static let baseURL = "http://localhost:5000"
}

// ─────────────────────────────────────────────
// MARK: - API Errors
// ─────────────────────────────────────────────
enum APIError: LocalizedError {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(String)
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid URL."
        case .noData:               return "No data received."
        case .decodingError(let e): return "Decode error: \(e.localizedDescription)"
        case .serverError(let m):   return m
        case .unauthorized:         return "Session expired. Please log in again."
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - APIService
// ─────────────────────────────────────────────
class APIService {
    static let shared = APIService()
    private init() {}

    var authToken: String? {
        get { UserDefaults.standard.string(forKey: "finflow_token") }
        set { UserDefaults.standard.setValue(newValue, forKey: "finflow_token") }
    }

    // MARK: Core request
    func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: Config.baseURL + path) else { throw APIError.invalidURL }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if let body = body {
            req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await URLSession.shared.data(for: req)

        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            throw APIError.unauthorized
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: DELETE helper (returns GenericResponse)
    func delete(path: String) async throws -> GenericResponse {
        try await request(path: path, method: "DELETE")
    }
}

// ─────────────────────────────────────────────
// MARK: - Auth Endpoints
// ─────────────────────────────────────────────
extension APIService {
    func login(email: String, password: String) async throws -> AuthResponse {
        try await request(
            path: "/api/auth/login",
            method: "POST",
            body: ["email": email, "password": password],
            requiresAuth: false
        )
    }

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        try await request(
            path: "/api/auth/register",
            method: "POST",
            body: ["name": name, "email": email, "password": password],
            requiresAuth: false
        )
    }

    func getMe() async throws -> AuthResponse {
        try await request(path: "/api/auth/me")
    }

    func updateProfile(_ updates: [String: Any]) async throws -> AuthResponse {
        try await request(path: "/api/auth/profile", method: "PUT", body: updates)
    }

    func changePassword(current: String, new: String) async throws -> GenericResponse {
        try await request(
            path: "/api/auth/change-password",
            method: "PUT",
            body: ["currentPassword": current, "newPassword": new]
        )
    }

    func forgotPassword(email: String) async throws -> GenericResponse {
        try await request(
            path: "/api/auth/forgot-password",
            method: "POST",
            body: ["email": email],
            requiresAuth: false
        )
    }
}

// ─────────────────────────────────────────────
// MARK: - Transaction Endpoints
// ─────────────────────────────────────────────
extension APIService {
    func getTransactions(
        type: String? = nil,
        category: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil
    ) async throws -> TransactionsResponse {
        var params: [String] = []
        if let t = type        { params.append("type=\(t)") }
        if let c = category    { params.append("category=\(c)") }
        if let s = startDate   { params.append("startDate=\(s)") }
        if let e = endDate     { params.append("endDate=\(e)") }
        let qs = params.isEmpty ? "" : "?" + params.joined(separator: "&")
        return try await request(path: "/api/transactions\(qs)")
    }

    func createTransaction(
        type: String, description: String, amount: Double,
        category: String, date: String, note: String
    ) async throws -> SingleTransactionResponse {
        try await request(
            path: "/api/transactions",
            method: "POST",
            body: ["type": type, "description": description,
                   "amount": amount, "category": category,
                   "date": date, "note": note]
        )
    }

    func deleteTransaction(id: Int) async throws -> GenericResponse {
        try await delete(path: "/api/transactions/\(id)")
    }
}

// ─────────────────────────────────────────────
// MARK: - Budget Endpoints
// ─────────────────────────────────────────────
extension APIService {
    func getBudgets(month: Int? = nil, year: Int? = nil) async throws -> BudgetsResponse {
        var params: [String] = []
        if let m = month { params.append("month=\(m)") }
        if let y = year  { params.append("year=\(y)") }
        let qs = params.isEmpty ? "" : "?" + params.joined(separator: "&")
        return try await request(path: "/api/budgets\(qs)")
    }

    func createBudget(
        name: String, emoji: String, totalAmount: Double,
        category: String, month: Int, year: Int
    ) async throws -> SingleBudgetResponse {
        try await request(
            path: "/api/budgets",
            method: "POST",
            body: ["name": name, "emoji": emoji, "totalAmount": totalAmount,
                   "category": category, "month": month, "year": year]
        )
    }

    func deleteBudget(id: Int) async throws -> GenericResponse {
        try await delete(path: "/api/budgets/\(id)")
    }
}

// ─────────────────────────────────────────────
// MARK: - Notification Endpoints
// ─────────────────────────────────────────────
extension APIService {
    func getNotifications() async throws -> NotificationsResponse {
        try await request(path: "/api/notifications")
    }

    func markAllNotificationsRead() async throws -> GenericResponse {
        try await request(path: "/api/notifications/read-all", method: "PUT")
    }

    func deleteNotification(id: Int) async throws -> GenericResponse {
        try await delete(path: "/api/notifications/\(id)")
    }
}

// ─────────────────────────────────────────────
// MARK: - Dashboard Endpoints
// ─────────────────────────────────────────────
extension APIService {
    func getDashboard(period: String = "monthly") async throws -> DashboardResponse {
        try await request(path: "/api/dashboard/summary?period=\(period)")
    }
}
