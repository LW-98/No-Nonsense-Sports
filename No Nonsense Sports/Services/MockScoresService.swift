//
//  MockScoresService.swift
//  No Nonsense Sports
//

import Foundation

final class MockScoresService: ScoresService {
    private let events: [ScoreboardEvent]
    private let delay: Duration

    init(events: [ScoreboardEvent] = MockScoresService.sampleEvents,
         delay: Duration = .milliseconds(150)) {
        self.events = events
        self.delay = delay
    }

    func fetchScoreboard(for sport: Sport, on date: Date) async throws -> [ScoreboardEvent] {
        try? await Task.sleep(for: delay)
        return events
    }

    func fetchMatchDetail(for sport: Sport, eventId: String, headerEvent: ScoreboardEvent) async throws -> MatchDetail {
        try? await Task.sleep(for: delay)
        let body: MatchDetail.Body = sport.kind == .football
            ? .football(MockScoresService.sampleFootball)
            : .boxScore(MockScoresService.sampleBoxScore)
        return MatchDetail(event: headerEvent, body: body)
    }

    static let sampleFootball = FootballSummary(
        homeLineup: TeamLineup(
            formation: "4-3-3",
            starters: [
                LineupPlayer(id: "1",  name: "A. Becker",     jersey: "1",  position: "GK"),
                LineupPlayer(id: "2",  name: "T. Alexander-Arnold", jersey: "66", position: "RB"),
                LineupPlayer(id: "3",  name: "I. Konaté",     jersey: "5",  position: "CB"),
                LineupPlayer(id: "4",  name: "V. van Dijk",   jersey: "4",  position: "CB"),
                LineupPlayer(id: "5",  name: "A. Robertson",  jersey: "26", position: "LB"),
                LineupPlayer(id: "6",  name: "A. Mac Allister", jersey: "10", position: "MF"),
                LineupPlayer(id: "7",  name: "D. Szoboszlai", jersey: "8",  position: "MF"),
                LineupPlayer(id: "8",  name: "C. Gakpo",      jersey: "18", position: "MF"),
                LineupPlayer(id: "9",  name: "M. Salah",      jersey: "11", position: "FW"),
                LineupPlayer(id: "10", name: "D. Núñez",      jersey: "9",  position: "FW"),
                LineupPlayer(id: "11", name: "L. Díaz",       jersey: "7",  position: "FW")
            ],
            substitutes: [
                LineupPlayer(id: "s1", name: "C. Kelleher", jersey: "62", position: "GK"),
                LineupPlayer(id: "s2", name: "J. Gomez",    jersey: "2",  position: "DF"),
                LineupPlayer(id: "s3", name: "H. Elliott",  jersey: "19", position: "MF")
            ]
        ),
        awayLineup: TeamLineup(
            formation: "4-2-3-1",
            starters: [
                LineupPlayer(id: "21", name: "Ederson", jersey: "31", position: "GK"),
                LineupPlayer(id: "22", name: "K. Walker", jersey: "2", position: "RB"),
                LineupPlayer(id: "23", name: "R. Dias", jersey: "3", position: "CB"),
                LineupPlayer(id: "24", name: "J. Stones", jersey: "5", position: "CB"),
                LineupPlayer(id: "25", name: "J. Gvardiol", jersey: "24", position: "LB"),
                LineupPlayer(id: "26", name: "Rodri", jersey: "16", position: "MF"),
                LineupPlayer(id: "27", name: "M. Kovačić", jersey: "8", position: "MF"),
                LineupPlayer(id: "28", name: "B. Silva", jersey: "20", position: "MF"),
                LineupPlayer(id: "29", name: "K. De Bruyne", jersey: "17", position: "MF"),
                LineupPlayer(id: "30", name: "P. Foden", jersey: "47", position: "FW"),
                LineupPlayer(id: "31", name: "E. Haaland", jersey: "9", position: "FW")
            ],
            substitutes: []
        ),
        keyEvents: [
            KeyEvent(id: "1", kind: .goal,         minute: "23'", side: .home, text: "M. Salah",
                     longText: "Goal! Liverpool 1, Manchester City 0. Mohamed Salah (Liverpool) right footed shot from the centre of the box to the bottom right corner.",
                     scoreAfter: EventScore(home: 1, away: 0)),
            KeyEvent(id: "2", kind: .yellowCard,   minute: "34'", side: .away, text: "Rodri",
                     longText: "Rodri (Manchester City) is shown the yellow card for a bad foul.",
                     scoreAfter: nil),
            KeyEvent(id: "3", kind: .goal,         minute: "58'", side: .away, text: "E. Haaland",
                     longText: "Goal! Liverpool 1, Manchester City 1. Erling Haaland (Manchester City) header from very close range to the high centre of the goal.",
                     scoreAfter: EventScore(home: 1, away: 1)),
            KeyEvent(id: "4", kind: .substitution, minute: "67'", side: .home, text: "Elliott → Díaz",
                     longText: "Substitution, Liverpool. Harvey Elliott replaces Luis Díaz.",
                     scoreAfter: nil),
            KeyEvent(id: "5", kind: .penaltyGoal,  minute: "82'", side: .home, text: "M. Salah (pen)",
                     longText: "Goal! Liverpool 2, Manchester City 1. Mohamed Salah (Liverpool) converts the penalty with a right footed shot to the bottom left corner.",
                     scoreAfter: EventScore(home: 2, away: 1))
        ],
        teamStats: [
            TeamStatPair(label: "Possession",    home: "53%", away: "47%"),
            TeamStatPair(label: "Shots",         home: "14",  away: "11"),
            TeamStatPair(label: "Shots on Tgt",  home: "6",   away: "4"),
            TeamStatPair(label: "Corners",       home: "7",   away: "3"),
            TeamStatPair(label: "Fouls",         home: "9",   away: "12")
        ]
    )

    static let sampleBoxScore = BoxScoreSummary(
        teamStats: [
            TeamStatPair(label: "Field Goal %",     home: "47.8%", away: "44.2%"),
            TeamStatPair(label: "3-Point %",        home: "38.5%", away: "33.3%"),
            TeamStatPair(label: "Rebounds",         home: "44",    away: "41"),
            TeamStatPair(label: "Assists",          home: "26",    away: "21"),
            TeamStatPair(label: "Turnovers",        home: "11",    away: "14"),
            TeamStatPair(label: "Points in Paint",  home: "48",    away: "42")
        ],
        topPerformers: [
            Performer(id: "p1", category: "Points",   side: .home, playerName: "L. James",     detail: "28 PTS, 7 REB, 9 AST"),
            Performer(id: "p2", category: "Rebounds", side: .home, playerName: "A. Davis",     detail: "12 REB, 22 PTS"),
            Performer(id: "p3", category: "Points",   side: .away, playerName: "J. Tatum",     detail: "31 PTS, 6 AST"),
            Performer(id: "p4", category: "Assists",  side: .away, playerName: "D. White",     detail: "8 AST, 14 PTS")
        ]
    )

    static let sampleEvents: [ScoreboardEvent] = [
        ScoreboardEvent(
            id: "1",
            startDate: Date(),
            status: .inProgress(detail: "Q3 04:21"),
            home: Competitor(name: "Los Angeles Lakers", shortName: "LAL", logoURL: nil, score: 78, record: "32-18", primaryColor: "552583", secondaryColor: "FDB927"),
            away: Competitor(name: "Boston Celtics",     shortName: "BOS", logoURL: nil, score: 82, record: "40-12", primaryColor: "007A33", secondaryColor: "BA9653"),
            venue: "Crypto.com Arena"
        ),
        ScoreboardEvent(
            id: "2",
            startDate: Date().addingTimeInterval(3600),
            status: .scheduled,
            home: Competitor(name: "Golden State Warriors", shortName: "GSW", logoURL: nil, score: nil, record: "28-22", primaryColor: "1D428A", secondaryColor: "FFC72C"),
            away: Competitor(name: "Denver Nuggets",        shortName: "DEN", logoURL: nil, score: nil, record: "34-16", primaryColor: "0E2240", secondaryColor: "869397"),
            venue: "Chase Center"
        ),
        ScoreboardEvent(
            id: "3",
            startDate: Date().addingTimeInterval(-7200),
            status: .final,
            home: Competitor(name: "Miami Heat",        shortName: "MIA", logoURL: nil, score: 110, record: "27-23", primaryColor: "98002E", secondaryColor: "F9A01B"),
            away: Competitor(name: "New York Knicks",   shortName: "NYK", logoURL: nil, score: 104, record: "31-19", primaryColor: "006BB6", secondaryColor: "F58426"),
            venue: "Kaseya Center"
        )
    ]
}
