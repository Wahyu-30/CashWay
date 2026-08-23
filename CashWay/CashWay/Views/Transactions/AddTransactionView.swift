import SwiftUI
import SwiftData

// ============================================================
// MARK: - AddTransactionView
// Bottom sheet untuk menambah atau mengedit transaksi.
// Menampilkan: toggle tipe (income/expense), input amount,
// picker kategori, picker wallet, date picker, note, income tag (jika income).
// ============================================================

struct AddTransactionView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss)      private var dismiss

    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query(sort: \Wallet.sortOrder)   private var wallets:    [Wallet]

    @State private var vm = TransactionViewModel()

    var editingTransaction: Transaction? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CWSpacing.lg) {
                    typeToggle
                    amountInput
                    if vm.selectedType == .income { incomeTagPicker }
                    categoryPicker
                    walletPicker
                    datePicker
                    noteField
                }
                .padding(CWSpacing.md)
            }
            .background(Color.cwBackground)
            .navigationTitle(editingTransaction == nil ? "Tambah Transaksi" : "Edit Transaksi")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }
                        .foregroundStyle(Color.cwTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") { saveAndDismiss() }
                        .bold()
                        .foregroundStyle(vm.isValidForm ? Color.cwAccent : Color.cwPlaceholder)
                        .disabled(!vm.isValidForm)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
        .onAppear { setup() }
    }

    // MARK: - Type Toggle (Pengeluaran / Pemasukan)
    private var typeToggle: some View {
        Picker("Tipe", selection: $vm.selectedType) {
            Text("Pengeluaran").tag(Transaction.TransactionType.expense)
            Text("Pemasukan").tag(Transaction.TransactionType.income)
        }
        .pickerStyle(.segmented)
        .onChange(of: vm.selectedType) { vm.selectedCategory = nil }
    }

    // MARK: - Amount Input
    private var amountInput: some View {
        VStack(spacing: CWSpacing.xs) {
            Text("Jumlah")
                .font(.caption).foregroundStyle(Color.cwTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                Text("Rp").font(.title2).foregroundStyle(Color.cwTextSecondary)
                TextField("0", text: $vm.amountText)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.cwTextPrimary)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .monospacedDigit()
                    .onChange(of: vm.amountText) { vm.formatAmountInput(vm.amountText) }
            }
            .padding(CWSpacing.md)
            .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: CWRadius.md)
                    .stroke(Color.cwAccent.opacity(0.5), lineWidth: 1)
            )
        }
    }

    // MARK: - Income Tag Picker (Gaji / Freelance / Lainnya)
    private var incomeTagPicker: some View {
        VStack(alignment: .leading, spacing: CWSpacing.sm) {
            Text("Sumber Pemasukan")
                .font(.caption).foregroundStyle(Color.cwTextSecondary)

            HStack(spacing: CWSpacing.sm) {
                ForEach(Transaction.IncomeTag.allCases, id: \.self) { tag in
                    Button {
                        vm.selectedIncomeTag = tag
                    } label: {
                        HStack(spacing: CWSpacing.xs) {
                            Image(systemName: tag.icon)
                            Text(tag.displayName)
                                .font(.caption)
                        }
                        .padding(.horizontal, CWSpacing.sm)
                        .padding(.vertical, CWSpacing.xs)
                        .background(
                            vm.selectedIncomeTag == tag
                                ? Color(hex: tag.colorHex)
                                : Color.cwSurface,
                            in: RoundedRectangle(cornerRadius: CWRadius.sm)
                        )
                        .foregroundStyle(
                            vm.selectedIncomeTag == tag
                                ? Color.white
                                : Color.cwTextSecondary
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Category Picker
    private var categoryPicker: some View {
        let filtered = categories.filter { $0.type == (vm.selectedType == .income ? .income : .expense) }

        return VStack(alignment: .leading, spacing: CWSpacing.sm) {
            Text("Kategori")
                .font(.caption).foregroundStyle(Color.cwTextSecondary)

            if filtered.isEmpty {
                Text("Tidak ada kategori").font(.caption).foregroundStyle(Color.cwPlaceholder)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: CWSpacing.sm) {
                    ForEach(filtered) { cat in
                        categoryChip(cat)
                    }
                }
            }
        }
    }

    private func categoryChip(_ category: Category) -> some View {
        let isSelected = vm.selectedCategory?.id == category.id
        return Button {
            vm.selectedCategory = isSelected ? nil : category
        } label: {
            VStack(spacing: 4) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : Color(hex: category.colorHex))
                    .frame(width: 44, height: 44)
                    .background(
                        isSelected ? Color(hex: category.colorHex) : Color(hex: category.colorHex).opacity(0.15),
                        in: RoundedRectangle(cornerRadius: CWRadius.sm)
                    )
                Text(category.name)
                    .font(.system(size: 10))
                    .foregroundStyle(isSelected ? Color.cwTextPrimary : Color.cwTextSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Wallet Picker
    private var walletPicker: some View {
        VStack(alignment: .leading, spacing: CWSpacing.sm) {
            Text("Dari / Ke Dompet")
                .font(.caption).foregroundStyle(Color.cwTextSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CWSpacing.sm) {
                    ForEach(wallets) { wallet in
                        walletChip(wallet)
                    }
                }
            }
        }
    }

    private func walletChip(_ wallet: Wallet) -> some View {
        let isSelected = vm.selectedWallet?.id == wallet.id
        return Button {
            vm.selectedWallet = wallet
        } label: {
            HStack(spacing: CWSpacing.xs) {
                Image(systemName: wallet.icon)
                    .foregroundStyle(Color(hex: wallet.colorHex))
                Text(wallet.name)
                    .font(.footnote)
                    .foregroundStyle(isSelected ? .white : Color.cwTextPrimary)
            }
            .padding(.horizontal, CWSpacing.sm)
            .padding(.vertical, CWSpacing.xs)
            .background(
                isSelected ? Color(hex: wallet.colorHex) : Color.cwSurface,
                in: RoundedRectangle(cornerRadius: CWRadius.sm)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CWRadius.sm)
                    .stroke(Color(hex: wallet.colorHex).opacity(isSelected ? 0 : 0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Picker
    private var datePicker: some View {
        HStack {
            Image(systemName: "calendar").foregroundStyle(Color.cwAccent)
            DatePicker("Tanggal", selection: $vm.selectedDate, displayedComponents: .date)
                .foregroundStyle(Color.cwTextPrimary)
                .environment(\.locale, Locale(identifier: "id_ID"))
        }
        .padding(CWSpacing.md)
        .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
    }

    // MARK: - Note Field
    private var noteField: some View {
        HStack(alignment: .top, spacing: CWSpacing.sm) {
            Image(systemName: "note.text").foregroundStyle(Color.cwTextSecondary)
            TextField("Catatan (opsional)", text: $vm.note, axis: .vertical)
                .foregroundStyle(Color.cwTextPrimary)
                .lineLimit(3)
        }
        .padding(CWSpacing.md)
        .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
    }

    // MARK: - Actions
    private func saveAndDismiss() {
        vm.save(context: modelContext)
        dismiss()
    }

    private func setup() {
        if let t = editingTransaction {
            vm.loadForEdit(t)
        } else {
            // Set default wallet (yang isDefault = true)
            vm.selectedWallet = wallets.first(where: { $0.isDefault }) ?? wallets.first
        }
    }
}

#Preview {
    AddTransactionView()
        .modelContainer(for: [Transaction.self, Category.self, Wallet.self, Budget.self], inMemory: true)
        .preferredColorScheme(.dark)
}
