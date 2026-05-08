//
//  ESPNSummary.swift
//  No Nonsense Sports
//

import Foundation

extension ESPNScoresService {
    func fetchMatchDetail(for sport: Sport, eventId: String, headerEvent: ScoreboardEvent) async throws -> MatchDetail {
        let endpoint = Endpoint(
            host: "site.api.espn.com",
            path: "/apis/site/v2/sports/\(sport.apiPath)/summary",
            queryItems: [URLQueryItem(name: "event", value: eventId)]
        )
        let dto = try await client.send(endpoint, as: ESPNSummaryDTO.self)
        return ESPNSummaryAdapter.adapt(dto: dto, sport: sport, headerEvent: headerEvent)
    }
}

// MARK: - DTOs

nonisolated struct ESPNSummaryDTO: Decodable, Sendable {
    let header: HeaderDTO?
    let boxscore: BoxscoreDTO?
    let rosters: [RosterDTO]?
    let keyEvents: [KeyEventDTO]?
    let leaders: [LeadersGroupDTO]?

    nonisolated struct HeaderDTO: Decodable, Sendable {
        let competitions: [CompetitionDTO]?
        nonisolated struct CompetitionDTO: Decodable, Sendable {
            let competitors: [CompetitorDTO]?
            nonisolated struct CompetitorDTO: Decodable, Sendable {
                let id: String?
                let homeAway: String?
            }
        }
    }

    nonisolated struct BoxscoreDTO: Decodable, Sendable {
        let teams: [TeamStatBlock]?
        nonisolated struct TeamStatBlock: Decodable, Sendable {
            let homeAway: String?
            let team: TeamRef?
            let statistics: [Statistic]?
            nonisolated struct Statistic: Decodable, Sendable {
                let name: String?
                let label: String?
                let displayValue: String?
            }
        }
    }

    nonisolated struct RosterDTO: Decodable, Sendable {
        let homeAway: String?
        let team: TeamRef?
        let formation: Formation?
        let roster: [Entry]?

        /// ESPN sends formation as string or object - handle both
        nonisolated struct Formation: Decodable, Sendable {
            let name: String?

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                if let string = try? container.decode(String.self) {
                    self.name = string
                    return
                }
                struct Object: Decodable { let name: String? }
                let obj = try container.decode(Object.self)
                self.name = obj.name
            }
        }
        nonisolated struct Entry: Decodable, Sendable {
            let starter: Bool?
            let subbedIn: Bool?
            let position: Position?
            let athlete: Athlete?
            let jersey: String?
            nonisolated struct Position: Decodable, Sendable {
                let abbreviation: String?
            }
            nonisolated struct Athlete: Decodable, Sendable {
                let id: String?
                let displayName: String?
                let shortName: String?
                let jersey: String?
            }
        }
    }

    nonisolated struct KeyEventDTO: Decodable, Sendable {
        let id: String?
        let type: TypeRef?
        let clock: Clock?
        let team: TeamRef?
        let text: String?
        let shortText: String?
        let scoringPlay: Bool?
        let shootout: Bool?
        let athletesInvolved: [Athlete]?

        nonisolated struct TypeRef: Decodable, Sendable {
            let id: String?
            let text: String?
        }
        nonisolated struct Clock: Decodable, Sendable {
            let displayValue: String?
        }
        nonisolated struct Athlete: Decodable, Sendable {
            let id: String?
            let displayName: String?
            let shortName: String?
        }
    }

    nonisolated struct LeadersGroupDTO: Decodable, Sendable {
        let team: TeamRef?
        let homeAway: String?
        let leaders: [Category]?
        nonisolated struct Category: Decodable, Sendable {
            let displayName: String?
            let leaders: [Leader]?
            nonisolated struct Leader: Decodable, Sendable {
                let displayValue: String?
                let athlete: Athlete?
                nonisolated struct Athlete: Decodable, Sendable {
                    let id: String?
                    let displayName: String?
                    let shortName: String?
                }
            }
        }
    }

    nonisolated struct TeamRef: Decodable, Sendable {
        let id: String?
        let homeAway: String?
    }
}

// MARK: - Stats

/// Stat label + ESPN field names
struct CommonStat {
    let label: String
    let candidates: [String]
}

extension SportKind {
    var commonStats: [CommonStat] {
        switch self {
        case .football: return [
            CommonStat(label: "Possession",     candidates: ["possessionpct", "possession"]),
            CommonStat(label: "Shots",          candidates: ["totalshots", "shots"]),
            CommonStat(label: "Shots on Target",candidates: ["shotsontarget", "shotsongoal"]),
            CommonStat(label: "Corners",        candidates: ["woncorners", "corners", "cornerkicks"]),
            CommonStat(label: "Fouls",          candidates: ["foulscommitted", "fouls"]),
            CommonStat(label: "Yellow Cards",   candidates: ["yellowcards"]),
            CommonStat(label: "Red Cards",      candidates: ["redcards"])
        ]
        case .basketball: return [
            CommonStat(label: "Field Goals",    candidates: ["fieldgoalsmade-fieldgoalsattempted", "field goals made-field goals attempted"]),
            CommonStat(label: "Field Goal %",   candidates: ["fieldgoalpct", "field goal %"]),
            CommonStat(label: "3-Pointers",     candidates: ["threepointfieldgoalsmade-threepointfieldgoalsattempted", "3pt"]),
            CommonStat(label: "3-Point %",      candidates: ["threepointfieldgoalpct", "3-point %"]),
            CommonStat(label: "Free Throw %",   candidates: ["freethrowpct", "free throw %"]),
            CommonStat(label: "Rebounds",       candidates: ["totalrebounds", "rebounds"]),
            CommonStat(label: "Assists",        candidates: ["assists"]),
            CommonStat(label: "Turnovers",      candidates: ["turnovers"])
        ]
        case .americanFootball: return [
            CommonStat(label: "Total Yards",    candidates: ["totalyards", "nettotalyards"]),
            CommonStat(label: "Passing Yards",  candidates: ["netpassingyards", "passingyards"]),
            CommonStat(label: "Rushing Yards",  candidates: ["rushingyards"]),
            CommonStat(label: "1st Downs",      candidates: ["firstdowns"]),
            CommonStat(label: "3rd Down",       candidates: ["thirddowneff", "thirddownconversions"]),
            CommonStat(label: "Turnovers",      candidates: ["turnovers"]),
            CommonStat(label: "Possession",     candidates: ["possessiontime", "timeofpossession"])
        ]
        case .baseball: return [
            CommonStat(label: "Hits",           candidates: ["hits"]),
            CommonStat(label: "Runs",           candidates: ["runs"]),
            CommonStat(label: "Home Runs",      candidates: ["homeruns"]),
            CommonStat(label: "RBI",            candidates: ["rbis", "rbi"]),
            CommonStat(label: "Strikeouts",     candidates: ["strikeouts"]),
            CommonStat(label: "Errors",         candidates: ["errors"])
        ]
        case .hockey: return [
            CommonStat(label: "Shots on Goal",  candidates: ["shotsongoal", "shots"]),
            CommonStat(label: "Power Play",     candidates: ["powerplaypct", "powerplay"]),
            CommonStat(label: "Faceoff %",      candidates: ["faceoffwinpct", "faceoffwins"]),
            CommonStat(label: "Hits",           candidates: ["hits"]),
            CommonStat(label: "Blocked Shots",  candidates: ["blockedshots"]),
            CommonStat(label: "Penalty Mins",   candidates: ["penaltyminutes"])
        ]
        }
    }
}

private extension Dictionary where Key == String {
    func find(_ candidates: [String]) -> Value? {
        for c in candidates {
            if let v = self[c.lowercased()] { return v }
        }
        return nil
    }
}

// MARK: - Adapter

enum ESPNSummaryAdapter {
    static func adapt(dto: ESPNSummaryDTO, sport: Sport, headerEvent: ScoreboardEvent) -> MatchDetail {
        // Resolve which team id is home / away from the header.
        let competitors = dto.header?.competitions?.first?.competitors ?? []
        let homeID = competitors.first { $0.homeAway == "home" }?.id
        let awayID = competitors.first { $0.homeAway == "away" }?.id

        let body: MatchDetail.Body
        switch sport.kind {
        case .football:
            body = .football(buildFootball(dto: dto, homeID: homeID, awayID: awayID))
        case .americanFootball, .basketball, .baseball, .hockey:
            body = .boxScore(buildBoxScore(dto: dto, sport: sport, homeID: homeID, awayID: awayID))
        }
        return MatchDetail(event: headerEvent, body: body)
    }

    private static func buildFootball(dto: ESPNSummaryDTO, homeID: String?, awayID: String?) -> FootballSummary {
        var home: TeamLineup?
        var away: TeamLineup?
        for roster in dto.rosters ?? [] {
            let lineup = lineup(from: roster)
            let side = side(for: roster.team?.id, homeID: homeID, awayID: awayID,
                            fallback: roster.homeAway)
            switch side {
            case .home: home = lineup
            case .away: away = lineup
            case nil:   break
            }
        }

        var events: [KeyEvent] = []
        var homeScore = 0
        var awayScore = 0
        for (offset, e) in (dto.keyEvents ?? []).enumerated() {
            guard let side = side(for: e.team?.id, homeID: homeID, awayID: awayID, fallback: nil),
                  let kind = keyEventKind(typeText: e.type?.text, scoringPlay: e.scoringPlay) else {
                continue
            }

            let athletes = (e.athletesInvolved ?? [])
                .compactMap { $0.shortName ?? $0.displayName }
                .map(trimReason)

            let text: String
            switch kind {
            case .substitution:
                // Display as "player coming on → player coming off".
                if athletes.count >= 2 {
                    // ESPN sends [outgoing, incoming], flip to (on → off)
                    text = "\(athletes[1]) → \(athletes[0])"
                } else if let parsed = parseSubstitution(e.text ?? "") {
                    text = "\(parsed.on) → \(parsed.off)"
                } else {
                    text = athletes.first ?? e.shortText ?? e.text ?? ""
                }
            case .yellowCard, .redCard:
                // Icon shows card type, just show player name
                let raw = athletes.first ?? e.shortText ?? e.text ?? ""
                text = cleanEventText(raw)
            case .goal, .penaltyGoal, .ownGoal, .penaltyMissed:
                // Show scorer with suffix (pen/OG/pen missed)
                let raw = athletes.first ?? e.shortText ?? e.text ?? ""
                let player = cleanEventText(raw)
                let suffix: String
                switch kind {
                case .penaltyGoal:    suffix = " (pen)"
                case .ownGoal:        suffix = " (OG)"
                case .penaltyMissed:  suffix = " (pen missed)"
                default:              suffix = ""
                }
                text = player + suffix
            default:
                text = athletes.joined(separator: " → ").nilIfEmpty
                    ?? e.shortText
                    ?? e.text
                    ?? ""
            }

            // Long narrative for expanded view (only if adds info)
            let long = e.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            let longText: String? = (long != nil && long != text) ? long : nil

            // Running score for goals (own goals credit opposite side)
            var scoreAfter: EventScore?
            switch kind {
            case .goal, .penaltyGoal:
                if side == .home { homeScore += 1 } else { awayScore += 1 }
                scoreAfter = EventScore(home: homeScore, away: awayScore)
            case .ownGoal:
                if side == .home { awayScore += 1 } else { homeScore += 1 }
                scoreAfter = EventScore(home: homeScore, away: awayScore)
            default:
                scoreAfter = nil
            }

            events.append(KeyEvent(
                id: e.id ?? "ke-\(offset)",
                kind: kind,
                minute: e.clock?.displayValue ?? "",
                side: side,
                text: text,
                longText: longText,
                scoreAfter: scoreAfter
            ))
        }

        let stats = buildStats(from: dto.boxscore?.teams ?? [], homeID: homeID, awayID: awayID, kind: .football)

        return FootballSummary(homeLineup: home, awayLineup: away, keyEvents: events, teamStats: stats)
    }

    private static func lineup(from roster: ESPNSummaryDTO.RosterDTO) -> TeamLineup {
        var starters: [LineupPlayer] = []
        var subs: [LineupPlayer] = []
        for entry in roster.roster ?? [] {
            let player = LineupPlayer(
                id: entry.athlete?.id ?? UUID().uuidString,
                name: entry.athlete?.shortName ?? entry.athlete?.displayName ?? "Unknown",
                jersey: entry.jersey ?? entry.athlete?.jersey,
                position: entry.position?.abbreviation
            )
            if entry.starter == true {
                starters.append(player)
            } else {
                subs.append(player)
            }
        }
        return TeamLineup(formation: roster.formation?.name, starters: starters, substitutes: subs)
    }

    /// Clean event text (remove card/goal words) - icon shows type
    static func cleanEventText(_ text: String) -> String {
        // Match card/goal variants with different capitalisation
        let pattern = #"(?:yellow\s*[\-]?\s*car(?:d)?|red\s*[\-]?\s*card|second\s*[\-]?\s*yellow|booking|caution|own\s*[\-]?\s*goal|penalty\s*[\-]?\s*(?:goal|missed)|goal!?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        let stripped = regex.stringByReplacingMatches(in: text, range: range, withTemplate: "")
        return stripped
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".,:-!")))
    }

    /// Parse "X replaces Y" and strip reason
    static func parseSubstitution(_ text: String) -> (off: String, on: String)? {
        // Stops the second capture at common reason connectors so we don't
        // grab "because of injury" / "due to ..." / "after ..." as a name.
        let pattern = #"([^.]+?)\s+replaces\s+(.+?)(?:\s+(?:because|due\s+to|after|with|following)\b.*?|\.|$)"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges == 3,
              let onRange = Range(match.range(at: 1), in: text),
              let offRange = Range(match.range(at: 2), in: text) else { return nil }

        let on  = trimReason(String(text[onRange]))
        let off = trimReason(String(text[offRange]))
        return (off: off, on: on)
    }

    /// Strip trailing reason ("because of injury", etc.)
    nonisolated static func trimReason(_ name: String) -> String {
        let pattern = #"\s+(?:because|due\s+to|after|with|following)\b.*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return name.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let range = NSRange(name.startIndex..., in: name)
        let cleaned = regex.stringByReplacingMatches(in: name, range: range, withTemplate: "")
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func keyEventKind(typeText: String?, scoringPlay: Bool?) -> KeyEvent.Kind? {
        let text = (typeText ?? "").lowercased()
        if text.contains("own") && text.contains("goal") { return .ownGoal }
        if text.contains("penalty") && text.contains("miss") { return .penaltyMissed }
        if text.contains("penalty") && text.contains("goal") { return .penaltyGoal }
        if text.contains("goal") || scoringPlay == true { return .goal }
        if text.contains("yellow") { return .yellowCard }
        if text.contains("red")    { return .redCard }
        if text.contains("substit") || text.contains("sub") { return .substitution }
        if text.isEmpty { return nil }
        return .other(typeText ?? "")
    }

    // MARK: - Box Score

    private static func buildBoxScore(dto: ESPNSummaryDTO, sport: Sport, homeID: String?, awayID: String?) -> BoxScoreSummary {
        let stats = buildStats(from: dto.boxscore?.teams ?? [], homeID: homeID, awayID: awayID, kind: sport.kind)

        var performers: [Performer] = []
        for group in dto.leaders ?? [] {
            guard let side = side(for: group.team?.id, homeID: homeID, awayID: awayID,
                                  fallback: group.homeAway) else { continue }
            for category in group.leaders ?? [] {
                guard let leader = category.leaders?.first else { continue }
                let name = leader.athlete?.shortName ?? leader.athlete?.displayName ?? "—"
                let detail = leader.displayValue ?? ""
                performers.append(Performer(
                    id: "\(category.displayName ?? "")-\(side == .home ? "h" : "a")-\(leader.athlete?.id ?? UUID().uuidString)",
                    category: category.displayName ?? "",
                    side: side,
                    playerName: name,
                    detail: detail
                ))
            }
        }
        return BoxScoreSummary(teamStats: stats, topPerformers: performers)
    }

    // MARK: - Helpers

    private static func buildStats(from blocks: [ESPNSummaryDTO.BoxscoreDTO.TeamStatBlock],
                                homeID: String?, awayID: String?,
                                kind: SportKind) -> [TeamStatPair] {
        let homeBlock = blocks.first { side(for: $0.team?.id, homeID: homeID, awayID: awayID, fallback: $0.homeAway) == .home }
        let awayBlock = blocks.first { side(for: $0.team?.id, homeID: homeID, awayID: awayID, fallback: $0.homeAway) == .away }

        // Index by lower-cased stat name
        let homeStats = indexStats(homeBlock?.statistics ?? [])
        let awayStats = indexStats(awayBlock?.statistics ?? [])

        // Build stat pairs, skip if missing on both sides
        var pairs: [TeamStatPair] = []
        for entry in kind.commonStats {
            guard let home = homeStats.find(entry.candidates) ?? awayStats.find(entry.candidates) else { continue }
            let homeValue = home.displayValue ?? "—"
            let awayValue = awayStats.find(entry.candidates)?.displayValue ?? "—"
            pairs.append(TeamStatPair(label: entry.label, home: homeValue, away: awayValue))
        }
        return pairs
    }

    private static func indexStats(_ stats: [ESPNSummaryDTO.BoxscoreDTO.TeamStatBlock.Statistic])
    -> [String: ESPNSummaryDTO.BoxscoreDTO.TeamStatBlock.Statistic] {
        var map: [String: ESPNSummaryDTO.BoxscoreDTO.TeamStatBlock.Statistic] = [:]
        for stat in stats {
            if let name = stat.name?.lowercased() { map[name] = stat }
            if let label = stat.label?.lowercased() { map[label] = stat }
        }
        return map
    }

    private static func side(for teamId: String?, homeID: String?, awayID: String?, fallback: String?) -> TeamSide? {
        if let teamId, let homeID, teamId == homeID { return .home }
        if let teamId, let awayID, teamId == awayID { return .away }
        switch fallback {
        case "home": return .home
        case "away": return .away
        default:     return nil
        }
    }
}
