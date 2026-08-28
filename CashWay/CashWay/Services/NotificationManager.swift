import Foundation
import UserNotifications
import Combine

// ============================================================
// MARK: - NotificationManager
// Mengelola izin & penjadwalan notifikasi lokal untuk CashWay.
// Mendukung dua jenis pengingat:
//  1. Harian  — mengingatkan pengguna mencatat pengeluaran
//  2. Bulanan — mengingatkan pengguna di awal bulan (tanggal 1)
// ============================================================

@MainActor
class NotificationManager: ObservableObject {

    static let shared = NotificationManager()

    @Published var isAuthorized: Bool = false

    private let center = UNUserNotificationCenter.current()

    // MARK: - Notification IDs
    private let dailyID   = "cashway.daily.reminder"
    private let monthlyID = "cashway.monthly.reminder"
    
    // MARK: - Default Times (untuk DatePicker di Settings)
    static func defaultDailyTime() -> Date {
        let h = UserDefaults.standard.integer(forKey: "notif_daily_hour")
        let m = UserDefaults.standard.integer(forKey: "notif_daily_minute")
        var comps = DateComponents()
        comps.hour   = h > 0 ? h : 20
        comps.minute = m > 0 ? m : 0
        return Calendar.current.date(from: comps) ?? Date()
    }

    static func defaultMonthlyTime() -> Date {
        let h = UserDefaults.standard.integer(forKey: "notif_monthly_hour")
        let m = UserDefaults.standard.integer(forKey: "notif_monthly_minute")
        var comps = DateComponents()
        comps.hour   = h > 0 ? h : 9
        comps.minute = m > 0 ? m : 0
        return Calendar.current.date(from: comps) ?? Date()
    }

    init() {
        Task {
            await refreshAuthorizationStatus()
        }
    }

    // MARK: - Request Permission
    func requestPermission() async {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            if granted {
                rescheduleAll()
            }
        } catch {
            print("NotificationManager: Gagal meminta izin — \(error.localizedDescription)")
        }
    }

    // MARK: - Reschedule All (dipanggil saat setting berubah)
    func rescheduleAll() {
        let dailyEnabled   = UserDefaults.standard.bool(forKey: "notif_daily_enabled")
        let monthlyEnabled = UserDefaults.standard.bool(forKey: "notif_monthly_enabled")

        // Selalu bersihkan dulu agar tidak duplikat
        center.removePendingNotificationRequests(withIdentifiers: [dailyID, monthlyID])

        if dailyEnabled   { scheduleDailyReminder() }
        if monthlyEnabled { scheduleMonthlyReminder() }
    }

    // MARK: - Cancel All
    func cancelAll() {
        center.removePendingNotificationRequests(withIdentifiers: [dailyID, monthlyID])
    }

    // MARK: - Refresh Authorization Status
    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Daily Reminder (default 20:00)
    private func scheduleDailyReminder() {
        let hour   = UserDefaults.standard.integer(forKey: "notif_daily_hour")
        let minute = UserDefaults.standard.integer(forKey: "notif_daily_minute")

        let content = UNMutableNotificationContent()
        content.title = "Sudah catat hari ini? 📝"
        content.body  = "Jangan lupa catat pengeluaran dan pemasukan kamu hari ini di CashWay!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour   = hour   > 0 ? hour   : 20
        dateComponents.minute = minute > 0 ? minute : 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: dailyID, content: content, trigger: trigger)

        center.add(request) { error in
            if let error { print("NotificationManager: Gagal jadwal harian — \(error)") }
        }
    }

    // MARK: - Monthly Reminder (default 09:00 tanggal 1)
    private func scheduleMonthlyReminder() {
        let hour   = UserDefaults.standard.integer(forKey: "notif_monthly_hour")
        let minute = UserDefaults.standard.integer(forKey: "notif_monthly_minute")

        let content = UNMutableNotificationContent()
        content.title = "Awal bulan baru! 🎯"
        content.body  = "Yuk atur budget dan catat pendapatan bulan ini di CashWay. Mulai yang baik dari sekarang!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.day    = 1
        dateComponents.hour   = hour   > 0 ? hour   : 9
        dateComponents.minute = minute > 0 ? minute : 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: monthlyID, content: content, trigger: trigger)

        center.add(request) { error in
            if let error { print("NotificationManager: Gagal jadwal bulanan — \(error)") }
        }
    }
}
