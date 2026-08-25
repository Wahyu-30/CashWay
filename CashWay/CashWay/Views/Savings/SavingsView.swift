import SwiftUI
import SwiftData

struct SavingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavingsGoal.targetDate, order: .forward) private var goals: [SavingsGoal]
    
    @State private var showAddGoal = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: CWSpacing.lg) {
                
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Tabungan & Target")
                            .font(.title2.bold())
                            .foregroundStyle(Color.cwTextPrimary)
                        Text("Mulai sisihkan uang untuk mimpimu")
                            .font(.caption)
                            .foregroundStyle(Color.cwTextSecondary)
                    }
                    Spacer()
                    Button {
                        showAddGoal = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Color.cwTextPrimary)
                            .frame(width: 40, height: 40)
                            .background(Color.cwSurfaceElevated, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, CWSpacing.md)
                
                // Summary Card
                let totalSaved = goals.reduce(Decimal(0)) { $0 + $1.currentAmount }
                let totalTarget = goals.reduce(Decimal(0)) { $0 + $1.targetAmount }
                let globalProgress = totalTarget > 0 ? NSDecimalNumber(decimal: totalSaved / totalTarget).doubleValue : 0
                
                if !goals.isEmpty {
                    ZStack {
                        RoundedRectangle(cornerRadius: CWRadius.xl)
                            .fill(LinearGradient(
                                colors: [Color(hex: "#102330"), Color.cwSurface],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .overlay(RoundedRectangle(cornerRadius: CWRadius.xl).stroke(Color.cwBorder, lineWidth: 1))
                        
                        VStack(spacing: CWSpacing.md) {
                            Text("Total Terkumpul")
                                .font(.caption)
                                .foregroundStyle(Color.cwTextSecondary)
                            AnimatedNumberText(value: totalSaved, color: .cwIncome, font: .system(size: 32, weight: .bold, design: .rounded))
                            
                            VStack(spacing: 4) {
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4).fill(Color.cwSurfaceElevated).frame(height: 8)
                                        RoundedRectangle(cornerRadius: 4).fill(Color.cwIncome)
                                            .frame(width: geo.size.width * CGFloat(globalProgress), height: 8)
                                    }
                                }
                                .frame(height: 8)
                                HStack {
                                    Text("\(Int(globalProgress * 100))% dari target \(CurrencyFormatter.formatCompact(totalTarget))")
                                        .font(.caption2)
                                        .foregroundStyle(Color.cwTextSecondary)
                                    Spacer()
                                }
                            }
                        }
                        .padding(CWSpacing.lg)
                    }
                }
                
                // List of Goals
                if goals.isEmpty {
                    ContentUnavailableView(
                        "Belum ada target tabungan",
                        systemImage: "banknote",
                        description: Text("Ketuk + untuk membuat target tabungan pertamamu, seperti beli kamera atau liburan.")
                    )
                    .frame(height: 300)
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: CWSpacing.md) {
                        ForEach(goals) { goal in
                            SavingsGoalCard(goal: goal)
                        }
                    }
                }
                
            }
            .padding(.horizontal, CWSpacing.md)
        }
        .background(Color.cwBackground)
        .navigationTitle("Tabungan")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .sheet(isPresented: $showAddGoal) {
            AddSavingsGoalSheet()
        }
    }
}

// MARK: - SavingsGoalCard
struct SavingsGoalCard: View {
    @Environment(\.modelContext) private var modelContext
    let goal: SavingsGoal
    
    @State private var showDeposit = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: CWSpacing.sm) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: CWRadius.sm)
                        .fill(Color(hex: goal.colorHex).opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: goal.icon)
                        .font(.title3)
                        .foregroundStyle(Color(hex: goal.colorHex))
                }
                Spacer()
                Menu {
                    Button("Tambah Setoran") { showDeposit = true }
                    Button("Hapus", role: .destructive) { showDeleteAlert = true }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color.cwTextSecondary)
                        .padding(8)
                }
                .menuStyle(.borderlessButton)
            }
            
            Text(goal.name)
                .font(.subheadline.bold())
                .foregroundStyle(Color.cwTextPrimary)
                .lineLimit(1)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(CurrencyFormatter.formatCompact(goal.currentAmount))
                    .font(.title3.bold())
                    .foregroundStyle(Color.cwIncome)
                    .monospacedDigit()
                Text("/ \(CurrencyFormatter.formatCompact(goal.targetAmount))")
                    .font(.caption2)
                    .foregroundStyle(Color.cwTextSecondary)
            }
            
            VStack(spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3).fill(Color.cwBackground).frame(height: 6)
                        RoundedRectangle(cornerRadius: 3).fill(Color(hex: goal.colorHex))
                            .frame(width: geo.size.width * CGFloat(goal.progress), height: 6)
                    }
                }
                .frame(height: 6)
                
                HStack {
                    Text("\(Int(goal.progress * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(Color(hex: goal.colorHex))
                    Spacer()
                    if let date = goal.targetDate {
                        Text(date.formatted(.dateTime.day().month(.abbreviated).year()))
                            .font(.caption2)
                            .foregroundStyle(Color.cwTextSecondary)
                    }
                }
            }
            .padding(.top, 4)
            
            Button {
                showDeposit = true
            } label: {
                Text("Setor")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.cwSurfaceElevated, in: RoundedRectangle(cornerRadius: CWRadius.sm))
                    .foregroundStyle(Color.cwTextPrimary)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(CWSpacing.md)
        .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
        .overlay(RoundedRectangle(cornerRadius: CWRadius.md).stroke(Color.cwBorder, lineWidth: 1))
        .sheet(isPresented: $showDeposit) {
            AddDepositSheet(goal: goal)
        }
        .alert("Hapus Tabungan?", isPresented: $showDeleteAlert) {
            Button("Batal", role: .cancel) {}
            Button("Hapus", role: .destructive) {
                modelContext.delete(goal)
                try? modelContext.save()
            }
        } message: {
            Text("Target tabungan ini akan dihapus permanen. Uang yang disetor tidak akan terhapus dari log transaksi.")
        }
    }
}
