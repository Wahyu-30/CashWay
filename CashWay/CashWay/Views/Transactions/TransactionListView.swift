import SwiftUI

// ============================================================
// MARK: - TransactionListView
// Daftar transaksi dengan filter bulan, tipe, search.
// Default: bulan ini. Bisa diubah pakai navigasi bulan atau
// klik chip "Semua Bulan" untuk lihat seluruh riwayat.
// ============================================================

struct TransactionListView: View {

    @EnvironmentObject private var dataStore: DataStore

    @State private var vm = TransactionViewModel()

    // Filter bulan — default ke bulan & tahun saat ini
    @State private var selectedMonth: Int = Calendar.current.component(.month, from: .now)
    @State private var selectedYear:  Int = Calendar.current.component(.year,  from: .now)
    @State private var showAllMonths: Bool = false   // jika true, tampilkan semua bulan

    // Transaksi yang sudah difilter berdasarkan bulan terpilih
    private var filteredByMonth: [Transaction] {
        guard !showAllMonths else { return dataStore.transactions }
        let cal = Calendar.current
        return dataStore.transactions.filter {
            cal.component(.month, from: $0.date) == selectedMonth &&
            cal.component(.year,  from: $0.date) == selectedYear
        }
    }

    // Navigasi bulan
    private var monthTitle: String {
        let f = DateFormatter()
        f.locale     = Locale(identifier: "id_ID")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: Calendar.current.date(
            from: DateComponents(year: selectedYear, month: selectedMonth)) ?? .now)
    }

    private func prevMonth() {
        if selectedMonth == 1 { selectedMonth = 12; selectedYear -= 1 }
        else { selectedMonth -= 1 }
    }

    private func nextMonth() {
        let now = Calendar.current
        let curMonth = now.component(.month, from: .now)
        let curYear  = now.component(.year,  from: .now)
        guard selectedYear < curYear || (selectedYear == curYear && selectedMonth < curMonth)
        else { return }
        if selectedMonth == 12 { selectedMonth = 1; selectedYear += 1 }
        else { selectedMonth += 1 }
    }

    var body: some View {
        Group {
            if dataStore.transactions.isEmpty {
                emptyState
            } else {
                listContent
            }
        }
        .background(Color.cwBackground)
        .navigationTitle("Transaksi")
        .searchable(text: $vm.searchText, prompt: "Cari transaksi...")
        .toolbar { toolbarContent }
        .sheet(isPresented: $vm.showAddSheet) {
            AddTransactionView()
        }
        .sheet(item: $vm.editingTransaction) { transaction in
            AddTransactionView(editingTransaction: transaction)
        }
        .alert("Hapus Transaksi?", isPresented: Binding(
            get: { vm.deletingTransaction != nil },
            set: { if !$0 { vm.deletingTransaction = nil } }
        )) {
            Button("Hapus", role: .destructive) {
                if let tx = vm.deletingTransaction {
                    vm.delete(tx, dataStore: dataStore)
                    vm.deletingTransaction = nil
                }
            }
            Button("Batal", role: .cancel) {
                vm.deletingTransaction = nil
            }
        } message: {
            if let tx = vm.deletingTransaction {
                Text("\(tx.category?.name ?? "Transaksi ini") sebesar \(CurrencyFormatter.format(tx.amount)) akan dihapus permanen.")
            }
        }
    }

    // MARK: - List Content
    private var listContent: some View {
        List {
            // --- Navigasi bulan ---
            monthNavigationRow
                .listRowBackground(Color.cwBackground)
                .listRowSeparator(.hidden)

            filterChips
                .listRowBackground(Color.cwBackground)
                .listRowSeparator(.hidden)

            let groups = vm.grouped(filteredByMonth)
            if groups.isEmpty {
                SlideInCard(index: 1) {
                    ContentUnavailableView(
                        showAllMonths ? "Tidak ada transaksi" : "Belum ada transaksi bulan ini",
                        systemImage: "tray.fill",
                        description: Text(showAllMonths
                            ? "Coba ubah filter atau cari kata kunci lain"
                            : "Ketuk + untuk mencatat transaksi, atau ketuk \"Semua Bulan\" untuk lihat riwayat")
                    )
                }
                .listRowBackground(Color.cwBackground)
            } else {
                ForEach(Array(groups.enumerated()), id: \.element.date) { gIndex, group in
                    Section {
                        ForEach(Array(group.items.enumerated()), id: \.element.id) { rIndex, transaction in
                            SlideInCard(index: gIndex + rIndex) {
                                TransactionRowView(transaction: transaction)
                            }
                            .listRowBackground(Color.cwSurface)
                            // iOS: swipe kiri untuk hapus, swipe kanan untuk edit
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    vm.deletingTransaction = transaction
                                } label: {
                                    Label("Hapus", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    vm.editingTransaction = transaction
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                .tint(Color.cwAccent)
                            }
                            // Mac: klik kanan untuk hapus / edit
                            .contextMenu {
                                Button {
                                    vm.editingTransaction = transaction
                                } label: {
                                    Label("Edit Transaksi", systemImage: "pencil")
                                }
                                Divider()
                                Button(role: .destructive) {
                                    vm.deletingTransaction = transaction
                                } label: {
                                    Label("Hapus Transaksi", systemImage: "trash")
                                }
                            }
                        }
                    } header: {
                        SlideInCard(index: gIndex) {
                            Text(group.date.formatted(.dateTime
                                .day().month(.wide).year()
                                .locale(Locale(identifier: "id_ID"))))
                                .font(.footnote.bold())
                                .foregroundStyle(Color.cwTextSecondary)
                                .textCase(nil)
                        }
                    }
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .scrollContentBackground(.hidden)
    }

    // MARK: - Month Navigation Row
    private var monthNavigationRow: some View {
        HStack {
            Button(action: prevMonth) {
                Image(systemName: "chevron.left")
                    .foregroundStyle(Color.cwAccent)
                    .font(.callout.bold())
            }
            .buttonStyle(.plain)

            Spacer()

            if showAllMonths {
                Text("Semua Bulan")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.cwTextPrimary)
            } else {
                Text(monthTitle)
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.cwTextPrimary)
            }

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .foregroundStyle(Color.cwAccent)
                    .font(.callout.bold())
            }
            .buttonStyle(.plain)
            .opacity(showAllMonths ? 0 : 1)
        }
        .padding(.vertical, CWSpacing.xs)
        .overlay(alignment: .trailing) {
            // Tombol toggle: Bulan Ini ↔ Semua Bulan
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAllMonths.toggle()
                    if !showAllMonths {
                        // Reset ke bulan saat ini
                        selectedMonth = Calendar.current.component(.month, from: .now)
                        selectedYear  = Calendar.current.component(.year,  from: .now)
                    }
                }
            } label: {
                Text(showAllMonths ? "Bulan Ini" : "Semua Bulan")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.cwSurface, in: Capsule())
                    .foregroundStyle(Color.cwTextSecondary)
            }
            .buttonStyle(.plain)
            .padding(.trailing, CWSpacing.md)
        }
    }

    // MARK: - Filter Chips
    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: CWSpacing.xs) {
                filterChip(label: "Semua", isActive: vm.filterType == nil) {
                    vm.filterType = nil
                }
                filterChip(
                    label: "Pengeluaran",
                    isActive: vm.filterType == .expense,
                    color: .cwExpense
                ) { vm.filterType = vm.filterType == .expense ? nil : .expense }

                filterChip(
                    label: "Pemasukan",
                    isActive: vm.filterType == .income,
                    color: .cwIncome
                ) { vm.filterType = vm.filterType == .income ? nil : .income }
            }
            .padding(.vertical, CWSpacing.xs)
        }
    }

    private func filterChip(label: String, isActive: Bool, color: Color = .cwAccent, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, CWSpacing.sm)
                .padding(.vertical, CWSpacing.xs)
                .background(isActive ? color : Color.cwSurface, in: Capsule())
                .foregroundStyle(isActive ? .white : Color.cwTextSecondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State
    private var emptyState: some View {
        ContentUnavailableView(
            "Belum ada transaksi",
            systemImage: "tray.fill",
            description: Text("Ketuk + untuk mencatat transaksi pertama kamu")
        )
    }

    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button { vm.showAddSheet = true } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(Color.cwAccent)
                    .font(.title3)
            }
        }
    }
}

// ============================================================
// MARK: - TransactionRowView
// Satu baris transaksi di dalam list.
// ============================================================

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: CWSpacing.sm) {
            // Icon kategori
            ZStack {
                RoundedRectangle(cornerRadius: CWRadius.sm)
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: transaction.category?.icon ?? "questionmark")
                    .foregroundStyle(categoryColor)
                    .font(.body)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category?.name ?? "Tidak ada kategori")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.cwTextPrimary)

                HStack(spacing: CWSpacing.xs) {
                    // Income tag badge
                    if transaction.type == .income, let tag = transaction.incomeTag {
                        Text(tag.displayName)
                            .font(.system(size: 9).bold())
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(hex: tag.colorHex).opacity(0.2), in: Capsule())
                            .foregroundStyle(Color(hex: tag.colorHex))
                    }
                    if !transaction.note.isEmpty {
                        Text(transaction.note)
                            .font(.caption)
                            .foregroundStyle(Color.cwTextSecondary)
                            .lineLimit(1)
                    }
                    Text(transaction.date.formatted(.dateTime.hour().minute()))
                        .font(.caption)
                        .foregroundStyle(Color.cwPlaceholder)
                }
            }

            Spacer()

            // Amount
            Text(CurrencyFormatter.formatSigned(transaction.amount, type: transaction.type))
                .font(.subheadline.bold())
                .foregroundStyle(amountColor)
                .monospacedDigit()
        }
        .padding(.vertical, CWSpacing.xs)
    }

    private var categoryColor: Color {
        Color(hex: transaction.category?.colorHex ?? "#8B8FA8")
    }

    private var amountColor: Color {
        switch transaction.type {
        case .income:   return .cwIncome
        case .expense:  return .cwExpense
        case .transfer: return .cwTextSecondary
        }
    }
}

#Preview {
    NavigationStack { TransactionListView() }
        .environmentObject(DataStore())
        .preferredColorScheme(.dark)
}
