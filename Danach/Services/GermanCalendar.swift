import Foundation

/// Rechnet mit Werktagen nach deutschem Verständnis.
///
/// Werktage sind Montag bis Samstag. Sonntage und bundesweite Feiertage
/// zählen nicht. Regionale Feiertage – Fronleichnam, Allerheiligen,
/// Reformationstag und andere – bleiben unberücksichtigt, weil die App das
/// Bundesland nicht erfragt. Im Zweifel rechnet die App damit eher zu knapp
/// als zu großzügig, was bei Fristen die richtige Richtung ist.
enum GermanCalendar {

    static var calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin") ?? .current
        calendar.firstWeekday = 2
        return calendar
    }()

    /// Bundesweite gesetzliche Feiertage eines Jahres.
    static func nationalHolidays(in year: Int) -> Set<DateComponents> {
        let easter = easterSunday(year: year)
        var days: [Date] = [
            date(year, 1, 1),    // Neujahr
            date(year, 5, 1),    // Tag der Arbeit
            date(year, 10, 3),   // Tag der Deutschen Einheit
            date(year, 12, 25),  // 1. Weihnachtstag
            date(year, 12, 26)   // 2. Weihnachtstag
        ]
        days.append(offset(easter, by: -2))  // Karfreitag
        days.append(offset(easter, by: 1))   // Ostermontag
        days.append(offset(easter, by: 39))  // Christi Himmelfahrt
        days.append(offset(easter, by: 50))  // Pfingstmontag

        return Set(days.map { calendar.dateComponents([.year, .month, .day], from: $0) })
    }

    private static var holidayCache: [Int: Set<DateComponents>] = [:]

    static func isHoliday(_ date: Date) -> Bool {
        let year = calendar.component(.year, from: date)
        if holidayCache[year] == nil {
            holidayCache[year] = nationalHolidays(in: year)
        }
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return holidayCache[year]?.contains(components) ?? false
    }

    static func isWorkday(_ date: Date) -> Bool {
        // 1 = Sonntag im gregorianischen Kalender
        calendar.component(.weekday, from: date) != 1 && !isHoliday(date)
    }

    /// Addiert Werktage. `adding(0)` gibt den Ausgangstag unverändert zurück.
    static func addingWorkdays(_ count: Int, to date: Date) -> Date {
        guard count > 0 else { return date }
        var result = date
        var remaining = count
        while remaining > 0 {
            guard let next = calendar.date(byAdding: .day, value: 1, to: result) else { break }
            result = next
            if isWorkday(result) { remaining -= 1 }
        }
        return result
    }

    /// Ostersonntag nach der Gaußschen Osterformel in der Fassung von Meeus.
    static func easterSunday(year: Int) -> Date {
        let a = year % 19
        let b = year / 100
        let c = year % 100
        let d = b / 4
        let e = b % 4
        let f = (b + 8) / 25
        let g = (b - f + 1) / 3
        let h = (19 * a + b - d - g + 15) % 30
        let i = c / 4
        let k = c % 4
        let l = (32 + 2 * e + 2 * i - h - k) % 7
        let m = (a + 11 * h + 22 * l) / 451
        let month = (h + l - 7 * m + 114) / 31
        let day = ((h + l - 7 * m + 114) % 31) + 1
        return date(year, month, day)
    }

    // MARK: - Hilfen

    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return calendar.date(from: components) ?? Date()
    }

    private static func offset(_ date: Date, by days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: date) ?? date
    }
}
