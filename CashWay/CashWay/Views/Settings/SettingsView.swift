import SwiftUI
import SwiftData

// ============================================================
// MARK: - SettingsView
// Pengaturan aplikasi: nama user, gaji pokok, iCloud sync, dll.
// Data disimpan ke UserDefaults.
// ============================================================

struct SettingsView: View {

    @AppStorage("userName")      private var userName      = "Way"
    @AppStorage("monthlySalary") private var monthlySalary = 4_500_000.0
    @AppStorage("iCloudSync")    private var iCloudSync    = false

    @State private var salaryText: String = ""
    @State private var showDeleteAlert = false
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            profileSection
            financeSection
            syncSection
            aboutSection
            dangerSection
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .scrollContentBackground(.hidden)
        .background(Color.cwBackground)
        .navigationTitle("Pengaturan")
        .onAppear { salaryText = String(Int(monthlySalary)) }
        .alert("Hapus Semua Data?", isPresented: $showDeleteAlert) {
            Button("Hapus", role: .destructive) { deleteAllData() }
            Button("Batal", role: .cancel) {}
        } message: {
            Text("Semua transaksi, budget, dan wallet akan dihapus permanen.")
        }
    }

    private var profileSection: some View {
        Section("Profil") {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.title2).foregroundStyle(Color.cwAccent)
                TextField("Nama kamu", text: $userName)
                    .foregroundStyle(Color.cwTextPrimary)
            }
        }
        .listRowBackground(Color.cwSurface)
    }

    private var financeSection: some View {
        Section {
            HStack {
                Image(systemName: "building.2.fill").foregroundStyle(Color.cwAccent)
                Text("Gaji Pokok Bulanan").foregroundStyle(Color.cwTextPrimary)
                Spacer()
                HStack(spacing: 2) {
                    Text("Rp").foregroundStyle(Color.cwTextSecondary)
                    TextField("4500000", text: $salaryText)
                        #if os(iOS)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        #endif
                        .foregroundStyle(Color.cwTextPrimary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                        .onChange(of: salaryText) {
                            let digits = salaryText.filter { $0.isNumber }
                            salaryText = digits
                            monthlySalary = Double(digits) ?? 0
                        }
                }
            }
            HStack {
                Image(systemName: "info.circle").foregroundStyle(Color.cwTextSecondary)
                Text("Digunakan untuk Smart Advisory")
                    .font(.caption).foregroundStyle(Color.cwTextSecondary)
            }
        } header: {
            Text("Keuangan")
        } footer: {
            Text("Gaji pokok digunakan untuk menghitung saran dan peringatan pengeluaran.")
                .foregroundStyle(Color.cwTextSecondary)
        }
        .listRowBackground(Color.cwSurface)
    }

    private var syncSection: some View {
        Section {
            Toggle(isOn: $iCloudSync) {
                HStack {
                    Image(systemName: "icloud.fill").foregroundStyle(Color.cwAccent)
                    VStack(alignment: .leading) {
                        Text("iCloud Sync").foregroundStyle(Color.cwTextPrimary)
                        Text("Sinkronisasi Mac ↔ iPhone").font(.caption).foregroundStyle(Color.cwTextSecondary)
                    }
                }
            }
            .tint(Color.cwAccent)
            if iCloudSync {
                HStack {
                    Image(systemName: "checkmark.icloud.fill").foregroundStyle(Color.cwIncome)
                    Text("Sync aktif. Data tersimpan di iCloud kamu.")
                        .font(.caption).foregroundStyle(Color.cwTextSecondary)
                }
            }
        } header: {
            Text("Sinkronisasi")
        } footer: {
            Text("iCloud Sync menggunakan storage iCloud kamu yang sudah aktif.")
                .foregroundStyle(Color.cwTextSecondary)
        }
        .listRowBackground(Color.cwSurface)
    }

    private var aboutSection: some View {
        Section("Tentang") {
            HStack {
                Image(systemName: "app.fill").foregroundStyle(Color.cwAccent)
                Text("CashWay").foregroundStyle(Color.cwTextPrimary)
                Spacer()
                Text("v1.0").foregroundStyle(Color.cwTextSecondary).font(.caption)
            }
            HStack {
                Image(systemName: "externaldrive.fill").foregroundStyle(Color.cwAccent)
                Text("Penyimpanan").foregroundStyle(Color.cwTextPrimary)
                Spacer()
                Text("Lokal (offline)").foregroundStyle(Color.cwTextSecondary).font(.caption)
            }
        }
        .listRowBackground(Color.cwSurface)
    }

    private var dangerSection: some View {
        Section("Zona Bahaya") {
            Button { showDeleteAlert = true } label: {
                HStack {
                    Image(systemName: "trash.fill").foregroundStyle(Color.cwExpense)
                    Text("Hapus Semua Data").foregroundStyle(Color.cwExpense)
                }
            }
        }
        .listRowBackground(Color.cwSurface)
    }

    private func deleteAllData() {
        let allTransactions = (try? modelContext.fetch(FetchDescriptor<Transaction>())) ?? []
        allTransactions.forEach { modelContext.delete($0) }
        let allBudgets = (try? modelContext.fetch(FetchDescriptor<Budget>())) ?? []
        allBudgets.forEach { modelContext.delete($0) }
        let allWallets = (try? modelContext.fetch(FetchDescriptor<Wallet>())) ?? []
        allWallets.forEach { modelContext.delete($0) }
        let allCategories = (try? modelContext.fetch(FetchDescriptor<Category>())) ?? []
        allCategories.forEach { modelContext.delete($0) }
        try? modelContext.save()
        DefaultData.seedIfNeeded(context: modelContext)
    }
}
