import SwiftUI

struct ContentView: View {
    @State private var game = GameModel()
    @State private var showingSettings = false
    @State private var showingMethodology = false

    private let columns = [GridItem(.adaptive(minimum: 100), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    scoreBar
                    dateCard
                    if game.showTimer {
                        timerView
                    }
                    answerGrid
                    if let result = game.lastResult {
                        feedback(for: result)
                    }
                }
                .padding()
            }
            .navigationTitle("Weekday Guess")
            .inlineNavigationTitle()
            .toolbar {
                // `.navigation` sits in the top-left corner on iPhone.
                ToolbarItem(placement: .navigation) {
                    Button {
                        showingMethodology = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                    }
                    .accessibilityLabel("Methodology")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings, onDismiss: game.applySettings) {
                SettingsView(game: game)
            }
            .sheet(isPresented: $showingMethodology) {
                MethodologyView()
            }
            .sensoryFeedback(trigger: game.totalCount) { _, _ in
                game.lastResult?.isCorrect == true ? .success : .error
            }
        }
    }

    // MARK: Subviews

    private var scoreBar: some View {
        HStack {
            stat("Correct", "\(game.correctCount)/\(game.totalCount)")
            stat("Accuracy", game.accuracy.formatted(.percent.precision(.fractionLength(0))))
            stat("Streak", "\(game.currentStreak)")
            stat("Best", "\(game.bestStreak)")
        }
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 12))
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline)
                .monospacedDigit()
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private var dateCard: some View {
        VStack(spacing: 8) {
            Text("Which day of the week was")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(game.currentDate.formatted)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal)
        .background(.tint.opacity(0.12), in: .rect(cornerRadius: 20))
    }

    private var timerView: some View {
        Group {
            if game.lastResult == nil {
                TimelineView(.periodic(from: .now, by: 0.1)) { context in
                    let elapsed = context.date.timeIntervalSince(game.questionStart)
                    Label(formatSeconds(elapsed), systemImage: "stopwatch")
                }
            } else {
                HStack(spacing: 16) {
                    if let last = game.lastAnswerTime {
                        Label(formatSeconds(last), systemImage: "stopwatch")
                    }
                    if let average = game.averageAnswerTime {
                        Text("Avg \(formatSeconds(average))")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .font(.title3.monospacedDigit())
    }

    private var answerGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Weekday.buttonOrder, id: \.self) { weekday in
                Button {
                    game.guess(weekday: weekday)
                } label: {
                    Text(Weekday.name(weekday))
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
                .tint(tint(for: weekday))
                .allowsHitTesting(game.lastResult == nil)
            }
        }
    }

    private func tint(for weekday: Int) -> Color {
        guard let result = game.lastResult else { return .accentColor }
        if weekday == result.correct { return .green }
        if weekday == result.guessed { return .red }
        return .gray.opacity(0.5)
    }

    private func feedback(for result: GuessResult) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(result.isCorrect ? "Correct!" : "Wrong — it was \(Weekday.name(result.correct))")
                .font(.title2.bold())
                .foregroundStyle(result.isCorrect ? .green : .red)

            VStack(alignment: .leading, spacing: 8) {
                Text("Doomsday steps")
                    .font(.headline)
                ForEach(Array(game.steps.explanation.enumerated()), id: \.offset) { index, line in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(index + 1).")
                            .foregroundStyle(.secondary)
                        Text(line)
                    }
                    .font(.callout)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 12))

            Button {
                game.nextQuestion()
            } label: {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func formatSeconds(_ seconds: TimeInterval) -> String {
        seconds.formatted(.number.precision(.fractionLength(1))) + " s"
    }
}

extension View {
    /// Inline navigation title on iOS; no-op on platforms without that option.
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

#Preview {
    ContentView()
}
