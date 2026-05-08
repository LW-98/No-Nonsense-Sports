//
//  ScoreboardEvent.swift
//  No Nonsense Sports
//
//  Domain models used throughout the app. These are intentionally decoupled
//  from any specific API DTO so the UI does not depend on a vendor schema.
//

import Foundation

struct ScoreboardEvent: Identifiable, Hashable, Sendable {
    let id: String
    let startDate: Date
    let status: EventStatus
    let home: Competitor
    let away: Competitor
    let venue: String?
}

struct Competitor: Hashable, Sendable {
    let name: String
    let shortName: String
    let logoURL: URL?
    let score: Int?
    let record: String?
    /// Team primary colour (hex, no #)
    let primaryColor: String?
    /// Secondary colour fallback for clashes
    let secondaryColor: String?
}

enum EventStatus: Hashable, Sendable {
    case scheduled
    case inProgress(detail: String)
    case final
    case postponed
    case unknown(String)

    var isLive: Bool {
        if case .inProgress = self { return true }
        return false
    }

    var label: String {
        switch self {
        case .scheduled:              return "Scheduled"
        case .inProgress(let detail): return detail
        case .final:                  return "Final"
        case .postponed:              return "Postponed"
        case .unknown(let raw):       return raw
        }
    }
}
