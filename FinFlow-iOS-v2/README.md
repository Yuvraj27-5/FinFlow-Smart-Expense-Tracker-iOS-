# FinFlow — iOS App

> **A beautifully crafted personal finance manager built natively for iPhone using Swift & SwiftUI.**  
> Track income, control spending, manage budgets, and visualise your financial health — all in one app.

---

## Features

### 🔐 Authentication
- **JWT-based login & registration** with persistent token storage via `UserDefaults`
- Secure password field with show/hide toggle
- **Forgot password** flow with email reset
- Animated entry screen with floating currency symbols and brand gradient

### 📊 Dashboard
- **Financial Health Score** — a single composite metric reflecting your money habits
- **3D Interactive Donut Chart** — tap slices to explore Savings vs Expenses breakdown, animated on load
- **Income & Expense summary cards** with period selector (Weekly / Monthly / Yearly)
- **Trend chart** showing income and expense lines over time
- **Budget summary strip** — quick overview of all active budgets
- Category breakdowns for both income and expenses

### 💸 Transactions
- Unified list of all income and expense entries
- **Segmented filter** — All / Income / Expenses
- Summary pill bar showing live totals and current balance
- **Swipe-to-delete** with confirmation dialog
- Add transactions with category (emoji-tagged), date, amount, and optional note
- Categories: Salary, Freelance, Investment, Bonus, Gift (income) · Food, Housing, Transport, Shopping, Entertainment, Utilities, Healthcare (expense)

### 💳 Budgets
- Create named budgets with emoji, category, total amount, and warning threshold
- **Color-coded progress bars**: green → orange (warning) → red (exceeded)
- Summary tiles: Total Budgeted · Total Spent · Remaining
- Swipe-to-delete with confirmation
- Budget cards show remaining amount and % used at a glance

### 🔔 Notifications
- Real-time unread **badge count** on the tab bar bell icon
- Notification types: success / warning / error / info — each with a distinct colour and icon
- Swipe-to-delete individual notifications
- **Mark All Read** toolbar action
- Relative timestamps (Just now / 5m ago / 2h ago / 3d ago)

### 👤 Profile
- Edit name, email, occupation, location, phone
- Set financial goal
- **Currency picker** — INR ₹, USD $, EUR €, GBP £, JPY ¥, and more
- **Dark Mode toggle** — syncs with system via `preferredColorScheme`
- Notification preferences: Email alerts, Budget warnings, Weekly/Monthly digests
- Secure **Change Password** sheet
- Logout with session clear

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Language | Swift 5.9+ |
| UI Framework | SwiftUI |
| Architecture | MVVM with `ObservableObject` |
| Networking | `URLSession` + `async/await` |
| State Sharing | `@EnvironmentObject` |
| Navigation | `NavigationStack` (iOS 16+) |
| Storage | `UserDefaults` (JWT token) |
| Dependencies | **Zero** — no SPM packages |

---

## Project Structure

```
FinFlow.xcodeproj/
└── FinFlow/
    ├── FinFlowApp.swift              ← App entry point + RootView (login / tab switcher)
    ├── Info.plist                    ← Permissions & ATS config
    ├── Assets.xcassets/
    │   └── AccentGreen.colorset      ← Brand green (#34CB60), light & dark variants
    │
    ├── Models/
    │   └── Models.swift              ← User, Transaction, Budget, AppNotification,
    │                                    DashboardSummary, all API response types
    │
    ├── Services/
    │   └── APIService.swift          ← Singleton REST client (URLSession, JWT headers,
    │                                    async/await, typed error handling)
    │
    ├── ViewModels/
    │   ├── AuthViewModel.swift       ← Login, register, forgot password, profile update,
    │                                    token persistence, logout
    │   └── ViewModels.swift          ← DashboardViewModel, TransactionsViewModel,
    │                                    BudgetViewModel, NotificationsViewModel
    │
    └── Views/
        ├── Auth/
        │   └── AuthViews.swift       ← LoginView, RegisterView, ForgotPasswordView
        ├── Dashboard/
        │   └── DashboardView.swift   ← MainTabView, DashboardView, DonutChart3D,
        │                                PieSliceShape, trend charts, summary cards
        ├── Transactions/
        │   └── TransactionsView.swift ← TransactionsView, TransactionRow,
        │                                 AddTransactionView, SummaryPill
        ├── Budgets/
        │   └── BudgetsView.swift     ← BudgetsView, BudgetCard, AddBudgetView,
        │                                BudgetSummaryTile
        ├── Profile/
        │   └── ProfileNotifViews.swift ← ProfileView, NotificationsView,
        │                                  NotificationRow, ChangePasswordView
        └── Components/
            └── Components.swift      ← Shared: GreenButton, DarkTextField,
                                         DarkSecureField, ToastView, card styles
```

---

## Requirements

| Tool | Minimum Version |
|------|----------------|
| Xcode | 15.0 |
| iOS Deployment Target | 17.0 |
| Swift | 5.9 |
| macOS (for Xcode) | 14.0 Sonoma |
| Backend | Node.js / Express / MySQL REST API |

---

## Getting Started

### 1. Configure your backend URL

Open `FinFlow/Services/APIService.swift` and update the base URL:

```swift
enum Config {
    static let baseURL = "https://your-production-url.up.railway.app"
    // Replace with your deployed backend URL
    // For local dev: "http://localhost:5000"
}
```

### 2. Open in Xcode

```bash
open FinFlow.xcodeproj
```

### 3. Select a target

Choose an iPhone simulator (iPhone 15 recommended) or a physical device.

### 4. Run

Press **⌘ R** or click the ▶ button.

---

## Architecture — MVVM

```
View  ──(reads)──▶  ViewModel  ──(calls)──▶  APIService
 │                      │                        │
 └──(triggers)──▶  @Published                URLSession
                   properties                async/await
```

- **Views** are pure SwiftUI — no business logic
- **ViewModels** own state and all async network calls
- **APIService** is a singleton that injects JWT headers automatically
- **`@EnvironmentObject`** passes `AuthViewModel` to every screen without prop-drilling
- **`NotificationCenter`** is used for cross-tab navigation (e.g., tapping a budget alert → jumps to Transactions tab)

---

## API Endpoints Used

| Feature | Method | Path |
|---------|--------|------|
| Login | POST | `/auth/login` |
| Register | POST | `/auth/register` |
| Forgot Password | POST | `/auth/forgot-password` |
| Get Profile | GET | `/users/profile` |
| Update Profile | PUT | `/users/profile` |
| Change Password | PUT | `/users/change-password` |
| Dashboard | GET | `/dashboard` |
| List Transactions | GET | `/transactions` |
| Add Transaction | POST | `/transactions` |
| Delete Transaction | DELETE | `/transactions/:id` |
| List Budgets | GET | `/budgets` |
| Add Budget | POST | `/budgets` |
| Delete Budget | DELETE | `/budgets/:id` |
| Notifications | GET | `/notifications` |
| Mark All Read | PUT | `/notifications/read-all` |
| Delete Notification | DELETE | `/notifications/:id` |

All requests send `Authorization: Bearer <token>` from `UserDefaults`.

---

## Supported Currencies

| Symbol | Currency |
|--------|----------|
| ₹ | Indian Rupee (INR) — default |
| $ | US Dollar (USD) |
| € | Euro (EUR) |
| £ | British Pound (GBP) |
| ¥ | Japanese Yen (JPY) |
| ₩ | Korean Won (KRW) |
| ฿ | Thai Baht (THB) |
| ₦ | Nigerian Naira (NGN) |

Currency symbol is stored on the user profile and applied across all views automatically.

---

## Pre-launch Checklist

- [ ] Replace `Config.baseURL` with your production HTTPS URL
- [ ] Remove `NSExceptionAllowsInsecureHTTPLoads` from `Info.plist` (localhost-only setting)
- [ ] Set `DEVELOPMENT_TEAM` in **Build Settings → Signing & Capabilities**
- [ ] Update Bundle ID from `com.yourcompany.finflow` to your own
- [ ] Add an **AppIcon** set to `Assets.xcassets`
- [ ] Test on a real device before App Store submission

---

## Author

**Yuvraj**  
Built natively for iPhone with Swift & SwiftUI  
