import SwiftUI
import Charts

// ============================================================
// MARK: - DashboardView
// Halaman utama CashWay. Menampilkan ringkasan keuangan bulan ini.
// ============================================================

struct DashboardView: View {

    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var authManager: AuthManager

    @State private var vm = DashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: CWSpacing.lg) {
                SlideInCard(index: 0) { headerSection }
                
                // Tampilkan peringatan sertifikat HANYA di hari ke-6 & ke-7 (≤1 hari tersisa)
                if let days = vm.daysUntilExpiration, days <= 1 {
                    SlideInCard(index: 1) { expirationBanner(days: days) }
                }
                
                SlideInCard(index: 2) { balanceCard }
                SlideInCard(index: 2) { walletBreakdownSection }
                SlideInCard(index: 2) { overspendingBanner }
                SlideInCard(index: 3) { incomeBreakdownSection }
                SlideInCard(index: 4) { chartSection }
                if !vm.smartAdvices.isEmpty {
                    SlideInCard(index: 5) { adviceSection }
                }
                SlideInCard(index: 6) { recentTransactionsSection }
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
        .onChange(of: dataStore.transactions) { _, _ in updateData() }
        .onChange(of: dataStore.budgets) { _, _ in updateData() }
        .onChange(of: vm.selectedMonth) { _, _ in updateData() }
        .onAppear { updateData() }
    }

    private func updateData() {
        vm.update(transactions: dataStore.transactions, budgets: dataStore.budgets, wallets: dataStore.wallets)
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hei, \(authManager.userNickname) 👋")
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
                // Label menjelaskan ini saldo akumulatif lintas bulan
                Text("Total Saldo")
                    .font(.caption)
                    .foregroundStyle(Color.cwTextSecondary)

                // Angka utama: kumulatif dari semua bulan s.d. bulan ini
                AnimatedNumberText(
                    value: vm.cumulativeBalance,
                    color: vm.cumulativeBalance >= 0 ? Color.cwIncome : Color.cwExpense,
                    font: .system(size: 36, weight: .bold, design: .rounded)
                )

                // Badge Masuk / Keluar tetap menampilkan aktivitas bulan ini saja
                HStack(spacing: CWSpacing.lg) {
                    statPill(label: "Masuk", amount: vm.totalIncome,   icon: "arrow.down", color: .cwIncome)
                    statPill(label: "Keluar", amount: vm.totalExpense, icon: "arrow.up",   color: .cwExpense)
                }
            }
            .padding(CWSpacing.lg)
        }
    }
    
    // MARK: - Wallet Breakdown
    private var walletBreakdownSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CWSpacing.sm) {
                ForEach(vm.walletBalances, id: \.wallet.id) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: item.wallet.icon)
                                .foregroundStyle(Color(hex: item.wallet.colorHex))
                            Text(item.wallet.name)
                                .font(.caption.bold())
                                .foregroundStyle(Color.cwTextPrimary)
                        }
                        Text(CurrencyFormatter.formatCompact(item.balance))
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.cwTextSecondary)
                            .monospacedDigit()
                    }
                    .padding(CWSpacing.md)
                    .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: CWRadius.md).stroke(Color.cwBorder, lineWidth: 1))
                }
            }
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

            ScrollView(.horizontal, showsIndicators: false) {
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
                    incomeSourceCard(
                        label:  "Orang Tua",
                        amount: vm.parentsIncome,
                        icon:   "figure.2.arms.open",
                        color:  Color(hex: "#ff33aa") // Tag Hot Pink
                    )
                    if vm.previousMonthBalance > 0 {
                        incomeSourceCard(
                            label:  "Sisa Saldo Bulan Lalu",
                            amount: vm.previousMonthBalance,
                            icon:   "arrow.uturn.left.circle.fill",
                            color:  Color(hex: "#1a6cff") // Blue
                        )
                    }
                }
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
        .frame(minWidth: 150, maxWidth: .infinity)
    }

    // MARK: - Bar Chart
    // MARK: - Overspending Warning Banner
    private var overspendingBanner: some View {
        Group {
            if vm.isOverspending {
                HStack(spacing: CWSpacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.white)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("⚠️ Pengeluaran Melebihi Pemasukan!")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Text("Pengeluaran kamu \(CurrencyFormatter.format(vm.totalExpense)) sudah melampaui pemasukan \(CurrencyFormatter.format(vm.totalIncome)) bulan ini.")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                }
                .padding(CWSpacing.md)
                .background(
                    LinearGradient(colors: [Color(hex: "#c0392b"), Color(hex: "#922b21")],
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: CWRadius.md)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CWRadius.md)
                        .stroke(Color.cwExpense.opacity(0.6), lineWidth: 1)
                )
            } else if vm.spendingRatio > 0.8 && vm.totalIncome > 0 {
                HStack(spacing: CWSpacing.sm) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.white)
                        .font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🔶 Hati-hati, hampir melebihi batas!")
                            .font(.subheadline.bold())
                            .foregroundStyle(.white)
                        Text("Pengeluaran sudah \(Int(vm.spendingRatio * 100))% dari pemasukan bulan ini. Sisanya \(CurrencyFormatter.format(vm.totalIncome - vm.totalExpense)).")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    Spacer()
                }
                .padding(CWSpacing.md)
                .background(
                    LinearGradient(colors: [Color(hex: "#d35400"), Color(hex: "#a04000")],
                                   startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: CWRadius.md)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CWRadius.md)
                        .stroke(Color.cwWarning.opacity(0.6), lineWidth: 1)
                )
            }
        }
    }
    
    // MARK: - Expiration Banner
    @ViewBuilder
    private func expirationBanner(days: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.title2)
                .foregroundStyle(Color(hex: "#FFA500"))
            VStack(alignment: .leading, spacing: 2) {
                Text(days > 0 ? "Expired dalam \(days) hari" : "Sertifikat Kedaluwarsa!")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.cwTextPrimary)
                Text(days > 0 ? "Hubungkan ke Xcode di Mac untuk me-refresh lisensi Apple Developer Gratis." : "Aplikasi mungkin tidak bisa dibuka lagi. Segera hubungkan ke Xcode!")
                    .font(.caption)
                    .foregroundStyle(Color.cwTextSecondary)
            }
            Spacer()
        }
        .padding(CWSpacing.md)
        .background(Color(hex: "#FFA500").opacity(0.1))
        .cornerRadius(CWRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CWRadius.lg)
                .stroke(Color(hex: "#FFA500").opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Income vs Expense Chart
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: CWSpacing.sm) {
            HStack {
                Text("Pemasukan vs Pengeluaran")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.cwTextSecondary)
                Spacer()
                // Legend
                HStack(spacing: CWSpacing.sm) {
                    legendDot(color: .cwIncome, label: "Masuk")
                    legendDot(color: .cwExpense, label: "Keluar")
                }
            }

            // Spending ratio progress bar
            if vm.totalIncome > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cwSurface)
                                .frame(height: 8)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(vm.isOverspending ? Color.cwExpense : (vm.spendingRatio > 0.8 ? Color.cwWarning : Color.cwIncome))
                                .frame(width: geo.size.width * min(CGFloat(vm.spendingRatio), 1.0), height: 8)
                                .animation(.spring(response: 0.6), value: vm.spendingRatio)
                        }
                    }
                    .frame(height: 8)
                    Text("\(Int(vm.spendingRatio * 100))% dari pemasukan sudah terpakai")
                        .font(.caption)
                        .foregroundStyle(vm.isOverspending ? Color.cwExpense : Color.cwTextSecondary)
                }
                .padding(.bottom, CWSpacing.xs)
            }

            let hasData = !vm.dailyExpenses.allSatisfy({ $0.amount == 0 }) || !vm.dailyIncome.allSatisfy({ $0.amount == 0 })

            if !hasData {
                chartEmptyState
            } else {
                Chart {
                    ForEach(vm.dailyIncome, id: \.day) { item in
                        if item.amount > 0 {
                            BarMark(
                                x: .value("Hari", item.day),
                                y: .value("Jumlah", item.amount),
                                width: .fixed(6)
                            )
                            .foregroundStyle(Color.cwIncome.gradient)
                            .position(by: .value("Tipe", "Masuk"))
                            .cornerRadius(3)
                        }
                    }
                    ForEach(vm.dailyExpenses, id: \.day) { item in
                        if item.amount > 0 {
                            BarMark(
                                x: .value("Hari", item.day),
                                y: .value("Jumlah", item.amount),
                                width: .fixed(6)
                            )
                            .foregroundStyle(Color.cwExpense.gradient)
                            .position(by: .value("Tipe", "Keluar"))
                            .cornerRadius(3)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 5)) { value in
                        AxisValueLabel { if let v = value.as(Int.self) { Text("\(v)").font(.caption2) } }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(CurrencyFormatter.formatCompact(Decimal(v)))
                                    .font(.caption2)
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3, dash: [3]))
                    }
                }
                .frame(height: 180)
                .padding(CWSpacing.sm)
                .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
            }
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption).foregroundStyle(Color.cwTextSecondary)
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
                VStack(spacing: 0) {
                    ForEach(vm.recentTransactions) { transaction in
                        TransactionRowView(transaction: transaction)
                            .padding(.horizontal, CWSpacing.md)
                            .padding(.vertical, 4)
                        
                        if transaction.id != vm.recentTransactions.last?.id {
                            Divider()
                                .background(Color.cwBorder)
                                .padding(.leading, 16 + 40 + CWSpacing.sm) // 16(padding) + 40(icon) + 8(spacing) = 64
                        }
                    }
                }
                .padding(.vertical, 8)
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
    .environmentObject(DataStore())
    .preferredColorScheme(.dark)
}
