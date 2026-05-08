//
//  ESPNScoresService.swift
//  No Nonsense Sports
//
//  Live implementation backed by ESPN's public scoreboard endpoint:
//      https://site.api.espn.com/apis/site/v2/sports/{sport}/{league}/scoreboard
//
//  This endpoint requires no API key and is suitable as a starter backend.
//  Swap in a paid API (e.g. API-SPORTS, SportRadar) by implementing
//  `ScoresService` and registering it in `AppEnvironment.live()`.
//

import Foundation

final class ESPNScoresService: ScoresService {
    let client: APIClient
    let host: String

    init(client: APIClient, host: String = "site.api.espn.com") {
        self.client = client
        self.host = host
    }

    func fetchScoreboard(for sport: Sport, on date: Date) async throws -> [ScoreboardEvent] {
        let calendar = Calendar.current
        let endpoint = Endpoint(
            host: host,
            path: "/apis/site/v2/sports/\(sport.apiPath)/scoreboard",
            queryItems: [URLQueryItem(name: "dates", value: Self.datesQuery(around: date, calendar: calendar))]
        )
        let decoder = JSONDecoder()
        let dto = try await client.send(endpoint, as: ESPNScoreboardDTO.self, decoder: decoder)

        // ESPN buckets games by US-Eastern day, so a fixture that starts at
        // 23:30 ET Friday is the same instant as 04:30 BST Saturday — the user
        // expects it under Saturday. We over-fetch by ±1 day to capture every
        // timezone shift, then filter by the user's local calendar day.
        return dto.events
            .compactMap { $0.toDomain() }
            .filter { calendar.isDate($0.startDate, inSameDayAs: date) }
    }

    /// Builds a `YYYYMMDD-YYYYMMDD` range covering the day before and after
    /// the user's selected day so that timezone-shifted fixtures are included.
    private static func datesQuery(around date: Date, calendar: Calendar) -> String {
        let start = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        let end   = calendar.date(byAdding: .day, value:  1, to: date) ?? date
        return "\(format(start, calendar: calendar))-\(format(end, calendar: calendar))"
    }

    private static func format(_ date: Date, calendar: Calendar) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d%02d%02d", c.year ?? 1970, c.month ?? 1, c.day ?? 1)
    }
}

// MARK: - DTO

private nonisolated struct ESPNScoreboardDTO: Decodable, Sendable {
    let events: [EventDTO]

    nonisolated struct EventDTO: Decodable, Sendable {
        let id: String
        let date: String
        let competitions: [CompetitionDTO]

        func toDomain() -> ScoreboardEvent? {
            guard let competition = competitions.first,
                  competition.competitors.count >= 2,
                  let start = ESPNScoreboardDTO.parseDate(date) else { return nil }

            let home = competition.competitors.first { $0.homeAway == "home" } ?? competition.competitors[0]
            let away = competition.competitors.first { $0.homeAway == "away" } ?? competition.competitors[1]

            return ScoreboardEvent(
                id: id,
                startDate: start,
                status: competition.status?.toDomain() ?? .unknown("—"),
                home: home.toDomain(),
                away: away.toDomain(),
                venue: competition.venue?.fullName
            )
        }
    }

    /// ESPN returns timestamps like `2026-05-08T23:00Z` (no seconds) and
    /// occasionally `2026-05-08T23:00:00Z`. The stock `ISO8601DateFormatter`
    /// only accepts the latter, so we try both formats.
    static func parseDate(_ string: String) -> Date? {
        if let date = isoWithSeconds.date(from: string) { return date }
        if let date = isoWithoutSeconds.date(from: string) { return date }
        return nil
    }

    private static let isoWithSeconds: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    private static let isoWithoutSeconds: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mmZ"
        return f
    }()

    nonisolated struct CompetitionDTO: Decodable, Sendable {
        let competitors: [CompetitorDTO]
        let status: StatusDTO?
        let venue: VenueDTO?
    }

    nonisolated struct CompetitorDTO: Decodable, Sendable {
        let homeAway: String?
        let score: String?
        let team: TeamDTO
        let records: [RecordDTO]?

        func toDomain() -> Competitor {
            Competitor(
                name: team.displayName ?? team.name ?? "Unknown",
                shortName: team.abbreviation ?? team.shortDisplayName ?? team.name ?? "—",
                logoURL: team.logo.flatMap(URL.init(string:)),
                score: score.flatMap(Int.init),
                record: records?.first?.summary,
                primaryColor: team.color,
                secondaryColor: team.alternateColor
            )
        }
    }

    nonisolated struct TeamDTO: Decodable, Sendable {
        let name: String?
        let displayName: String?
        let shortDisplayName: String?
        let abbreviation: String?
        let logo: String?
        let color: String?
        let alternateColor: String?
    }

    nonisolated struct RecordDTO: Decodable, Sendable { let summary: String? }

    nonisolated struct VenueDTO: Decodable, Sendable { let fullName: String? }

    nonisolated struct StatusDTO: Decodable, Sendable {
        let type: StatusTypeDTO
        nonisolated struct StatusTypeDTO: Decodable, Sendable {
            let state: String         // "pre", "in", "post"
            let completed: Bool
            let detail: String?
            let shortDetail: String?
        }

        func toDomain() -> EventStatus {
            switch type.state {
            case "pre":  return .scheduled
            case "in":   return .inProgress(detail: type.shortDetail ?? type.detail ?? "Live")
            case "post": return type.completed ? .final : .unknown(type.detail ?? "Post")
            default:     return .unknown(type.detail ?? type.state)
            }
        }
    }
}
