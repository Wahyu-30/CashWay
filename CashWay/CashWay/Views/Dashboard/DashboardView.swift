import SwiftUI
import SwiftData
import Charts

// ============================================================
// MARK: - DashboardView
// Halaman utama CashWay. Menampilkan ringkasan keuangan bulan ini.
// ============================================================

struct DashboardView: View {

    @Environment(\.modelContext) private var modelContext

    @Query private var transactions: [Transaction]
    @Query private var budgets:      [Budget]

    @State private var vm = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: CWSpacing.lg) {
                headerSection
                balanceCard
                incomeBreakdownSection
                chartSection
                if !vm.smartAdvices.isEmpty { adviceSection }
                recentTransactionsSection
            }
            .padding(.horizontal, CWSpacing.md)
            .padding(.bottom, CWSpacing.xxl)
        }
        .background(Color.cwBackground)
        .navigationTitle("Dashboard")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar { toolbarContent }
        .sheet(isPresented: $vm.showAddTransaction) {
            AddTransactionView()
        }
        .sheet(isPresented: $vm.showSmartAdvice) {
            SmartAdviceView(advices: vm.smartAdvices)
        }
        .onAppear { vm.update(transactions: transactions, budgets: budgets) }
        .onChange(of: transactions) { vm.update(transactions: transactions, budgets: budgets) }
        .onChange(of: budgets)      { vm.update(transactions: transactions, budgets: budgets) }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hei, \(vm.userName) 👋")
                    .font(.title2.bold())
                    .foregroundStyle(Color.cwTextPrimary)
                Text(Date.now.formatted(.dateTime.day().month(.wide).year().locale(Locale(identifier: "id_ID"))))
                    .font(.caption)
                    .foregroundStyle(Color.cwTextSecondary)
            }
            Spacer()
            // Month navigator
            HStack(spacing: CWSpacing.sm) {
                Button { vm.prevMonth() } label: {
                    Image(systemName: "chevron.left").font(.title3.bold()).padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
                
                Text(vm.monthTitle)
                    .font(.title3.weight(.bold))
                    .frame(minWidth: 120)
                    
                Button { vm.nextMonth() } label: {
                    Image(systemName: "chevron.right").font(.title3.bold()).padding(.horizontal, 4)
                }
                .buttonStyle(.plain)
                .disabled(!vm.canGoForward)
            }
            .foregroundStyle(Color.cwTextSecondary)
        }
        .padding(.top, CWSpacing.md)
    }

    // MARK: - Balance Card
    private var balanceCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: CWRadius.xl)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "#1A2F3A"), Color.cwSurface],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CWRadius.xl)
                        .stroke(Color.cwBorder, lineWidth: 1)
                )

            VStack(spacing: CWSpacing.sm) {
                Text("Saldo Bulan Ini")
                    .font(.caption)
                    .foregroundStyle(Color.cwTextSecondary)

                Text(CurrencyFormatter.format(vm.netBalance))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(vm.netBalance >= 0 ? Color.cwIncome : Color.cwExpense)
                    .monospacedDigit()

                HStack(spacing: CWSpacing.lg) {
                    statPill(label: "Masuk", amount: vm.totalIncome,   icon: "arrow.down", color: .cwIncome)
                    statPill(label: "Keluar", amount: vm.totalExpense, icon: "arrow.up",   color: .cwExpense)
                }
            }
            .padding(CWSpacing.lg)
        }
    }

    private func statPill(label: String, amount: Decimal, icon: String, color: Color) -> some View {
        HStack(spacing: CWSpacing.xs) {
            Image(systemName: "\(icon).circle.fill")
                .foregroundStyle(color)
                .font(.caption)
            VStack(alignment: .leading, spacing: 0) {
                Text(label).font(.caption).foregroundStyle(Color.cwTextSecondary)
                Text(CurrencyFormatter.formatCompact(amount))
                    .font(.subheadline.bold()).foregroundStyle(color)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, CWSpacing.sm)
        .padding(.vertical, CWSpacing.xs)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: CWRadius.sm))
    }

    // MARK: - Income Breakdown (Gaji vs Freelance)
    private var incomeBreakdownSection: some View {
        VStack(alignment: .leading, spacing: CWSpacing.sm) {
            Text("Sumber Pemasukan")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.cwTextSecondary)

            HStack(spacing: CWSpacing.sm) {
                incomeSourceCard(
                    label:  "Gaji Kantor",
                    amount: vm.salaryIncome,
                    icon:   "building.2.fill",
                    color:  .cwAccent
                )
                incomeSourceCard(
                    label:  "Freelance",
                    amount: vm.freelanceIncome,
                    icon:   "video.fill",
                    color:  .cwFreelance
                )
            }
        }
    }

    private func incomeSourceCard(label: String, amount: Decimal, icon: String, color: Color) -> some View {
        HStack(spacing: CWSpacing.sm) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.15), in: RoundedRectangle(cornerRadius: CWRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption).foregroundStyle(Color.cwTextSecondary)
                Text(amount > 0 ? CurrencyFormatter.formatCompact(amount) : "Belum ada")
                    .font(.subheadline.bold())
                    .foregroundStyle(amount > 0 ? color : Color.cwPlaceholder)
                    .monospacedDigit()
            }
            Spacer()
        }
        .padding(CWSpacing.sm)
        .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
        .overlay(RoundedRectangle(cornerRadius: CWRadius.md).stroke(Color.cwBorder, lineWidth: 1))
        .frame(maxWidth: .infinity)
    }

    // MARK: - Bar Chart
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: CWSpacing.sm) {
            Text("Pengeluaran Harian")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.cwTextSecondary)

            if vm.dailyExpenses.isEmpty || vm.dailyExpenses.allSatisfy({ $0.amount == 0 }) {
                chartEmptyState
            } else {
                Chart(vm.dailyExpenses, id: \.day) { item in
                    BarMark(
                        x: .value("Hari", item.day),
                        y: .value("Pengeluaran", item.amount)
                    )
                    .foregroundStyle(Color.cwExpense.gradient)
                    .cornerRadius(3)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 5)) { value in
                        AxisValueLabel { if let v = value.as(Int.self) { Text("\(v)") } }
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(CurrencyFormatter.formatCompact(Decimal(v)))
                                    .font(.caption)
                            }
                        }
                    }
                }
                .frame(height: 160)
                .padding(CWSpacing.sm)
                .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
            }
        }
    }

    private var chartEmptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: CWSpacing.sm) {
                Image(systemName: "chart.bar").font(.title).foregroundStyle(Color.cwTextSecondary)
                Text("Belum ada pengeluaran bulan ini")
                    .font(.caption).foregroundStyle(Color.cwTextSecondary)
            }
            Spacer()
        }
        .frame(height: 120)
        .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
    }

    // MARK: - Smart Advice Banner
    private var adviceSection: some View {
        Button { vm.showSmartAdvice = true } label: {
            HStack {
                Image(systemName: vm.hasHighPriorityAdvice ? "exclamationmark.triangle.fill" : "lightbulb.fill")
                    .foregroundStyle(vm.hasHighPriorityAdvice ? Color.cwExpense : Color.cwWarning)
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.hasHighPriorityAdvice ? "Ada peringatan keuangan" : "Saran keuangan tersedia")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.cwTextPrimary)
                    Text("\(vm.smartAdvices.count) saran · Ketuk untuk lihat detail")
                        .font(.caption)
                        .foregroundStyle(Color.cwTextSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.cwTextSecondary)
            }
            .padding(CWSpacing.md)
            .background(
                vm.hasHighPriorityAdvice ? Color(hex: "#3D1A1A") : Color(hex: "#3D2D1A"),
                in: RoundedRectangle(cornerRadius: CWRadius.md)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CWRadius.md)
                    .stroke(vm.hasHighPriorityAdvice ? Color.cwExpense.opacity(0.4) : Color.cwWarning.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Transactions
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: CWSpacing.sm) {
            HStack {
                Text("Transaksi Terakhir")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.cwTextSecondary)
                Spacer()
            }

            if vm.recentTransactions.isEmpty {
                ContentUnavailableView(
                    "Belum ada transaksi",
                    systemImage: "tray",
                    description: Text("Ketuk + untuk menambah transaksi pertama")
                )
                .frame(height: 120)
            } else {
                VStack(spacing: 1) {
                    ForEach(vm.recentTransactions) { transaction in
                        TransactionRowView(transaction: transaction)
                        if transaction.id != vm.recentTransactions.last?.id {
                            Divider().background(Color.cwBorder).padding(.leading, 52)
                        }
                    }
                }
                .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
            }
        }
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                vm.showAddTransaction = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.cwAccent)
                    .font(.title3)
            }
        }
    }
}

#Preview {
    NavigationStack {
        DashboardView()
    }
    .modelContainer(for: [Transaction.self, Category.self, Wallet.self, Budget.self], inMemory: true)
    .preferredColorScheme(.dark)
}
