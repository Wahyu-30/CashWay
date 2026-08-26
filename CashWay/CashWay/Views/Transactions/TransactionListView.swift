import SwiftUI

// ============================================================
// MARK: - TransactionListView
// Daftar semua transaksi dengan filter, search, dan swipe actions.
// ============================================================

struct TransactionListView: View {

    @EnvironmentObject private var dataStore: DataStore

    @State private var vm = TransactionViewModel()

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
    }

    // MARK: - List Content
    private var listContent: some View {
        List {
            filterChips
                .listRowBackground(Color.cwBackground)
                .listRowSeparator(.hidden)

            let groups = vm.grouped(dataStore.transactions)
            if groups.isEmpty {
                SlideInCard(index: 1) {
                    ContentUnavailableView.search
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
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    vm.delete(transaction, dataStore: dataStore)
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
