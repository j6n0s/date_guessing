import SwiftUI

struct SettingsView: View {
    @Bindable var game: GameModel
    @Environment(\.dismiss) private var dismiss

    private let years = Array(GameModel.yearLimits)

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 0) {
                        yearPicker("From", selection: $game.minYear)
                        yearPicker("To", selection: $game.maxYear)
                    }
                    .frame(height: 160)
                } header: {
                    Text("Year range")
                } footer: {
                    Text("Dates are picked from \(String(game.minYear)) to \(String(game.maxYear)). Allowed range: 1600–2400.")
                }

                Section("Timer") {
                    Toggle("Show timer", isOn: $game.showTimer)
                }

                Section {
                    Button("Reset score", role: .destructive) {
                        game.resetScore()
                    }
                } footer: {
                    Text("Your best streak is kept.")
                }
            }
            .navigationTitle("Settings")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func yearPicker(_ title: String, selection: Binding<Int>) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Picker(title, selection: selection) {
                ForEach(years, id: \.self) { year in
                    Text(String(year)).tag(year)
                }
            }
            #if os(iOS)
            .pickerStyle(.wheel)
            #endif
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    SettingsView(game: GameModel())
}
