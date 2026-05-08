//
//  Sport.swift
//  No Nonsense Sports
//

import Foundation

/// Sport/league with ESPN API path
struct Sport: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let symbolName: String
    let apiPath: String
    let kind: SportKind

    nonisolated static let all: [Sport] = [
        Sport(id: "nfl",     displayName: "NFL",              symbolName: "football.fill",    apiPath: "football/nfl",            kind: .americanFootball),
        Sport(id: "nba",     displayName: "NBA",              symbolName: "basketball.fill",  apiPath: "basketball/nba",          kind: .basketball),
        Sport(id: "mlb",     displayName: "MLB",              symbolName: "baseball.fill",    apiPath: "baseball/mlb",            kind: .baseball),
        Sport(id: "nhl",     displayName: "NHL",              symbolName: "hockey.puck.fill", apiPath: "hockey/nhl",              kind: .hockey),
        Sport(id: "epl",     displayName: "Premier League",   symbolName: "soccerball",       apiPath: "soccer/eng.1",            kind: .football),
        Sport(id: "ucl",     displayName: "Champions League", symbolName: "soccerball",       apiPath: "soccer/uefa.champions",   kind: .football)
    ]
}

enum SportKind: Sendable, Hashable {
    case football
    case americanFootball
    case basketball
    case baseball
    case hockey

    var usesBoxScore: Bool {
        self != .football
    }
}
