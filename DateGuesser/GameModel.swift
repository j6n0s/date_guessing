import Foundation
import Observation

/// A date to guess, stored as plain components so the Doomsday calculation stays exact.
struct GameDate: Equatable {
    let year: Int
    let month: Int
    let day: Int

    var formatted: String {
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = Weekday.calendar.date(from: components) else {
            return "\(day) \(Weekday.monthName(month)) \(year)"
        }
        var style = Date.FormatStyle(date: .long, time: .omitted)
        style.calendar = Weekday.calendar
        style.timeZone = Weekday.calendar.timeZone
        style.locale = Weekday.calendar.locale ?? .current
        return date.formatted(style)
    }
}

private extension Int {
    func clamped(to range: ClosedRange<Int>) -> Int {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}

struct GuessResult {
    let guessed: Int
    let correct: Int
    var isCorrect: Bool { guessed == correct }
}

@MainActor
@Observable
final class GameModel {
    static let yearLimits = 1600...2400

    private enum Keys {
        static let minYear = "minYear"
        static let maxYear = "maxYear"
        static let showTimer = "showTimer"
        static let bestStreak = "bestStreak"
    }

    private let defaults = UserDefaults.standard

    // MARK: Settings

    /// First year of the range. The settings pickers keep it within `yearLimits`;
    /// the end year is pushed forward if needed so the range is never empty.
    var minYear: Int {
        didSet {
            if maxYear < minYear { maxYear = minYear }
            defaults.set(minYear, forKey: Keys.minYear)
        }
    }

    var maxYear: Int {
        didSet {
            if minYear > maxYear { minYear = maxYear }
            defaults.set(maxYear, forKey: Keys.maxYear)
        }
    }

    var showTimer: Bool {
        didSet { defaults.set(showTimer, forKey: Keys.showTimer) }
    }

    // MARK: Game state

    private(set) var currentDate = GameDate(year: 2000, month: 1, day: 1)
    private(set) var lastResult: GuessResult?
    private(set) var correctCount = 0
    private(set) var totalCount = 0
    private(set) var currentStreak = 0
    private(set) var bestStreak: Int {
        didSet { defaults.set(bestStreak, forKey: Keys.bestStreak) }
    }

    private(set) var questionStart = Date()
    private(set) var lastAnswerTime: TimeInterval?
    private var totalAnswerTime: TimeInterval = 0

    var accuracy: Double {
        totalCount == 0 ? 0 : Double(correctCount) / Double(totalCount)
    }

    var averageAnswerTime: TimeInterval? {
        totalCount == 0 ? nil : totalAnswerTime / Double(totalCount)
    }

    var steps: DoomsdaySteps {
        DoomsdayCalculator.steps(year: currentDate.year, month: currentDate.month, day: currentDate.day)
    }

    init() {
        let limits = Self.yearLimits
        let storedMin = (defaults.object(forKey: Keys.minYear) as? Int ?? 1900).clamped(to: limits)
        let storedMax = (defaults.object(forKey: Keys.maxYear) as? Int ?? 2099).clamped(to: limits)
        minYear = storedMin
        maxYear = max(storedMin, storedMax)
        showTimer = defaults.object(forKey: Keys.showTimer) as? Bool ?? true
        bestStreak = defaults.integer(forKey: Keys.bestStreak)
        nextQuestion()
    }

    // MARK: Actions

    func guess(weekday: Int) {
        guard lastResult == nil else { return }

        let elapsed = Date().timeIntervalSince(questionStart)
        let correct = DoomsdayCalculator.weekday(year: currentDate.year, month: currentDate.month, day: currentDate.day)
        let result = GuessResult(guessed: weekday, correct: correct)

        lastResult = result
        lastAnswerTime = elapsed
        totalAnswerTime += elapsed
        totalCount += 1

        if result.isCorrect {
            correctCount += 1
            currentStreak += 1
            if currentStreak > bestStreak { bestStreak = currentStreak }
        } else {
            currentStreak = 0
        }
    }

    func nextQuestion() {
        let year = Int.random(in: minYear...maxYear)
        let month = Int.random(in: 1...12)
        let day = Int.random(in: 1...DoomsdayCalculator.daysInMonth(year: year, month: month))
        currentDate = GameDate(year: year, month: month, day: day)
        lastResult = nil
        questionStart = Date()
    }

    /// Picks a new date if the current one falls outside a changed year range.
    func applySettings() {
        if !(minYear...maxYear).contains(currentDate.year) {
            nextQuestion()
        }
    }

    func resetScore() {
        correctCount = 0
        totalCount = 0
        currentStreak = 0
        totalAnswerTime = 0
        lastAnswerTime = nil
        nextQuestion()
    }
}
