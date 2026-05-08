//
//  LiveScoresViewModelTests.swift
//  No Nonsense SportsTests
//

import Foundation
import Testing
@testable import No_Nonsense_Sports

@MainActor
struct LiveScoresViewModelTests {

    @Test("Loads events successfully and sorts live games first")
    func loadSortsLiveFirst() async throws {
        let now = Date()
        let scheduled = ScoreboardEvent(
            id: "a", startDate: now.addingTimeInterval(3600), status: .scheduled,
            home: Competitor(name: "A", shortName: "A", logoURL: nil, score: nil, record: nil, primaryColor: nil),
            away: Competitor(name: "B", shortName: "B", logoURL: nil, score: nil, record: nil, primaryColor: nil),
            venue: nil
        )
        let live = ScoreboardEvent(
            id: "b", startDate: now, status: .inProgress(detail: "Q1"),
            home: Competitor(name: "C", shortName: "C", logoURL: nil, score: 0, record: nil, primaryColor: nil),
            away: Competitor(name: "D", shortName: "D", logoURL: nil, score: 0, record: nil, primaryColor: nil),
            venue: nil
        )

        let service = MockScoresService(events: [scheduled, live], delay: .zero)
        let vm = LiveScoresViewModel(service: service)

        await vm.load()

        #expect(vm.state == LiveScoresViewModel.LoadState.loaded)
        #expect(vm.events.count == 2)
        #expect(vm.events.first?.id == "b") // live first
    }

    @Test("Surfaces failure state on service error")
    func loadFailureSetsErrorState() async {
        struct FailingService: ScoresService {
            func fetchScoreboard(for sport: Sport, on date: Date) async throws -> [ScoreboardEvent] {
                throw APIError.http(status: 500)
            }
            func fetchMatchDetail(for sport: Sport, eventId: String, headerEvent: ScoreboardEvent) async throws -> MatchDetail {
                throw APIError.http(status: 500)
            }
        }

        let vm = LiveScoresViewModel(service: FailingService())
        await vm.load()

        if case .failed = vm.state {
            #expect(vm.events.isEmpty)
        } else {
            Issue.record("Expected failed state, got \(vm.state)")
        }
    }
}
