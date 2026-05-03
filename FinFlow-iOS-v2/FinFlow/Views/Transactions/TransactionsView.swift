import SwiftUI

// MARK: - TransactionsView
struct TransactionsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var notifVM: NotificationsViewModel
    @StateObject private var vm = TransactionsViewModel()
    @State private var showAdd = false
    @State private var addType: String = "expense"
    @State private var selectedFilter: String? = nil
    @State private var deleteCandidateId: Int? = nil
    @State private var deleteCandidateDesc: String = ""
    @State private var showDeleteConfirm = false
    @State private var showNotifications = false

    var symbol: String { authVM.user?.displaySymbol ?? "₹" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary bar
                HStack(spacing: 0) {
                    SummaryPill(label: "Income",   value: "\(symbol)\(formatAmount(vm.incomeTotal))", color: .green)
                    Divider().frame(height: 40)
                    SummaryPill(label: "Expenses", value: "\(symbol)\(formatAmount(vm.expenseTotal))", color: .red)
                    Divider().frame(height: 40)
                    SummaryPill(label: "Balance",  value: "\(symbol)\(formatAmount(vm.balance))",
                                color: vm.balance >= 0 ? .blue : .red)
                }
                .background(.regularMaterial)

                // Filter tabs
                Picker("Filter", selection: $selectedFilter) {
                    Text("All").tag(String?.none)
                    Text("Income").tag(Optional("income"))
                    Text("Expenses").tag(Optional("expense"))
                }
                .pickerStyle(.segmented).padding(.horizontal).padding(.vertical, 8)
                .onChange(of: selectedFilter) { val in vm.filterType = val; vm.load() }

                if vm.isLoading {
                    Spacer(); ProgressView(); Spacer()
                } else if vm.transactions.isEmpty {
                    ContentUnavailableView("No Transactions", systemImage: "arrow.left.arrow.right",
                        description: Text("Tap + to add your first transaction."))
                } else {
                    List {
                        ForEach(vm.transactions) { tx in
                            TransactionRow(tx: tx, symbol: symbol)
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        deleteCandidateId = tx.id
                                        deleteCandidateDesc = tx.description
                                        showDeleteConfirm = true
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                                // Cross button via context menu too
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteCandidateId = tx.id
                                        deleteCandidateDesc = tx.description
                                        showDeleteConfirm = true
                                    } label: { Label("Delete Transaction", systemImage: "trash") }
                                }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Transactions")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    // Bell
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
                    Menu {
                        Button { addType = "income";  showAdd = true } label: { Label("Add Income",  systemImage: "plus.circle.fill") }
                        Button { addType = "expense"; showAdd = true } label: { Label("Add Expense", systemImage: "minus.circle.fill") }
                    } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: { vm.load() }) {
                AddTransactionView(initialType: addType).environmentObject(authVM)
            }
            .sheet(isPresented: $showNotifications) { NotificationsView().environmentObject(notifVM) }
            .alert("Delete Transaction?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let id = deleteCandidateId { Task { await vm.delete(id: id) } }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \"\(deleteCandidateDesc)\"? This action cannot be undone.")
            }
            .onAppear { vm.load() }
        }
    }
}

// MARK: - TransactionRow
struct TransactionRow: View {
    let tx: Transaction
    let symbol: String
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(tx.isIncome ? Color.green.opacity(0.15) : Color.red.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(tx.categoryEmoji).font(.title3)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(tx.description).font(.subheadline.bold()).lineLimit(1)
                HStack(spacing: 6) {
                    Text(tx.category).font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(categoryColor(tx.category).opacity(0.15), in: Capsule())
                        .foregroundStyle(categoryColor(tx.category))
                    Text(tx.formattedDate).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text("\(tx.isIncome ? "+" : "-")\(symbol)\(formatAmount(tx.amount))")
                .font(.subheadline.bold()).foregroundStyle(tx.isIncome ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - AddTransactionView (fixed form - no black boxes)
struct AddTransactionView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = TransactionsViewModel()
    @Environment(\.dismiss) var dismiss

    let initialType: String
    @State private var type: String
    @State private var descriptionText = ""
    @State private var amountStr = ""
    @State private var category = ""
    @State private var date = Date()
    @State private var note = ""

    init(initialType: String) {
        self.initialType = initialType
        _type     = State(initialValue: initialType)
        _category = State(initialValue: initialType == "income" ? "Salary" : "Food")
    }

    var categories: [String] {
        type == "income" ? IncomeCategory.allCases.map(\.rawValue) : ExpenseCategory.allCases.map(\.rawValue)
    }
    var isValid: Bool { !descriptionText.isEmpty && (Double(amountStr) ?? 0) > 0 && !category.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                // TYPE
                Section {
                    Picker("Transaction Type", selection: $type) {
                        Text("💰 Income").tag("income")
                        Text("💸 Expense").tag("expense")
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { _ in category = type == "income" ? "Salary" : "Food" }
                } header: { Text("TYPE") }

                // DETAILS
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "pencil").foregroundStyle(.secondary)
                        TextField("Description", text: $descriptionText)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "indianrupeesign").foregroundStyle(.secondary)
                        TextField("Amount", text: $amountStr).keyboardType(.decimalPad)
                    }
                } header: { Text("DETAILS") }

                // CATEGORY
                Section {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                } header: { Text("CATEGORY") }

                // DATE & NOTE
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Note (optional)", text: $note, axis: .vertical).lineLimit(3)
                } header: { Text("DATE & NOTE") }

                if let err = vm.errorMessage { Section { ErrorBanner(message: err) } }

                Section {
                    Button(action: save) {
                        if vm.isLoading { ProgressView().frame(maxWidth: .infinity) }
                        else { Label("Save Transaction", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity) }
                    }
                    .disabled(!isValid || vm.isLoading)
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .navigationTitle(type == "income" ? "Add Income" : "Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        }
        .colorScheme(.light)
    }

    func save() {
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"
        Task {
            let ok = await vm.add(type: type, description: descriptionText,
                                  amount: Double(amountStr) ?? 0,
                                  category: category, date: fmt.string(from: date), note: note)
            if ok { dismiss() }
        }
    }
}

// MARK: - SummaryPill
struct SummaryPill: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 8)
    }
}