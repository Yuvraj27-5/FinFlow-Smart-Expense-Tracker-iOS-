import SwiftUI

// MARK: - NotificationsView
struct NotificationsView: View {
    @EnvironmentObject var notifVM: NotificationsViewModel
    @State private var deleteId: Int? = nil
    @State private var showDeleteConfirm = false

    var body: some View {
        NavigationStack {
            Group {
                if notifVM.isLoading {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if notifVM.notifications.isEmpty {
                    ContentUnavailableView("No Notifications", systemImage: "bell.slash")
                } else {
                    List {
                        ForEach(notifVM.notifications) { notif in
                            NotificationRow(notif: notif)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteId = notif.id; showDeleteConfirm = true
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                if notifVM.unreadCount > 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Mark All Read") { notifVM.markAllRead() }.font(.subheadline)
                    }
                }
            }
            .alert("Delete Notification?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let id = deleteId { Task { await notifVM.delete(id: id) } }
                }
                Button("Cancel", role: .cancel) {}
            } message: { Text("This notification will be permanently removed.") }
            .onAppear { notifVM.load() }
        }
    }
}

struct NotificationRow: View {
    let notif: AppNotification
    var rowColor: Color {
        switch notif.type {
        case "success": return .green
        case "warning": return .orange
        case "error":   return .red
        default:        return .blue
        }
    }
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(notif.displayIcon).font(.title2).frame(width: 40, height: 40)
                .background(rowColor.opacity(0.12), in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notif.title).font(.subheadline.bold()).lineLimit(1)
                    Spacer()
                    if notif.isRead != true { Circle().fill(Color.blue).frame(width: 8, height: 8) }
                }
                Text(notif.message).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                Text(notif.timeAgo).font(.caption2).foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4).opacity(notif.isRead == true ? 0.65 : 1)
    }
}

// MARK: - ProfileView (all features working)
struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var notifVM: NotificationsViewModel
    @State private var name          = ""
    @State private var occupation    = ""
    @State private var location      = ""
    @State private var phone         = ""
    @State private var financialGoal = ""
    @State private var currency      = "INR"
    @State private var currencySymbol = "₹"
    @State private var darkMode      = false
    @State private var monthlyBudget = ""

    @State private var showChangePassword  = false
    @State private var showLogoutConfirm   = false
    @State private var showEditProfile     = false
    @State private var showCurrencyPicker  = false
    @State private var showMonthlyBudget   = false
    @State private var showNotifications   = false

    private let currencies: [(String, String)] = [
        ("INR","₹"),("USD","$"),("EUR","€"),("GBP","£"),("JPY","¥"),
        ("AUD","A$"),("CAD","C$"),("SGD","S$"),("AED","د.إ")
    ]

    var body: some View {
        NavigationStack {
            List {
                // Avatar header
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [Color("AccentGreen"), Color(hex: "#30B050")],
                                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 80, height: 80)
                                Text(String(name.prefix(1)).uppercased())
                                    .font(.largeTitle.bold()).foregroundStyle(.white)
                            }
                            .shadow(color: Color("AccentGreen").opacity(0.4), radius: 8)
                            Text(name.isEmpty ? (authVM.user?.name ?? "") : name).font(.headline)
                            Text(authVM.user?.email ?? "").font(.caption).foregroundStyle(.secondary)
                            Text(authVM.user?.plan ?? "Free Plan")
                                .font(.caption.bold())
                                .padding(.horizontal, 12).padding(.vertical, 4)
                                .background(Color("AccentGreen").opacity(0.15), in: Capsule())
                                .foregroundStyle(Color("AccentGreen"))
                            // Edit Profile button
                            Button { showEditProfile = true } label: {
                                Label("Edit Profile", systemImage: "pencil")
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 20).padding(.vertical, 8)
                                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .listRowBackground(Color.clear)
                }

                // Personal info (read-only display)
                Section("Personal Information") {
                    InfoRow(icon: "person",    label: "Name",           value: name.isEmpty ? "Not set" : name)
                    InfoRow(icon: "briefcase", label: "Occupation",     value: occupation.isEmpty ? "Not set" : occupation)
                    InfoRow(icon: "location",  label: "Location",       value: location.isEmpty ? "Not set" : location)
                    InfoRow(icon: "phone",     label: "Phone",          value: phone.isEmpty ? "Not set" : phone)
                    InfoRow(icon: "target",    label: "Financial Goal", value: financialGoal.isEmpty ? "Not set" : financialGoal)
                }

                // Finance settings (tappable)
                Section("Finance Settings") {
                    // Currency picker (fully working)
                    Button { showCurrencyPicker = true } label: {
                        HStack {
                            Image(systemName: "coloncurrencysign.circle").foregroundStyle(.secondary).frame(width: 22)
                            Text("Currency").foregroundStyle(.primary)
                            Spacer()
                            Text("\(currencySymbol) \(currency)").foregroundStyle(.secondary)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    // Monthly budget (tappable - shows detail)
                    Button { showMonthlyBudget = true } label: {
                        HStack {
                            Image(systemName: "banknote").foregroundStyle(.secondary).frame(width: 22)
                            Text("Monthly Budget").foregroundStyle(.primary)
                            Spacer()
                            Text(monthlyBudget.isEmpty ? "Not set" : "₹\(monthlyBudget)").foregroundStyle(.secondary)
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    Toggle("Dark Mode", isOn: $darkMode)
                        .tint(Color("AccentGreen"))
                        .onChange(of: darkMode) { _ in saveProfile() }
                }

                if let msg = authVM.successMessage {
                    Section {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text(msg).font(.subheadline).foregroundStyle(.green)
                        }
                    }
                }

                // Actions
                Section {
                    Button { showChangePassword = true } label: {
                        Label("Change Password", systemImage: "lock.rotation")
                    }
                    Button(role: .destructive) { showLogoutConfirm = true } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right").foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button { showNotifications = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                            if notifVM.unreadCount > 0 {
                                ZStack {
                                    Circle().fill(Color.red).frame(width: 15, height: 15)
                                    Text("\(min(notifVM.unreadCount,9))").font(.system(size: 9, weight: .heavy)).foregroundStyle(.white)
                                }.offset(x: 6, y: -6)
                            }
                        }
                    }
                }
            }
            .onAppear { loadFromUser() }
            // Edit Profile sheet
            .sheet(isPresented: $showEditProfile, onDismiss: { loadFromUser() }) {
                EditProfileView(
                    name: name, occupation: occupation, location: location,
                    phone: phone, financialGoal: financialGoal
                ).environmentObject(authVM)
            }
            // Currency picker sheet
            .sheet(isPresented: $showCurrencyPicker) {
                CurrencyPickerView(currencies: currencies, selected: currency) { code, symbol in
                    currency = code; currencySymbol = symbol
                    saveProfile()
                }
            }
            // Monthly budget sheet
            .sheet(isPresented: $showMonthlyBudget) {
                MonthlyBudgetDetailView(budget: monthlyBudget) { newVal in
                    monthlyBudget = newVal
                    saveProfile()
                }
                .environmentObject(authVM)
            }
            .sheet(isPresented: $showChangePassword) { ChangePasswordView().environmentObject(authVM) }
            .sheet(isPresented: $showNotifications)   { NotificationsView().environmentObject(notifVM) }
            .confirmationDialog("Sign out of FinFlow?", isPresented: $showLogoutConfirm, titleVisibility: .visible) {
                Button("Sign Out", role: .destructive) { authVM.logout() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    func loadFromUser() {
        guard let u = authVM.user else { return }
        name = u.name; occupation = u.occupation ?? ""; location = u.location ?? ""
        phone = u.phone ?? ""; financialGoal = u.financialGoal ?? ""
        currency = u.currency ?? "INR"; currencySymbol = u.currencySymbol ?? "₹"
        darkMode = u.darkMode ?? false
        monthlyBudget = u.monthlyBudget.map { $0 > 0 ? String(Int($0)) : "" } ?? ""
    }

    func saveProfile() {
        Task {
            let _ = await authVM.updateProfile([
                "name": name, "occupation": occupation, "location": location,
                "phone": phone, "financialGoal": financialGoal,
                "currency": currency, "currencySymbol": currencySymbol,
                "darkMode": darkMode, "monthlyBudget": Double(monthlyBudget) ?? 0
            ])
        }
    }
}

// MARK: - InfoRow
struct InfoRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(.secondary).frame(width: 20)
            Text(label).foregroundStyle(.secondary).frame(width: 110, alignment: .leading)
            Text(value).foregroundStyle(.primary).lineLimit(1)
        }
    }
}

// MARK: - EditProfileView
struct EditProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State var name: String
    @State var occupation: String
    @State var location: String
    @State var phone: String
    @State var financialGoal: String

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    HStack(spacing: 12) {
                        Image(systemName: "person").foregroundStyle(.secondary)
                        TextField("Full Name", text: $name)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "briefcase").foregroundStyle(.secondary)
                        TextField("Occupation", text: $occupation)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "location").foregroundStyle(.secondary)
                        TextField("Location", text: $location)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "phone").foregroundStyle(.secondary)
                        TextField("Phone", text: $phone).keyboardType(.phonePad)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "target").foregroundStyle(.secondary)
                        TextField("Financial Goal", text: $financialGoal)
                    }
                }
                if let err = authVM.errorMessage { Section { ErrorBanner(message: err) } }
                if let msg = authVM.successMessage {
                    Section {
                        HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text(msg).foregroundStyle(.green) }
                    }
                }
                Section {
                    Button(action: save) {
                        if authVM.isLoading { ProgressView().frame(maxWidth: .infinity) }
                        else { Text("Save Changes").frame(maxWidth: .infinity) }
                    }
                    .buttonStyle(PrimaryButtonStyle()).disabled(name.isEmpty || authVM.isLoading)
                }
            }
            .navigationTitle("Edit Profile").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }

    func save() {
        Task {
            let ok = await authVM.updateProfile([
                "name": name, "occupation": occupation, "location": location,
                "phone": phone, "financialGoal": financialGoal
            ])
            if ok { DispatchQueue.main.asyncAfter(deadline: .now() + 1) { dismiss() } }
        }
    }
}

// MARK: - CurrencyPickerView
struct CurrencyPickerView: View {
    @Environment(\.dismiss) var dismiss
    let currencies: [(String, String)]
    let selected: String
    let onSelect: (String, String) -> Void

    var body: some View {
        NavigationStack {
            List(currencies, id: \.0) { code, sym in
                Button {
                    onSelect(code, sym); dismiss()
                } label: {
                    HStack {
                        Text("\(sym) \(code)").foregroundStyle(.primary)
                        Spacer()
                        if code == selected {
                            Image(systemName: "checkmark").foregroundStyle(Color("AccentGreen"))
                        }
                    }
                }
            }
            .navigationTitle("Select Currency").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

// MARK: - MonthlyBudgetDetailView
struct MonthlyBudgetDetailView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    let budget: String
    let onSave: (String) -> Void
    @State private var editedBudget: String

    init(budget: String, onSave: @escaping (String) -> Void) {
        self.budget = budget; self.onSave = onSave
        _editedBudget = State(initialValue: budget)
    }

    var budgetDouble: Double { Double(editedBudget) ?? 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Monthly Budget") {
                    if budget.isEmpty {
                        Text("No monthly budget set").foregroundStyle(.secondary)
                    } else {
                        HStack {
                            Text("Budget").foregroundStyle(.secondary)
                            Spacer()
                            Text("₹\(budget)").font(.headline).foregroundStyle(Color("AccentGreen"))
                        }
                        if let b = Double(budget), b > 0 {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Daily allowance").font(.caption).foregroundStyle(.secondary)
                                Text("₹\(formatAmount(b / 30))/day").font(.subheadline.bold()).foregroundStyle(.blue)
                            }
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Weekly allowance").font(.caption).foregroundStyle(.secondary)
                                Text("₹\(formatAmount(b / 4.3))/week").font(.subheadline.bold()).foregroundStyle(.purple)
                            }
                        }
                    }
                }
                Section("Update Budget") {
                    HStack(spacing: 12) {
                        Image(systemName: "indianrupeesign").foregroundStyle(.secondary)
                        TextField("Monthly Budget Amount", text: $editedBudget).keyboardType(.decimalPad)
                    }
                }
                Section {
                    Button(action: { onSave(editedBudget); dismiss() }) {
                        Text("Save Budget").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(editedBudget.isEmpty || budgetDouble <= 0)
                }
            }
            .navigationTitle("Monthly Budget").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }
}

// MARK: - ChangePasswordView
struct ChangePasswordView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var current = ""
    @State private var newPass = ""
    @State private var confirm = ""
    @State private var showCurrent = false
    @State private var showNew = false

    var mismatch: Bool { !newPass.isEmpty && !confirm.isEmpty && newPass != confirm }
    var isValid:  Bool { !current.isEmpty && newPass.count >= 6 && newPass == confirm }

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Password") {
                    FFSecureField(placeholder: "Current Password", text: $current, showPassword: $showCurrent)
                }
                Section("New Password") {
                    FFSecureField(placeholder: "New Password (min 6 chars)", text: $newPass, showPassword: $showNew)
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill").foregroundStyle(.secondary)
                        SecureField("Confirm Password", text: $confirm)
                    }
                    if mismatch { Text("Passwords do not match").font(.caption).foregroundStyle(.red) }
                }
                if let err = authVM.errorMessage { Section { ErrorBanner(message: err) } }
                if let msg = authVM.successMessage {
                    Section { HStack { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        Text(msg).foregroundStyle(.green) } }
                }
                Section {
                    Button(action: save) {
                        if authVM.isLoading { ProgressView().frame(maxWidth: .infinity) }
                        else { Text("Update Password").frame(maxWidth: .infinity) }
                    }
                    .disabled(!isValid || authVM.isLoading).buttonStyle(PrimaryButtonStyle())
                }
            }
            .navigationTitle("Change Password").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }

    func save() {
        Task {
            authVM.errorMessage = nil; authVM.successMessage = nil
            let ok = await authVM.changePassword(current: current, new: newPass)
            if ok { DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() } }
        }
    }
}

// MARK: - ProfileField (kept for backward compat)
struct ProfileField: View {
    let label: String; @Binding var value: String; let icon: String; let editable: Bool
    var body: some View {
        HStack {
            Image(systemName: icon).foregroundStyle(.secondary).frame(width: 20)
            if editable { TextField(label, text: $value) }
            else { Text(value.isEmpty ? label : value).foregroundStyle(value.isEmpty ? .secondary : .primary) }
        }
    }
}
