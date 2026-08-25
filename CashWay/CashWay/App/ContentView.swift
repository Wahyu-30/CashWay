import SwiftUI
import SwiftData

// ============================================================
// MARK: - ContentView
// Root navigation. iOS pakai TabView, macOS pakai custom sidebar.
// ============================================================

struct ContentView: View {

    @State private var selectedTab: Tab = .dashboard

    enum Tab: String, CaseIterable {
        case dashboard    = "Dashboard"
        case transactions = "Transaksi"
        case budget       = "Budget"
        case reports      = "Laporan"
        case settings     = "Pengaturan"

        var icon: String {
            switch self {
            case .dashboard:    return "house.fill"
            case .transactions: return "list.bullet.rectangle.fill"
            case .budget:       return "target"
            case .reports:      return "chart.bar.fill"
            case .settings:     return "gear"
            }
        }

        var accentColor: Color {
            switch self {
            case .dashboard:    return Color(hex: "#1c6cff") // Signal Blue
            case .transactions: return Color(hex: "#00acfe") // Tag Sky
            case .budget:       return Color(hex: "#ff33aa") // Tag Hot Pink
            case .reports:      return Color(hex: "#ffcc02") // Tag Sunflower
            case .settings:     return Color(hex: "#9019e6") // Tag Violet
            }
        }
    }

    var body: some View {
        #if os(iOS)
        iosLayout
        #else
        macLayout
        #endif
    }

    // MARK: - iOS: Tab Bar
    private var iosLayout: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                NavigationStack {
                    destination(for: tab)
                }
                .tabItem { Label(tab.rawValue, systemImage: tab.icon) }
                .tag(tab)
            }
        }
        .tint(.cwAccent)
    }

    // MARK: - macOS: Custom Sidebar + Detail
    private var macLayout: some View {
        NavigationSplitView(columnVisibility: .constant(.all)) {
            VStack(spacing: 0) {
                // ── App Header ──────────────────────────
                VStack(spacing: 6) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#1c6cff"), Color(hex: "#9019e6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 52)
                        Image(systemName: "coloncurrencysign.arrow.trianglehead.counterclockwise.rotate.90")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    Text("CashWay")
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Financial Tracker")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.cwTextSecondary)
                }
                .padding(.top, 24)
                .padding(.bottom, 28)

                // ── Divider ──────────────────────────
                Rectangle()
                    .fill(Color.cwBorder)
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)

                // ── Menu Items ──────────────────────────
                VStack(spacing: 4) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        SidebarItem(
                            tab: tab,
                            isSelected: selectedTab == tab
                        ) {
                            selectedTab = tab
                        }
                    }
                }
                .padding(.horizontal, 12)

                Spacer()

                // ── Bottom Badge ──────────────────────────
                VStack(spacing: 4) {
                    Rectangle()
                        .fill(Color.cwBorder)
                        .frame(height: 1)
                        .padding(.horizontal, 16)
                    HStack(spacing: 8) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#1c6cff"), Color(hex: "#9019e6")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                            .overlay(
                                Text("W")
                                    .font(.system(size: 13, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                            )
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Way")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.cwTextPrimary)
                            Text("Personal Account")
                                .font(.system(size: 10))
                                .foregroundStyle(Color.cwTextSecondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .frame(minWidth: 200)
            .background(Color.cwSurface)
        } detail: {
            destination(for: selectedTab)
                .environment(\.dynamicTypeSize, .xxLarge) // Perbesar semua teks secara proporsional
                .environment(\.controlSize, .large)
                .environment(\.defaultMinListRowHeight, 56)
        }
        .navigationSplitViewStyle(.balanced)
    }

    // MARK: - Tab Routing
    @ViewBuilder
    private func destination(for tab: Tab) -> some View {
        switch tab {
        case .dashboard:    DashboardView()
        case .transactions: TransactionListView()
        case .budget:       BudgetView()
        case .reports:      ReportsView()
        case .settings:     SettingsView()
        }
    }
}

// MARK: - SidebarItem
struct SidebarItem: View {
    let tab: ContentView.Tab
    let isSelected: Bool
    let action: () -> Void

    @State private var isHovered = false
    @State private var iconScale: CGFloat = 1.0

    var body: some View {
        Button(action: {
            // Trigger bounce animation on tap
            withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
                iconScale = 0.8
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    iconScale = 1.0
                }
            }
            action()
        }) {
            HStack(spacing: 14) {
                // Icon container with bounce
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? tab.accentColor : (isHovered ? tab.accentColor.opacity(0.15) : Color.cwBackground))
                        .frame(width: 38, height: 38)
                        .shadow(color: isSelected ? tab.accentColor.opacity(0.4) : .clear, radius: 6, y: 3)
                    Image(systemName: tab.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : (isHovered ? tab.accentColor : Color.cwTextSecondary))
                        .scaleEffect(iconScale)
                }

                Text(tab.rawValue)
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? .white : (isHovered ? Color.cwTextPrimary : Color.cwTextSecondary))

                Spacer()

                // Active indicator — pulsing dot
                if isSelected {
                    PulsingDot(color: tab.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tab.accentColor.opacity(0.15) : (isHovered ? Color.cwBackground.opacity(0.6) : Color.clear))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? tab.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [Transaction.self, Category.self, Wallet.self, Budget.self],
            inMemory: true
        )
        .preferredColorScheme(.dark)
}
