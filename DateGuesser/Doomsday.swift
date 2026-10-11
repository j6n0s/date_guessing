import Foundation

/// Weekday helpers. Weekdays are numbered 0 = Sunday … 6 = Saturday throughout the app.
enum Weekday {
    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        // The app's text is English, so keep weekday and month names English too.
        calendar.locale = Locale(identifier: "en_US")
        return calendar
    }()

    /// Order of the answer buttons: Monday → Sunday.
    static let buttonOrder = [1, 2, 3, 4, 5, 6, 0]

    static func name(_ weekday: Int) -> String {
        calendar.weekdaySymbols[weekday]
    }

    static func monthName(_ month: Int) -> String {
        calendar.monthSymbols[month - 1]
    }
}

/// Every intermediate value of a Doomsday calculation, ready to be shown to the player.
struct DoomsdaySteps {
    let year: Int
    let month: Int
    let day: Int
    let isLeapYear: Bool
    let century: Int
    let anchor: Int
    let yearInCentury: Int
    let twelves: Int
    let remainder: Int
    let remainderFours: Int
    let yearDoomsday: Int
    let monthReference: Int
    let result: Int

    /// Human-readable explanation, one line per step.
    var explanation: [String] {
        let sum = anchor + twelves + remainder + remainderFours
        let difference = day - monthReference
        let offset = ((difference % 7) + 7) % 7
        let differenceText = difference >= 0 ? "+\(difference)" : "−\(abs(difference))"
        return [
            "Century \(century)00s → anchor \(Weekday.name(anchor)) (\(anchor))",
            "\(yearInCentury) = \(twelves) × 12 + \(remainder),  \(remainder) ÷ 4 = \(remainderFours)",
            "Doomsday of \(year): \(anchor) + \(twelves) + \(remainder) + \(remainderFours) = \(sum) → mod 7 = \(yearDoomsday) → \(Weekday.name(yearDoomsday))",
            "\(year) is \(isLeapYear ? "" : "not ")a leap year → doomsday in \(Weekday.monthName(month)) is day \(monthReference).",
            "\(day) − \(monthReference) = \(differenceText) days → mod 7 = \(offset) → \(Weekday.name(yearDoomsday)) + \(offset) = \(Weekday.name(result))"
        ]
    }
}

/// Conway's Doomsday algorithm for the Gregorian calendar.
enum DoomsdayCalculator {
    static func isLeapYear(_ year: Int) -> Bool {
        year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
    }

    static func daysInMonth(year: Int, month: Int) -> Int {
        switch month {
        case 2: return isLeapYear(year) ? 29 : 28
        case 4, 6, 9, 11: return 30
        default: return 31
        }
    }

    /// Anchor day of the century: 1600s/2000s Tuesday, 1700s/2100s Sunday,
    /// 1800s/2200s Friday, 1900s/2300s Wednesday.
    static func centuryAnchor(year: Int) -> Int {
        (5 * ((year / 100) % 4) + 2) % 7
    }

    /// The day of each month that always falls on the year's doomsday.
    static func monthReference(year: Int, month: Int) -> Int {
        let leap = isLeapYear(year)
        let references = [leap ? 4 : 3, leap ? 29 : 28, 14, 4, 9, 6, 11, 8, 5, 10, 7, 12]
        return references[month - 1]
    }

    static func steps(year: Int, month: Int, day: Int) -> DoomsdaySteps {
        let anchor = centuryAnchor(year: year)
        let yearInCentury = year % 100
        let twelves = yearInCentury / 12
        let remainder = yearInCentury % 12
        let remainderFours = remainder / 4
        let yearDoomsday = (anchor + twelves + remainder + remainderFours) % 7
        let reference = monthReference(year: year, month: month)
        let result = (((yearDoomsday + day - reference) % 7) + 7) % 7

        return DoomsdaySteps(
            year: year,
            month: month,
            day: day,
            isLeapYear: isLeapYear(year),
            century: year / 100,
            anchor: anchor,
            yearInCentury: yearInCentury,
            twelves: twelves,
            remainder: remainder,
            remainderFours: remainderFours,
            yearDoomsday: yearDoomsday,
            monthReference: reference,
            result: result
        )
    }

    static func weekday(year: Int, month: Int, day: Int) -> Int {
        steps(year: year, month: month, day: day).result
    }
}
