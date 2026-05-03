import Foundation
import Combine

@MainActor
class AuthViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let api = APIService.shared

    init() {
        // Auto-login if token exists
        if api.authToken != nil {
            Task { await fetchMe() }
        }
    }

    // MARK: - Login
    func login(email: String, password: String) async {
        isLoading = true; errorMessage = nil
        do {
            let res = try await api.login(email: email, password: password)
            if res.success, let token = res.token, let usr = res.user {
                api.authToken = token
                user = usr
                isLoggedIn = true
            } else {
                errorMessage = res.message ?? "Login failed."
            }
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // MARK: - Register
    func register(name: String, email: String, password: String) async {
        isLoading = true; errorMessage = nil
        do {
            let res = try await api.register(name: name, email: email, password: password)
            if res.success, let token = res.token, let usr = res.user {
                api.authToken = token
                user = usr
                isLoggedIn = true
            } else {
                errorMessage = res.message ?? "Registration failed."
            }
        } catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    // MARK: - Fetch Me
    func fetchMe() async {
        do {
            let res = try await api.getMe()
            if res.success, let usr = res.user {
                user = usr
                isLoggedIn = true
            } else {
                logout()
            }
        } catch APIError.unauthorized { logout() }
        catch { /* silent */ }
    }

    // MARK: - Update Profile
    func updateProfile(_ updates: [String: Any]) async -> Bool {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let res = try await api.updateProfile(updates)
            if res.success, let usr = res.user {
                user = usr
                successMessage = "Profile updated."
                return true
            } else {
                errorMessage = res.message ?? "Update failed."
            }
        } catch { errorMessage = error.localizedDescription }
        return false
    }

    // MARK: - Change Password
    func changePassword(current: String, new: String) async -> Bool {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let res = try await api.changePassword(current: current, new: new)
            if res.success {
                successMessage = res.message ?? "Password changed."
                return true
            } else { errorMessage = res.message ?? "Failed." }
        } catch { errorMessage = error.localizedDescription }
        return false
    }

    // MARK: - Forgot Password
    func forgotPassword(email: String) async -> Bool {
        isLoading = true; errorMessage = nil
        defer { isLoading = false }
        do {
            let res = try await api.forgotPassword(email: email)
            successMessage = res.message ?? "Reset email sent."
            return res.success
        } catch { errorMessage = error.localizedDescription }
        return false
    }

    // MARK: - Logout
    func logout() {
        api.authToken = nil
        user = nil
        isLoggedIn = false
    }
}
