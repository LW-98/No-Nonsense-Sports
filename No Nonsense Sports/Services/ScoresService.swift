//
//  ScoresService.swift
//  No Nonsense Sports
//

import Foundation

protocol ScoresService: Sendable {
    func fetchScoreboard(for sport: Sport, on date: Date) async throws -> [ScoreboardEvent]
    func fetchMatchDetail(for sport: Sport, eventId: String, headerEvent: ScoreboardEvent) async throws -> MatchDetail
}
