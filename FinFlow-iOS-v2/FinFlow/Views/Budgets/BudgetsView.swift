import SwiftUI

// MARK: - BudgetsView
struct BudgetsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var notifVM: NotificationsViewModel
    @StateObject private var vm = BudgetViewModel()
    @State private var showAdd = false
    @State private var deleteCandidateId: Int? = nil
    @State private var deleteCandidateName: String = ""
    @State private var showDeleteConfirm = false
    @State private var showNotifications = false

    var symbol: String { authVM.user?.displaySymbol ?? "₹" }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Summary tiles
                    HStack(spacing: 12) {
                        BudgetSummaryTile(label: "Budgeted",  value: "\(symbol)\(formatAmount(vm.totalBudgeted))",  color: .blue)
                        BudgetSummaryTile(label: "Spent",     value: "\(symbol)\(formatAmount(vm.totalSpent))",     color: .red)
                        BudgetSummaryTile(label: "Remaining", value: "\(symbol)\(formatAmount(vm.totalRemaining))", color: .green)
                    }.padding(.horizontal)

                    if vm.isLoading {
                        ProgressView().padding(40)
                    } else if vm.budgets.isEmpty {
                        ContentUnavailableView("No Budgets", systemImage: "creditcard",
                            description: Text("Tap + to create your first budget.")).padding(.top, 40)
                    } else {
                        LazyVStack(spacing: 14) {
                            ForEach(vm.budgets) { budget in
                                BudgetCard(budget: budget, symbol: symbol) {
                                    deleteCandidateId = budget.id
                                    deleteCandidateName = budget.name
                                    showDeleteConfirm = true
                                }
                            }
                        }.padding(.horizontal)
                    }
                }.padding(.vertical)
            }
            .navigationTitle("Budgets")
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
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd, onDismiss: { vm.load() }) {
                AddBudgetView().environmentObject(authVM)
            }
            .sheet(isPresented: $showNotifications) { NotificationsView().environmentObject(notifVM) }
            .alert("Delete Budget?", isPresented: $showDeleteConfirm) {
                Button("Delete", role: .destructive) {
                    if let id = deleteCandidateId { Task { await vm.delete(id: id) } }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \"\(deleteCandidateName)\"? This cannot be undone.")
            }
            .onAppear { vm.load() }
        }
    }
}

// MARK: - BudgetCard
struct BudgetCard: View {
    let budget: Budget
    let symbol: String
    let onDelete: () -> Void

    var statusColor: Color { budget.isExceeded ? .red : budget.isWarning ? .orange : Color("AccentGreen") }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(categoryColor(budget.category ?? "").opacity(0.15))
                            .frame(width: 38, height: 38)
                        Text(budget.displayEmoji).font(.title3)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(budget.name).font(.headline)
                        Text(budget.category ?? "General").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                HStack(spacing: 8) {
                    if budget.isExceeded {
                        Label("Exceeded", systemImage: "exclamationmark.triangle.fill")
                            .font(.caption).foregroundStyle(.red)
                    } else if budget.isWarning {
                        Label("\(Int(budget.percentUsed))%", systemImage: "exclamationmark.circle.fill")
                            .font(.caption).foregroundStyle(.orange)
                    }
                    // Delete button (X)
                    Button(action: onDelete) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary).font(.title3)
                    }
                    .buttonStyle(.plain)
                }
            }

            ProgressView(value: budget.percentUsed, total: 100)
                .tint(statusColor)
                .scaleEffect(x: 1, y: 2, anchor: .center)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Remaining").font(.caption2).foregroundStyle(.secondary)
                    Text("\(symbol)\(formatAmount(budget.remaining))").font(.subheadline.bold()).foregroundStyle(statusColor)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Spent / Limit").font(.caption2).foregroundStyle(.secondary)
                    Text("\(symbol)\(formatAmount(budget.spent)) / \(symbol)\(formatAmount(budget.totalAmount))")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16)
            .stroke(budget.isExceeded ? Color.red.opacity(0.4) : Color.clear, lineWidth: 1.5))
    }
}

// MARK: - AddBudgetView (fixed form inputs)
struct AddBudgetView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = BudgetViewModel()
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var emoji = "💰"
    @State private var amountStr = ""
    @State private var category = "Food"

    let emojis = ["💰","🏠","🚗","🍔","🛍","🎬","💡","🏥","📚","✈️","🎮","💪"]
    let categories = ExpenseCategory.allCases.map(\.rawValue) + ["General"]

    var isValid: Bool { !name.isEmpty && (Double(amountStr) ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "tag").foregroundStyle(.secondary)
                        TextField("Budget Name (e.g. Monthly Food)", text: $name)
                    }
                    HStack(spacing: 12) {
                        Image(systemName: "indianrupeesign").foregroundStyle(.secondary)
                        TextField("Limit Amount", text: $amountStr).keyboardType(.decimalPad)
                    }
                } header: { Text("BUDGET INFO") }

                Section {
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { Text($0).tag($0) }
                    }
                    .onChange(of: category) { _ in autoSetEmoji() }
                } header: { Text("CATEGORY") }

                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(emojis, id: \.self) { e in
                                Button { emoji = e } label: {
                                    Text(e).font(.title2).padding(8)
                                        .background(emoji == e ? Color("AccentGreen").opacity(0.2) : Color(.systemGray6),
                                                    in: RoundedRectangle(cornerRadius: 8))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                } header: { Text("EMOJI") }

                if let err = vm.errorMessage { Section { ErrorBanner(message: err) } }

                Section {
                    Button(action: save) {
                        if vm.isLoading { ProgressView().frame(maxWidth: .infinity) }
                        else { Label("Create Budget", systemImage: "checkmark.circle.fill").frame(maxWidth: .infinity) }
                    }
                    .disabled(!isValid || vm.isLoading)
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .navigationTitle("New Budget").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .topBarLeading) { Button("Cancel") { dismiss() } } }
        }
    }

    func autoSetEmoji() {
        let map: [String: String] = ["Food":"🍔","Housing":"🏠","Transport":"🚗","Shopping":"🛍",
                                     "Entertainment":"🎬","Utilities":"💡","Healthcare":"🏥"]
        emoji = map[category] ?? "💰"
    }

    func save() {
        Task {
            let ok = await vm.add(name: name, emoji: emoji,
                                  totalAmount: Double(amountStr) ?? 0, category: category)
            if ok { dismiss() }
        }
    }
}

// MARK: - BudgetSummaryTile
struct BudgetSummaryTile: View {
    let label: String; let value: String; let color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption.bold()).foregroundStyle(color).minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 10)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
    }
}
