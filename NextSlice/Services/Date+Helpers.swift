import Foundation

extension Date {

    /// Monday-anchored start of the ISO week.
    func weekStart(calendar: Calendar = .iso8601GregorianMonday) -> Date {
        var cal = calendar
        cal.firstWeekday = 2 // Monday
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: comps) ?? self
    }

    /// `startOfDay`, but as a method for chainability.
    var dayStart: Date {
        Calendar.current.startOfDay(for: self)
    }
}

extension Calendar {
    /// Gregorian calendar with Monday as the first day of the week.
    /// Use as a stable, locale-independent anchor for weekly retros.
    static let iso8601GregorianMonday: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 2
        cal.minimumDaysInFirstWeek = 4
        return cal
    }()
}
