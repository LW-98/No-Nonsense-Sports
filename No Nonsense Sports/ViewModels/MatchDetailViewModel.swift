//
//  MatchDetailViewModel.swift
//  No Nonsense Sports
//

import Foundation
import Observation

@MainActor
@Observable
final class MatchDetailViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    let event: ScoreboardEvent
    let sport: Sport
    private(set) var detail: MatchDetail?
    private(set) var state: LoadState = .idle

    private let service: ScoresService

    init(event: ScoreboardEvent, sport: Sport, service: ScoresService) {
        self.event = event
        self.sport = sport
        self.service = service
    }

    func load() async {
        state = .loading
        do {
            detail = try await service.fetchMatchDetail(for: sport, eventId: event.id, headerEvent: event)
            state = .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
