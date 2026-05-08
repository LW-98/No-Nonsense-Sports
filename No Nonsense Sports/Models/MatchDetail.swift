//
//  MatchDetail.swift
//  No Nonsense Sports
//

import Foundation

struct MatchDetail: Sendable {
    let event: ScoreboardEvent
    let body: Body

    enum Body: Sendable {
        case football(FootballSummary)
        case boxScore(BoxScoreSummary)
        case unsupported
    }
}

// MARK: - Helpers

enum TeamSide: Sendable, Hashable {
    case home
    case away
}

struct TeamStatPair: Identifiable, Sendable, Hashable {
    let label: String
    let home: String
    let away: String
    var id: String { label }
}

// MARK: - Football

struct FootballSummary: Sendable {
    let homeLineup: TeamLineup?
    let awayLineup: TeamLineup?
    let keyEvents: [KeyEvent]
    let teamStats: [TeamStatPair]
}

struct TeamLineup: Sendable, Hashable {
    let formation: String?
    let starters: [LineupPlayer]
    let substitutes: [LineupPlayer]
}

struct LineupPlayer: Identifiable, Sendable, Hashable {
    let id: String
    let name: String
    let jersey: String?
    let position: String?
}

struct KeyEvent: Identifiable, Sendable, Hashable {
    enum Kind: Sendable, Hashable {
        case goal
        case ownGoal
        case penaltyGoal
        case penaltyMissed
        case yellowCard
        case redCard
        case substitution
        case other(String)

        var symbolName: String {
            switch self {
            case .goal, .penaltyGoal:   return "soccerball"
            case .ownGoal:              return "arrow.uturn.backward.circle.fill"
            case .penaltyMissed:        return "xmark.circle.fill"
            case .yellowCard:           return "rectangle.portrait.fill"
            case .redCard:              return "rectangle.portrait.fill"
            case .substitution:         return "arrow.left.arrow.right"
            case .other:                return "circle.fill"
            }
        }
    }

    let id: String
    let kind: Kind
    let minute: String
    let side: TeamSide
    /// Short summary, typically just the player name(s).
    let text: String
    /// Full ESPN narrative for the event, shown when the row is expanded.
    /// `nil` when no extra detail is available beyond `text`.
    let longText: String?
    /// Score immediately after this event. Only set for goal-like events.
    let scoreAfter: EventScore?
}

struct EventScore: Sendable, Hashable {
    let home: Int
    let away: Int
}

// MARK: - Box Score

struct BoxScoreSummary: Sendable {
    let teamStats: [TeamStatPair]
    let topPerformers: [Performer]
}

struct Performer: Identifiable, Sendable, Hashable {
    let id: String
    let category: String   // e.g. "Passing", "Rebounds"
    let side: TeamSide
    let playerName: String
    let detail: String     // e.g. "28 PTS, 7 REB, 5 AST"
}
