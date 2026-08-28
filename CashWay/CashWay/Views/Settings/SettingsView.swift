import SwiftUI

// ============================================================
// MARK: - SettingsView
// Pengaturan aplikasi: nama user, gaji pokok, iCloud sync, dll.
// Data disimpan ke UserDefaults.
// ============================================================

struct SettingsView: View {
    @AppStorage("monthlySalary") private var monthlySalary = 4_500_000.0
    @AppStorage("iCloudSync")    private var iCloudSync    = false
    
    // Notification toggles
    @AppStorage("notif_daily_enabled")   private var dailyEnabled   = false
    @AppStorage("notif_monthly_enabled") private var monthlyEnabled = false

    @State private var salaryText: String = ""
    @State private var showDeleteAlert = false
    @EnvironmentObject private var dataStore: DataStore
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var notifManager = NotificationManager.shared

    // Local state untuk TextField agar tidak glitch saat diketik
    @State private var localNickname: String = ""
    
    // Time pickers
    @State private var dailyTime: Date   = NotificationManager.defaultDailyTime()
    @State private var monthlyTime: Date = NotificationManager.defaultMonthlyTime()

    var body: some View {
        List {
            SlideInCard(index: 0) { profileSection }
            SlideInCard(index: 1) { notificationSection }
            SlideInCard(index: 2) { syncSection }
            SlideInCard(index: 3) { aboutSection }
            SlideInCard(index: 4) { dangerSection }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #endif
        .scrollContentBackground(.hidden)
        .background(Color.cwBackground)
        .navigationTitle("Pengaturan")
        .onAppear {
            salaryText = String(Int(monthlySalary))
            localNickname = authManager.userNickname
            dailyTime   = NotificationManager.defaultDailyTime()
            monthlyTime = NotificationManager.defaultMonthlyTime()
        }
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
                TextField("Nama kamu", text: $localNickname)
                    .foregroundStyle(Color.cwTextPrimary)
                    .onChange(of: localNickname) { _, newValue in
                        authManager.updateNickname(newValue)
                    }
            }
        }
        .listRowBackground(Color.cwSurface)
    }
    
    // MARK: - Notification Section
    private var notificationSection: some View {
        Section {
            // Toggle Pengingat Harian
            Toggle(isOn: $dailyEnabled) {
                HStack {
                    Image(systemName: "bell.fill").foregroundStyle(Color.cwAccent)
                    VStack(alignment: .leading) {
                        Text("Pengingat Harian").foregroundStyle(Color.cwTextPrimary)
                        Text("Catat pengeluaran setiap hari").font(.caption).foregroundStyle(Color.cwTextSecondary)
                    }
                }
            }
            .tint(Color.cwAccent)
            .onChange(of: dailyEnabled) { _, enabled in
                handleNotificationToggle(enabled: enabled)
            }
            
            if dailyEnabled {
                DatePicker("Jam Pengingat Harian", selection: $dailyTime, displayedComponents: .hourAndMinute)
                    .foregroundStyle(Color.cwTextPrimary)
                    .onChange(of: dailyTime) { _, newTime in
                        let cal = Calendar.current
                        UserDefaults.standard.set(cal.component(.hour, from: newTime),   forKey: "notif_daily_hour")
                        UserDefaults.standard.set(cal.component(.minute, from: newTime), forKey: "notif_daily_minute")
                        notifManager.rescheduleAll()
                    }
            }
            
            // Divider
            Divider().listRowBackground(Color.cwSurface)
            
            // Toggle Pengingat Bulanan
            Toggle(isOn: $monthlyEnabled) {
                HStack {
                    Image(systemName: "calendar.badge.clock").foregroundStyle(Color.cwAccent)
                    VStack(alignment: .leading) {
                        Text("Pengingat Awal Bulan").foregroundStyle(Color.cwTextPrimary)
                        Text("Setiap tanggal 1 tiap bulan").font(.caption).foregroundStyle(Color.cwTextSecondary)
                    }
                }
            }
            .tint(Color.cwAccent)
            .onChange(of: monthlyEnabled) { _, enabled in
                handleNotificationToggle(enabled: enabled)
            }
            
            if monthlyEnabled {
                DatePicker("Jam Pengingat Bulanan", selection: $monthlyTime, displayedComponents: .hourAndMinute)
                    .foregroundStyle(Color.cwTextPrimary)
                    .onChange(of: monthlyTime) { _, newTime in
                        let cal = Calendar.current
                        UserDefaults.standard.set(cal.component(.hour, from: newTime),   forKey: "notif_monthly_hour")
                        UserDefaults.standard.set(cal.component(.minute, from: newTime), forKey: "notif_monthly_minute")
                        notifManager.rescheduleAll()
                    }
            }
            
            // Status izin
            if !notifManager.isAuthorized && (dailyEnabled || monthlyEnabled) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                    Text("Izin notifikasi belum diberikan. Buka Pengaturan iPhone → CashWay → Notifikasi.")
                        .font(.caption).foregroundStyle(Color.cwTextSecondary)
                }
            }
            
        } header: {
            Text("Notifikasi Pengingat")
        } footer: {
            Text("Notifikasi akan muncul di layar HP kamu sebagai pengingat mencatat keuangan.")
                .foregroundStyle(Color.cwTextSecondary)
        }
        .listRowBackground(Color.cwSurface)
    }
    
    private func handleNotificationToggle(enabled: Bool) {
        if enabled && !notifManager.isAuthorized {
            Task {
                await notifManager.requestPermission()
            }
        } else {
            notifManager.rescheduleAll()
        }
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
            Button {
                dataStore.clearData()
                authManager.signOut()
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right").foregroundStyle(Color.cwAccent)
                    Text("Keluar (Sign Out)").foregroundStyle(Color.cwTextPrimary)
                }
            }
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
        for tx in dataStore.transactions { dataStore.deleteTransaction(tx) }
        for b in dataStore.budgets { dataStore.deleteBudget(b) }
        for s in dataStore.savingsGoals { dataStore.deleteSavingsGoal(s) }
    }
}
