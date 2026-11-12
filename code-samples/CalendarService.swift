import Foundation
import EventKit
import SwiftUI

// ====================================================================
// Read-only EventKit integration — the reason the native app exists.
// Fetches events from all device calendars for a visible month so
// they can be shown alongside HomeSync events. Never writes.
// ====================================================================

/// A lightweight, immutable snapshot of a device calendar event.
struct DeviceCalendarEvent: Identifiable, Equatable {
    let id: String
    let title: String
    let dateKey: String     // the day it appears on, "YYYY-MM-DD"
    let isAllDay: Bool
    let timeLabel: String   // "All day" or "2:30 PM"
    let calendarColor: Color
}

final class CalendarService {
    private let store = EKEventStore()

    /// Ask for read access to the device calendar (iOS 17+ API).
    /// Returns true when granted.
    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    var authorizationStatus: EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    /// All device events in the given month (plus the visible lead-in /
    /// lead-out days), grouped by dateKey. Multi-day events appear on
    /// each day they span.
    func eventsByDay(year: Int, month: Int) -> [String: [DeviceCalendarEvent]] {
        var startComps = DateComponents()
        startComps.year = year; startComps.month = month; startComps.day = 1
        guard let monthStart = DateHelpers.calendar.date(from: startComps),
              let rangeStart = DateHelpers.calendar.date(byAdding: .day, value: -7, to: monthStart),
              let monthEnd = DateHelpers.calendar.date(byAdding: .month, value: 1, to: monthStart),
              let rangeEnd = DateHelpers.calendar.date(byAdding: .day, value: 7, to: monthEnd) else {
            return [:]
        }

        let predicate = store.predicateForEvents(withStart: rangeStart, end: rangeEnd, calendars: nil)
        let events = store.events(matching: predicate)

        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short

        var byDay: [String: [DeviceCalendarEvent]] = [:]
        for event in events {
            guard let start = event.startDate else { continue }
            let end = event.endDate ?? start

            // Walk each day this event covers.
            var day = DateHelpers.calendar.startOfDay(for: start)
            let lastDay = DateHelpers.calendar.startOfDay(
                // An all-day event "ends" at midnight of the next day —
                // subtract a second so it doesn't bleed onto an extra day.
                for: event.isAllDay ? end.addingTimeInterval(-1) : end
            )
            while day <= lastDay {
                let key = DateHelpers.dateKey(day)
                let item = DeviceCalendarEvent(
                    id: (event.eventIdentifier ?? UUID().uuidString) + "@" + key,
                    title: event.title ?? "Busy",
                    dateKey: key,
                    isAllDay: event.isAllDay,
                    timeLabel: event.isAllDay ? "All day" : timeFormatter.string(from: start),
                    calendarColor: (event.calendar as EKCalendar?).map { Color(cgColor: $0.cgColor) } ?? .blue
                )
                byDay[key, default: []].append(item)
                guard let next = DateHelpers.calendar.date(byAdding: .day, value: 1, to: day) else { break }
                day = next
            }
        }

        // Sort each day's events: all-day first, then by start time label.
        for (key, items) in byDay {
            byDay[key] = items.sorted {
                if $0.isAllDay != $1.isAllDay { return $0.isAllDay }
                return $0.timeLabel < $1.timeLabel
            }
        }
        return byDay
    }
}
