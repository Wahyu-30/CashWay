import SwiftUI

struct AddSavingsGoalSheet: View {
    @EnvironmentObject private var dataStore: DataStore
    @Environment(\.dismiss)      private var dismiss
    
    @State private var name: String = ""
    @State private var amountText: String = ""
    @State private var selectedDate: Date = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    
    // Preset icons for goals
    let iconPresets = ["target", "laptopcomputer", "camera.fill", "airplane", "car.fill", "house.fill", "gamecontroller.fill"]
    @State private var selectedIcon = "target"
    
    let colorPresets = ["#1c6cff", "#00C9A7", "#ff33aa", "#ffcc02", "#F4A261", "#9019e6"]
    @State private var selectedColor = "#1c6cff"
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: CWSpacing.lg) {
                    
                    // MARK: - Header
                    VStack(spacing: CWSpacing.xs) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(hex: selectedColor))
                                .frame(width: 56, height: 56)
                            Image(systemName: selectedIcon)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                        }
                        Text("Target Tabungan Baru")
                            .font(.title3.bold())
                            .foregroundStyle(Color.cwTextPrimary)
                    }
                    .padding(.top, CWSpacing.md)
                    
                    // MARK: - Input Form
                    VStack(alignment: .leading, spacing: CWSpacing.sm) {
                        Text("Nama Target")
                            .font(.subheadline)
                            .foregroundStyle(Color.cwTextSecondary)
                        TextField("Contoh: MacBook Pro", text: $name)
                            .textFieldStyle(.plain)
                            .padding(CWSpacing.md)
                            .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
                            .overlay(RoundedRectangle(cornerRadius: CWRadius.md).stroke(Color.cwBorder, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: CWSpacing.sm) {
                        Text("Target Dana")
                            .font(.subheadline)
                            .foregroundStyle(Color.cwTextSecondary)
                        HStack {
                            Text("Rp").font(.title2).foregroundStyle(Color.cwTextSecondary)
                            TextField("0", text: $amountText)
                                .textFieldStyle(.plain)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .onChange(of: amountText) {
                                    amountText = amountText.filter { $0.isNumber }
                                }
                        }
                        .padding(CWSpacing.md)
                        .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: CWRadius.md).stroke(Color.cwBorder, lineWidth: 1))
                    }
                    
                    VStack(alignment: .leading, spacing: CWSpacing.sm) {
                        Text("Target Tercapai")
                            .font(.subheadline)
                            .foregroundStyle(Color.cwTextSecondary)
                        HStack {
                            Image(systemName: "calendar").foregroundStyle(Color(hex: selectedColor))
                            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                                .labelsHidden()
                        }
                        .padding(CWSpacing.md)
                        .background(Color.cwSurface, in: RoundedRectangle(cornerRadius: CWRadius.md))
                    }
                    
                    // MARK: - Icon & Color Picker
                    VStack(alignment: .leading, spacing: CWSpacing.sm) {
                        Text("Pilih Ikon")
                            .font(.subheadline)
                            .foregroundStyle(Color.cwTextSecondary)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(iconPresets, id: \.self) { icon in
                                    Button { selectedIcon = icon } label: {
                                        Image(systemName: icon)
                                            .font(.title3)
                                            .foregroundStyle(selectedIcon == icon ? .white : Color.cwTextSecondary)
                                            .frame(width: 44, height: 44)
                                            .background(selectedIcon == icon ? Color(hex: selectedColor) : Color.cwSurfaceElevated, in: Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        
                        Text("Pilih Warna")
                            .font(.subheadline)
                            .foregroundStyle(Color.cwTextSecondary)
                            .padding(.top, CWSpacing.sm)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(colorPresets, id: \.self) { color in
                                    Button { selectedColor = color } label: {
                                        Circle()
                                            .fill(Color(hex: color))
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                Circle().stroke(.white, lineWidth: selectedColor == color ? 2 : 0)
                                                    .padding(-4)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .padding(4)
                                }
                            }
                        }
                    }
                    
                }
                .padding(.horizontal, CWSpacing.md)
                .padding(.bottom, CWSpacing.xxl)
            }
            .background(Color.cwBackground)
            .navigationTitle("Tabungan Baru")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { dismiss() }.foregroundStyle(Color.cwTextSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") { save() }
                        .bold()
                        .foregroundStyle(canSave ? Color.cwAccent : Color.cwPlaceholder)
                        .disabled(!canSave)
                }
            }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.dark)
    }
    
    private var canSave: Bool {
        !name.isEmpty && CurrencyFormatter.parse(amountText) > 0
    }
    
    private func save() {
        let goal = SavingsGoal(
            name: name,
            targetAmount: CurrencyFormatter.parse(amountText),
            currentAmount: 0,
            targetDate: selectedDate,
            icon: selectedIcon,
            colorHex: selectedColor
        )
        dataStore.addSavingsGoal(goal)
        
        dismiss()
    }
}
