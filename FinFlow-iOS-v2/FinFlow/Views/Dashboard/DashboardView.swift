import SwiftUI

// MARK: - MainTabView
struct MainTabView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var notifVM = NotificationsViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem { Label("Dashboard", systemImage: "house.fill") }.tag(0)
            TransactionsView()
                .tabItem { Label("Transactions", systemImage: "arrow.left.arrow.right") }.tag(1)
            BudgetsView()
                .tabItem { Label("Budgets", systemImage: "bag.fill") }.tag(2)
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }.tag(3)
        }
        .accentColor(Color("AccentGreen"))
        .environmentObject(notifVM)
        .onAppear { notifVM.load() }
        .onReceive(NotificationCenter.default.publisher(for: .switchToTransactions)) { _ in
            selectedTab = 1
        }
    }
}

// MARK: - Pie Slice Shape
struct PieSliceShape: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var animatableData: AnimatablePair<Double, Double> {
        get { .init(startAngle.degrees, endAngle.degrees) }
        set { startAngle = .degrees(newValue.first); endAngle = .degrees(newValue.second) }
    }
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        p.move(to: c)
        p.addArc(center: c, radius: r, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - 3D Interactive DonutChart
struct DonutChart3D: View {
    struct Segment: Identifiable {
        let id = UUID()
        let label: String
        let value: Double
        let color: Color
        var angle: Double = 0
        var sweep: Double = 0
    }

    let totalIncome: Double
    let totalExpenses: Double
    @State private var selectedIndex: Int? = nil
    @State private var animProgress: Double = 0

    var segments: [Segment] {
        let sav  = max(0, totalIncome - totalExpenses)
        let raw  = [(label: "Savings", val: sav, color: Color("AccentGreen")),
                    (label: "Expenses", val: totalExpenses, color: Color.red)]
        let total = raw.reduce(0) { $0 + $1.val }
        guard total > 0 else { return [] }
        var start = -90.0
        return raw.compactMap { item -> Segment? in
            guard item.val > 0 else { return nil }
            let sweep = (item.val / total) * 360
            var s = Segment(label: item.label, value: item.val, color: item.color)
            s.angle = start; s.sweep = sweep
            start += sweep
            return s
        }
    }

    var savingsPercent: Int {
        guard totalIncome > 0 else { return 0 }
        return Int(max(0, (totalIncome - totalExpenses) / totalIncome * 100))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ForEach(Array(segments.enumerated()), id: \.offset) { idx, seg in
                    let isSelected = selectedIndex == idx
                    ZStack {
                        ForEach(0..<6, id: \.self) { d in
                            PieSliceShape(
                                startAngle: .degrees(seg.angle),
                                endAngle:   .degrees(seg.angle + seg.sweep * animProgress)
                            )
                            .fill(seg.color.opacity(0.15 - Double(d) * 0.02))
                            .frame(width: 160, height: 160)
                            .offset(y: CGFloat(d) * 1.2)
                            .scaleEffect(isSelected ? 1.07 : 1)
                        }
                        PieSliceShape(
                            startAngle: .degrees(seg.angle),
                            endAngle:   .degrees(seg.angle + seg.sweep * animProgress)
                        )
                        .fill(seg.color)
                        .frame(width: 160, height: 160)
                        .scaleEffect(isSelected ? 1.07 : 1)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    }
                }
                Circle().fill(Color(.systemBackground)).frame(width: 88, height: 88)
                VStack(spacing: 1) {
                    if let idx = selectedIndex, idx < segments.count {
                        Text(segments[idx].label)
                            .font(.system(size: 8, weight: .semibold)).foregroundStyle(.secondary)
                        Text("\(Int(segments[idx].value / max(totalIncome, 1) * 100))%")
                            .font(.system(size: 18, weight: .heavy))
                            .foregroundStyle(segments[idx].color)
                    } else {
                        Text("\(savingsPercent)%")
                            .font(.system(size: 20, weight: .heavy))
                            .foregroundStyle(Color("AccentGreen"))
                        Text("Saved").font(.system(size: 9, weight: .semibold)).foregroundStyle(.secondary)
                    }
                }
                ZStack {
                    ForEach(Array(segments.enumerated()), id: \.offset) { idx, seg in
                        PieSliceShape(startAngle: .degrees(seg.angle), endAngle: .degrees(seg.angle + seg.sweep))
                            .fill(Color.clear).frame(width: 160, height: 160)
                            .contentShape(PieSliceShape(startAngle: .degrees(seg.angle), endAngle: .degrees(seg.angle + seg.sweep)))
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedIndex = selectedIndex == idx ? nil : idx
                                }
                            }
                    }
                    Circle().fill(Color.clear).frame(width: 88, height: 88).onTapGesture { selectedIndex = nil }
                }
            }
            .frame(width: 160, height: 175)
        }
        .onAppear { withAnimation(.easeOut(duration: 1.2)) { animProgress = 1 } }
    }
}

// MARK: - DashboardView
struct DashboardView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var notifVM: NotificationsViewModel
    @StateObject private var vm = DashboardViewModel()
    @StateObject private var txVM = TransactionsViewModel()
    @State private var showNotifications = false

    var symbol: String { authVM.user?.displaySymbol ?? "₹" }
    var userName: String { authVM.user?.name.components(separatedBy: " ").first ?? "there" }

    var greetingPrefix: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good Morning" }
        else if h < 17 { return "Good Afternoon" }
        else { return "Good Evening" }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {

                    // MARK: Greeting Header
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(greetingPrefix + ",")
                                .font(.subheadline).foregroundStyle(.secondary)
                            HStack(spacing: 6) {
                                Text(authVM.user?.name ?? "User")
                                    .font(.title2.bold())
                                Text("👋").font(.title2)
                            }
                        }
                        Spacer()
                        Button { showNotifications = true } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "bell.fill")
                                    .font(.title3).foregroundStyle(.primary)
                                if notifVM.unreadCount > 0 {
                                    ZStack {
                                        Circle().fill(Color.red).frame(width: 16, height: 16)
                                        Text("\(min(notifVM.unreadCount, 9))")
                                            .font(.system(size: 9, weight: .heavy)).foregroundStyle(.white)
                                    }.offset(x: 6, y: -6)
                                }
                            }
                        }
                    }
                    .padding(.horizontal).padding(.top, 8).padding(.bottom, 14)

                    // MARK: Period Picker
                    HStack(spacing: 0) {
                        ForEach(["Weekly", "Monthly", "Yearly"], id: \.self) { period in
                            let isActive = vm.selectedPeriod == period.lowercased()
                            Button {
                                vm.selectedPeriod = period.lowercased()
                                vm.load()
                            } label: {
                                Text(period)
                                    .font(.subheadline.weight(isActive ? .semibold : .regular))
                                    .foregroundStyle(isActive ? .white : .secondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(isActive ? Color.primary : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 10))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(4)
                    .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 13))
                    .padding(.horizontal).padding(.bottom, 16)

                    if vm.isLoading {
                        ProgressView().padding(60)
                    } else if let s = vm.summary {

                        // MARK: Financial Overview Card (Chart + Legend)
                        HStack(alignment: .top, spacing: 14) {
                            DonutChart3D(
                                totalIncome: s.totalIncome ?? 1,
                                totalExpenses: s.totalExpenses ?? 0
                            )
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Financial Overview")
                                    .font(.subheadline.bold())
                                let inc = s.totalIncome ?? 1
                                let sav = max(0, (s.totalIncome ?? 0) - (s.totalExpenses ?? 0))
                                let savPct = inc > 0 ? Int(sav / inc * 100) : 0
                                let expPct = inc > 0 ? Int((s.totalExpenses ?? 0) / inc * 100) : 0

                                HStack(spacing: 6) {
                                    Circle().fill(Color("AccentGreen")).frame(width: 9, height: 9)
                                    Text("Savings").font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(savPct)%").font(.caption.bold())
                                }
                                HStack(spacing: 6) {
                                    Circle().fill(Color.red).frame(width: 9, height: 9)
                                    Text("Expenses").font(.caption).foregroundStyle(.secondary)
                                    Spacer()
                                    Text("\(expPct)%").font(.caption.bold())
                                }
                                Divider()
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Total Income").font(.caption2).foregroundStyle(.secondary)
                                    Text("\(symbol)\(formatAmount(s.totalIncome ?? 0))")
                                        .font(.subheadline.bold()).foregroundStyle(Color("AccentGreen"))
                                }
                                Text("Tap a slice for details")
                                    .font(.system(size: 9)).foregroundStyle(.tertiary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(16)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal).padding(.bottom, 14)

                        // MARK: 4 Stat Cards
                        LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                            DashStatCard(title: "INCOME",
                                         value: "\(symbol)\(formatAmount(s.totalIncome ?? 0))",
                                         subtitle: "This month", color: Color("AccentGreen"))
                            DashStatCard(title: "EXPENSES",
                                         value: "\(symbol)\(formatAmount(s.totalExpenses ?? 0))",
                                         subtitle: "This month", color: .red)
                            DashStatCard(title: "BALANCE",
                                         value: "\(symbol)\(formatAmount(s.balance ?? 0))",
                                         subtitle: "This month", color: .blue)
                            DashStatCard(title: "SAVINGS",
                                         value: "\(Int(s.savingsRate ?? 0))%",
                                         subtitle: "This month", color: .purple)
                        }
                        .padding(.horizontal).padding(.bottom, 14)

                        // MARK: Spending by Category
                        if let cats = s.expenseByCategory, !cats.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Spending by Category")
                                    .font(.headline).padding(.horizontal)
                                let total = cats.reduce(0) { $0 + $1.total }
                                VStack(spacing: 0) {
                                    ForEach(cats.prefix(6)) { cat in
                                        let pct = total > 0 ? cat.total / total : 0
                                        VStack(spacing: 6) {
                                            HStack(spacing: 10) {
                                                ZStack {
                                                    Circle()
                                                        .fill(categoryColor(cat.category).opacity(0.15))
                                                        .frame(width: 36, height: 36)
                                                    Text(categoryEmoji(cat.category))
                                                        .font(.system(size: 16))
                                                }
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(cat.category).font(.subheadline.weight(.medium))
                                                    GeometryReader { geo in
                                                        ZStack(alignment: .leading) {
                                                            RoundedRectangle(cornerRadius: 4)
                                                                .fill(Color(.systemGray5))
                                                                .frame(height: 6)
                                                            RoundedRectangle(cornerRadius: 4)
                                                                .fill(categoryColor(cat.category))
                                                                .frame(width: geo.size.width * pct, height: 6)
                                                        }
                                                    }
                                                    .frame(height: 6)
                                                }
                                                Spacer()
                                                VStack(alignment: .trailing, spacing: 2) {
                                                    Text("\(symbol)\(formatAmount(cat.total))")
                                                        .font(.subheadline.bold())
                                                    Text("\(Int(pct * 100))%")
                                                        .font(.caption).foregroundStyle(.secondary)
                                                }
                                            }
                                            .padding(.horizontal, 14).padding(.vertical, 10)
                                            if cat.category != cats.prefix(6).last?.category {
                                                Divider().padding(.leading, 60)
                                            }
                                        }
                                    }
                                }
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                            }
                            .padding(.bottom, 14)
                        }

                        // MARK: Recent Transactions
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent Transactions").font(.headline)
                                Spacer()
                                Button("See all") {
                                    // Posted via NotificationCenter so MainTabView can switch tab
                                    NotificationCenter.default.post(name: .switchToTransactions, object: nil)
                                }
                                .font(.subheadline).foregroundStyle(Color("AccentGreen"))
                            }
                            .padding(.horizontal)

                            if txVM.isLoading {
                                ProgressView().frame(maxWidth: .infinity).padding()
                            } else if txVM.transactions.isEmpty {
                                Text("No transactions yet.")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity).padding()
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(txVM.transactions.prefix(5)) { tx in
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill(tx.isIncome ? Color.green.opacity(0.15) : Color.red.opacity(0.12))
                                                    .frame(width: 40, height: 40)
                                                Text(tx.categoryEmoji).font(.system(size: 16))
                                            }
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(tx.description)
                                                    .font(.subheadline.weight(.medium)).lineLimit(1)
                                                HStack(spacing: 6) {
                                                    Text(tx.category)
                                                        .font(.caption)
                                                        .padding(.horizontal, 7).padding(.vertical, 2)
                                                        .background(categoryColor(tx.category).opacity(0.15),
                                                                    in: Capsule())
                                                        .foregroundStyle(categoryColor(tx.category))
                                                    Text(tx.formattedDate)
                                                        .font(.caption).foregroundStyle(.secondary)
                                                }
                                            }
                                            Spacer()
                                            Text("\(tx.isIncome ? "+" : "-")\(symbol)\(formatAmount(tx.amount))")
                                                .font(.subheadline.bold())
                                                .foregroundStyle(tx.isIncome ? .green : .red)
                                        }
                                        .padding(.horizontal, 14).padding(.vertical, 10)
                                        if tx.id != txVM.transactions.prefix(5).last?.id {
                                            Divider().padding(.leading, 66)
                                        }
                                    }
                                }
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 20)

                    } else {
                        ContentUnavailableView("No Data", systemImage: "chart.pie",
                            description: Text("Add transactions to see your dashboard."))
                        .padding(40)
                    }
                }
                .padding(.bottom, 8)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showNotifications) {
                NotificationsView().environmentObject(notifVM)
            }
            .onAppear {
                vm.load()
                txVM.load()
            }
            .onChange(of: vm.selectedPeriod) { _ in vm.load() }
            .refreshable { vm.load(); txVM.load() }
        }
    }
}

// MARK: - DashStatCard
struct DashStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            HStack(spacing: 4) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - CategoryBreakdownCard (kept for compatibility)
struct CategoryBreakdownCard: View {
    let categories: [CategoryStat]
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category").font(.headline)
            let total = categories.reduce(0) { $0 + $1.total }
            ForEach(categories.prefix(6)) { cat in
                let pct = total > 0 ? cat.total / total : 0
                VStack(spacing: 4) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle().fill(categoryColor(cat.category)).frame(width: 8, height: 8)
                            Text(cat.category).font(.subheadline)
                        }
                        Spacer()
                        Text("\(symbol)\(formatAmount(cat.total))").font(.subheadline.bold())
                        Text("(\(Int(pct*100))%)").font(.caption).foregroundStyle(.secondary)
                    }
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray5))
                            RoundedRectangle(cornerRadius: 4).fill(categoryColor(cat.category))
                                .frame(width: geo.size.width * pct)
                        }
                    }
                    .frame(height: 7)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - TrendCard
struct TrendCard: View {
    let trend: [TrendPoint]
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("6-Month Trend").font(.headline)
            let incomePoints  = trend.filter { $0.type == "income" }
            let expensePoints = trend.filter { $0.type == "expense" }
            let maxVal = trend.map { $0.total }.max() ?? 1
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(incomePoints.indices, id: \.self) { i in
                    VStack(spacing: 2) {
                        Spacer()
                        let incH  = CGFloat((incomePoints[safe: i]?.total  ?? 0) / maxVal * 90)
                        let expH  = CGFloat((expensePoints[safe: i]?.total ?? 0) / maxVal * 90)
                        HStack(spacing: 1) {
                            RoundedRectangle(cornerRadius: 3).fill(Color.green).frame(width: 10, height: max(4, incH))
                            RoundedRectangle(cornerRadius: 3).fill(Color.red).frame(width: 10,  height: max(4, expH))
                        }
                        Text(incomePoints[safe: i]?.monthLabel ?? "").font(.system(size: 9)).foregroundStyle(.secondary)
                    }
                }
            }
            .frame(height: 110)
            HStack(spacing: 16) {
                Label("Income",  systemImage: "circle.fill").foregroundStyle(.green).font(.caption)
                Label("Expense", systemImage: "circle.fill").foregroundStyle(.red).font(.caption)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - BudgetOverviewCard
struct BudgetOverviewCard: View {
    let budgets: [Budget]
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Budget Overview").font(.headline)
            ForEach(budgets.prefix(4)) { b in
                HStack {
                    Text(b.displayEmoji + " " + b.name).font(.subheadline)
                    Spacer()
                    Text("\(symbol)\(formatAmount(b.spent)) / \(symbol)\(formatAmount(b.totalAmount))")
                        .font(.caption).foregroundStyle(.secondary)
                }
                ProgressView(value: b.percentUsed, total: 100)
                    .tint(b.isExceeded ? .red : b.isWarning ? .orange : Color("AccentGreen"))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
    }
}

// MARK: - Category Emoji Helper
func categoryEmoji(_ category: String) -> String {
    switch category {
    case "Food":          return "🍔"
    case "Housing":       return "🏠"
    case "Transport":     return "🚗"
    case "Shopping":      return "🛍"
    case "Entertainment": return "🎬"
    case "Utilities":     return "💡"
    case "Healthcare":    return "🏥"
    case "Salary":        return "💼"
    case "Freelance":     return "💻"
    case "Investment":    return "📈"
    default:              return "💰"
    }
}

// MARK: - Notification Name for Tab Switch
extension Notification.Name {
    static let switchToTransactions = Notification.Name("switchToTransactions")
}