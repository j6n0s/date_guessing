import SwiftUI

/// Explains the Doomsday method used to work out the weekday of any date.
struct MethodologyView: View {
    @Environment(\.dismiss) private var dismiss

    private let centuries = [1600, 1700, 1800, 1900, 2000, 2100, 2200, 2300, 2400]
    private let example = DoomsdayCalculator.steps(year: 1879, month: 3, day: 14)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    section("1. The idea") {
                        Text("In every year, a set of easy-to-remember dates — the \"doomsdays\" — all fall on the same weekday. Find that weekday for the year, then count from the nearest doomsday to your date.")
                    }

                    section("2. Century anchor") {
                        Text("Each century starts from an anchor day. The pattern repeats every 400 years.")
                        Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 6) {
                            ForEach(centuries, id: \.self) { century in
                                let anchor = DoomsdayCalculator.centuryAnchor(year: century)
                                GridRow {
                                    Text(century == 2400 ? "2400" : "\(String(century))s")
                                        .monospacedDigit()
                                    Text("\(Weekday.name(anchor)) (\(anchor))")
                                }
                            }
                        }
                        .padding(.top, 4)
                        Text("Number the weekdays Sunday = 0, Monday = 1, … Saturday = 6.")
                            .foregroundStyle(.secondary)
                    }

                    section("3. Doomsday of the year") {
                        Text("Take the last two digits of the year (YY):")
                        bullet("a = how many times 12 fits into YY")
                        bullet("b = the remainder")
                        bullet("c = how many times 4 fits into b")
                        Text("Doomsday = (anchor + a + b + c) mod 7")
                            .font(.body.bold())
                    }

                    section("4. Doomsday in each month") {
                        bullet("Even months: 4/4, 6/6, 8/8, 10/10, 12/12")
                        bullet("\"I work 9-to-5 at 7-Eleven\": 9 May, 5 September, 11 July, 7 November")
                        bullet("Pi Day: 14 March")
                        bullet("January 3 (January 4 in a leap year)")
                        bullet("February 28 (February 29 in a leap year)")
                    }

                    section("5. Leap years") {
                        Text("A year is a leap year if it is divisible by 4, except century years, which must be divisible by 400. So 2000 and 2400 are leap years, but 1700, 1800, 1900 are not.")
                    }

                    section("6. Count to the date") {
                        Text("Subtract the month's doomsday from your day, reduce mod 7, and add that to the year's doomsday.")
                    }

                    section("Example: \(String(example.day)) \(Weekday.monthName(example.month)) \(String(example.year))") {
                        ForEach(Array(example.explanation.enumerated()), id: \.offset) { index, line in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("\(index + 1).")
                                    .foregroundStyle(.secondary)
                                Text(line)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .navigationTitle("Doomsday Method")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.title3.bold())
            content()
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("•")
            Text(text)
        }
    }
}

#Preview {
    MethodologyView()
}
