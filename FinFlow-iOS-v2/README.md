# FinFlow iOS — Swift / SwiftUI

A native iOS app converted from the original FinFlow web project  
(Node.js + Express + MySQL + Vanilla JS → **Swift + SwiftUI**).

---

## Project Structure

```
FinFlow-iOS/
├── FinFlow.xcodeproj/          ← Open this in Xcode
│   └── project.pbxproj
└── FinFlow/
    ├── FinFlowApp.swift         ← App entry point + RootView
    ├── Info.plist               ← Permissions, ATS config
    ├── Assets.xcassets/
    │   └── AccentGreen.colorset ← Brand green (#34CB60)
    ├── Models/
    │   └── Models.swift         ← User, Transaction, Budget, Notification, API responses
    ├── Services/
    │   └── APIService.swift     ← All REST calls (async/await + URLSession)
    ├── ViewModels/
    │   ├── AuthViewModel.swift  ← Login, register, profile, JWT token
    │   └── ViewModels.swift     ← Dashboard, Transactions, Budget, Notifications VMs
    └── Views/
        ├── Auth/
        │   └── AuthViews.swift  ← LoginView, RegisterView, ForgotPasswordView
        ├── Dashboard/
        │   └── DashboardView.swift
        ├── Transactions/
        │   └── TransactionsView.swift
        ├── Budgets/
        │   └── BudgetsView.swift
        ├── Profile/
        │   └── ProfileNotifViews.swift
        └── Components/
            └── Components.swift ← Shared UI (buttons, text fields, cards, toast)
```

---

## Requirements

| Tool | Version |
|------|---------|
| Xcode | 15.0+ |
| iOS Deployment Target | 17.0+ |
| Swift | 5.9+ |
| Backend | Your existing Node.js/Express/MySQL server |

No third-party Swift packages required — uses only SwiftUI + URLSession.

---

## Setup

### Step 1 — Set your backend URL

Open `FinFlow/Services/APIService.swift` and change:

```swift
enum Config {
    static let baseURL = "http://localhost:5000"
    //                    ↑ Replace with your Railway / production URL
    // e.g. "https://finflow-production.up.railway.app"
}
```

### Step 2 — Start your backend

```bash
cd backend
npm install
npm start
```

### Step 3 — Open in Xcode

```bash
open FinFlow.xcodeproj
```

Then select your simulator or device and hit **⌘R**.

---

## Features Converted

| Feature | Android/Web | iOS (Swift) |
|---------|-------------|-------------|
| Auth | JWT login/register/forgot password | ✅ Identical API calls |
| Dashboard | Health score, charts, summary cards | ✅ Native SwiftUI |
| Income Tracker | Add/delete/filter | ✅ Swipe-to-delete |
| Expense Tracker | Add/delete/filter/categories | ✅ |
| Budget Manager | Create, progress bar, warnings | ✅ Color-coded cards |
| Notifications | Bell badge, mark read, delete | ✅ Tab badge count |
| Profile | Edit info, currency, dark mode | ✅ |
| Change Password | Secure update | ✅ |
| Period Filter | Weekly / Monthly / Yearly | ✅ |
| Dark Mode | System toggle | ✅ |
| Multi-currency | INR, USD, EUR, GBP, JPY… | ✅ |

---

## Architecture

- **MVVM** — each screen has its own `ObservableObject` ViewModel
- **async/await** — all network calls are modern Swift concurrency
- **@EnvironmentObject** — `AuthViewModel` shared across all tabs
- **SwiftUI NavigationStack** — iOS 16+ navigation
- **No third-party packages** — zero dependencies

---

## Production Checklist

- [ ] Replace `Config.baseURL` with your production HTTPS URL
- [ ] Remove `NSExceptionAllowsInsecureHTTPLoads` from Info.plist (localhost only)
- [ ] Set `DEVELOPMENT_TEAM` in Build Settings → Signing
- [ ] Change `com.yourcompany.finflow` to your actual Bundle ID
- [ ] Add an AppIcon to Assets.xcassets

---

## Backend (unchanged)

The Node.js/Express/MySQL backend is **completely unchanged** — the iOS app
consumes the exact same REST API. You can run both simultaneously:
web users use the browser frontend, iOS users use this Swift app.

---

## Author

Converted from FinFlow by Yuvraj  
Original: Node.js + Express + MySQL + Vanilla JS  
iOS Port: Swift + SwiftUI + URLSession
