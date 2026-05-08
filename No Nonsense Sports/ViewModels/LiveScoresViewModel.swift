//
//  LiveScoresViewModel.swift
//  No Nonsense Sports
//

import Foundation
import Observation

@MainActor
@Observable
final class LiveScoresViewModel {
    enum LoadState: Equatable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    private(set) var events: [ScoreboardEvent] = []
    private(set) var state: LoadState = .idle
    var selectedSport: Sport {
        didSet { Task { await load() } }
    }
    var selectedDate: Date {
        didSet {
            // Only reload when the calendar day actually changes.
            if !Calendar.current.isDate(oldValue, inSameDayAs: selectedDate) {
                Task { await load() }
            }
        }
    }

    let service: ScoresService

    init(service: ScoresService,
         initialSport: Sport = Sport.all[0],
         initialDate: Date = .now) {
        self.service = service
        self.selectedSport = initialSport
        self.selectedDate = Calendar.current.startOfDay(for: initialDate)
    }

    func load() async {
        state = .loading
        do {
            let result = try await service.fetchScoreboard(for: selectedSport, on: selectedDate)
            events = result.sorted { lhs, rhs in
                if lhs.status.isLive != rhs.status.isLive { return lhs.status.isLive }
                return lhs.startDate < rhs.startDate
            }
            state = .loaded
        } catch {
            events = []
            state = .failed(error.localizedDescription)
        }
    }

    func refresh() async {
        await load()
    }
}
