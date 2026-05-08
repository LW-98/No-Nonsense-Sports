//
//  MatchDetailView.swift
//  No Nonsense Sports
//

import SwiftUI

struct MatchDetailView: View {
    @Bindable var viewModel: MatchDetailViewModel

    private var footballSummary: FootballSummary? {
        if case .football(let summary) = viewModel.detail?.body {
            return summary
        }
        return nil
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                MatchHeaderCard(event: viewModel.event, sport: viewModel.sport, summary: footballSummary)
                content
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    private var navigationTitle: String {
        "\(viewModel.event.home.shortName) vs \(viewModel.event.away.shortName)"
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .padding(.top, 40)
        case .failed(let message):
            VStack(spacing: 8) {
                Image(systemName: "wifi.exclamationmark")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Couldn't load match details")
                    .font(.headline)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Retry") { Task { await viewModel.load() } }
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 4)
            }
            .padding()
        case .loaded:
            if let body = viewModel.detail?.body {
                bodyView(body)
            }
        }
    }

    @ViewBuilder
    private func bodyView(_ body: MatchDetail.Body) -> some View {
        switch body {
        case .football(let summary):
            FootballSummarySection(event: viewModel.event, summary: summary, sport: viewModel.sport)
        case .boxScore(let summary):
            BoxScoreSection(event: viewModel.event, summary: summary, sport: viewModel.sport)
        case .unsupported:
            ContentUnavailableView("No detail available",
                                   systemImage: "doc.questionmark",
                                   description: Text("ESPN doesn't expose detail for this match yet."))
                .frame(minHeight: 240)
        }
    }
}

// MARK: - Header

private struct MatchHeaderCard: View {
    let event: ScoreboardEvent
    let sport: Sport
    let summary: FootballSummary?

    var body: some View {
        VStack(spacing: 14) {
            Text(statusText)
                .font(.caption.weight(.bold))
                .foregroundStyle(statusColour)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(statusColour.opacity(0.15), in: Capsule())

            HStack(alignment: .center, spacing: 12) {
                let homeScorers = summary?.keyEvents.filter { $0.side == .home && ($0.kind == .goal || $0.kind == .penaltyGoal || $0.kind == .ownGoal) }.map { $0.text } ?? []
                let awayScorers = summary?.keyEvents.filter { $0.side == .away && ($0.kind == .goal || $0.kind == .penaltyGoal || $0.kind == .ownGoal) }.map { $0.text } ?? []
                teamColumn(name: event.home.name, short: event.home.shortName, record: event.home.record, scorers: homeScorers)
                Spacer(minLength: 8)
                scoreBlock
                Spacer(minLength: 8)
                teamColumn(name: event.away.name, short: event.away.shortName, record: event.away.record, scorers: awayScorers)
            }

            if let venue = event.venue {
                Label(venue, systemImage: "mappin.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func teamColumn(name: String, short: String, record: String?, scorers: [String] = []) -> some View {
        VStack(spacing: 4) {
            Text(short)
                .font(.title2.weight(.heavy))
            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            if let record {
                Text(record)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            if !scorers.isEmpty {
                HStack(spacing: 2) {
                    Image(systemName: "soccerball")
                        .font(.caption2)
                    Text(scorers.joined(separator: ", "))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.primary)
                }
                .multilineTextAlignment(.center)
                .lineLimit(3)
            }
        }
        .frame(maxWidth: 80)
    }

    private var scoreBlock: some View {
        HStack(spacing: 6) {
            Text(event.home.score.map(String.init) ?? "—")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
            Text("–")
                .foregroundStyle(.tertiary)
            Text(event.away.score.map(String.init) ?? "—")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
        }
    }

    private var statusText: String { event.status.label.uppercased() }
    private var statusColour: Color {
        switch event.status {
        case .inProgress: return .red
        case .final:      return .secondary
        case .scheduled:  return .blue
        case .postponed:  return .orange
        case .unknown:    return .gray
        }
    }
}

// MARK: - Card / Section helpers

private struct CardSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

private struct StatBar: View {
    let pair: TeamStatPair
    let homeColor: Color
    let awayColor: Color
    let sport: Sport

    private static let barHeight: CGFloat = 6

    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(pair.home)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                Spacer()
                Text(pair.label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(pair.away)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
            }

            // Two-segment bar: away grows from the left, home from the right.
            // Widths are proportional to each side's numeric value.
            GeometryReader { geo in
                let total = geo.size.width
                HStack(spacing: 2) {
                    Capsule()
                        .fill(homeColor)
                        .frame(width: max(2, total * homeFraction - 1))
                    Capsule()
                        .fill(awayColor)
                        .frame(width: max(2, total * awayFraction - 1))
                }
                .frame(height: StatBar.barHeight)
            }
            .frame(height: StatBar.barHeight)
        }
    }

    private var homeFraction: Double {
        let value = toNumber(pair.home)
        let total = toNumber(pair.home) + toNumber(pair.away)
        guard total > 0 else { return 0.5 }
        return value / total
    }

    private var awayFraction: Double { 1 - homeFraction }

    /// Extracts the leading numeric portion of a stat value, ignoring `%`,
    /// `:`, parentheses etc. Returns 0 if no numeric content is present.
    private func toNumber(_ s: String) -> Double {
        var digits = ""
        for ch in s {
            if ch.isNumber || ch == "." { digits.append(ch) }
            else if !digits.isEmpty { break } // stop at first non-numeric after digits start
        }
        return Double(digits) ?? 0
    }
}

// MARK: - Football

private struct FootballSummarySection: View {
    let event: ScoreboardEvent
    let summary: FootballSummary
    let sport: Sport
    @State private var expandedEventId: String?

    func teamColor(_ side: TeamSide) -> Color {
        let hex = side == .home ? event.home.primaryColor : event.away.primaryColor
        let secondaryHex = side == .home ? event.home.secondaryColor : event.away.secondaryColor

        // If colours clash and this is the away team, use secondary colour
        if side == .away && colorsClash(event.home.primaryColor, event.away.primaryColor) {
            return Color(hex: secondaryHex) ?? Color(hex: hex) ?? .orange
        }

        return Color(hex: hex) ?? (side == .home ? .blue : .orange)
    }

    var body: some View {
        VStack(spacing: 16) {
            if !summary.keyEvents.isEmpty {
                CardSection(title: "Key Events") {
                    HStack(spacing: 12) {
                        ColorLegendDot(color: teamColor(.home), label: event.home.shortName)
                        ColorLegendDot(color: teamColor(.away), label: event.away.shortName)
                        Spacer()
                    }
                    .padding(.bottom, 4)
                    VStack(spacing: 6) {
                        ForEach(summary.keyEvents) { keyEvent in
                            KeyEventRow(
                                event: keyEvent,
                                color: teamColor(keyEvent.side),
                                isExpanded: expandedEventId == keyEvent.id,
                                onTap: {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        expandedEventId = expandedEventId == keyEvent.id ? nil : keyEvent.id
                                    }
                                }
                            )
                        }
                    }
                }
            }

            if !summary.teamStats.isEmpty {
                CardSection(title: "Team Stats") {
                    VStack(spacing: 14) {
                        ForEach(summary.teamStats) { pair in
                            StatBar(pair: pair, homeColor: teamColor(.home), awayColor: teamColor(.away), sport: sport)
                        }
                    }
                }
            }

            if summary.homeLineup != nil || summary.awayLineup != nil {
                CardSection(title: "Lineups") {
                    HStack(alignment: .top, spacing: 12) {
                        LineupColumn(title: event.home.shortName, lineup: summary.homeLineup)
                        Divider()
                        LineupColumn(title: event.away.shortName, lineup: summary.awayLineup)
                    }
                }
            }
        }
    }
}

private struct KeyEventRow: View {
    let event: KeyEvent
    let color: Color
    let isExpanded: Bool
    let onTap: () -> Void

    private var canExpand: Bool { event.longText != nil }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Team colour stripe doubles as the team identifier so we can
            // drop the explicit team-name text from each row.
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            Text(event.minute)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
                .padding(.top, 2)

            iconView
                .frame(width: 18, height: 18)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.text)
                    .font(.subheadline)
                    .lineLimit(isExpanded ? nil : 1)
                    .fixedSize(horizontal: false, vertical: isExpanded)

                if isExpanded, let long = event.longText {
                    Text(long)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: 0)

            if let score = event.scoreAfter {
                Text("\(score.away)–\(score.home)")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15), in: Capsule())
                    .foregroundStyle(.green)
                    .padding(.top, 2)
            }
        }
        .frame(minHeight: 28)
        .contentShape(Rectangle())
        .onTapGesture {
            guard canExpand else { return }
            onTap()
        }
        .accessibilityAddTraits(canExpand ? .isButton : [])
        .accessibilityHint(canExpand ? Text(isExpanded ? "Collapse" : "Tap to see full description") : Text(""))
    }

    /// Cards render as the rectangle icon itself (a "card"); other events
    /// use a coloured circular chip with a white symbol inside.
    @ViewBuilder
    private var iconView: some View {
        switch event.kind {
        case .yellowCard:
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(.yellow)
                .frame(width: 10, height: 14)
        case .redCard:
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(.red)
                .frame(width: 10, height: 14)
        default:
            Image(systemName: event.kind.symbolName)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(chipColor, in: Circle())
        }
    }

    private var chipColor: Color {
        switch event.kind {
        case .goal, .penaltyGoal: return .green
        case .ownGoal:            return .red
        case .penaltyMissed:      return .gray
        case .substitution:       return .blue
        case .other:              return .secondary
        case .yellowCard, .redCard: return .clear // unused
        }
    }
}

private struct ColorLegendDot: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

private struct LineupColumn: View {
    let title: String
    let lineup: TeamLineup?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                if let formation = lineup?.formation {
                    Text(formation)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(Color.accentColor)
                }
            }
            if let lineup {
                if !lineup.starters.isEmpty {
                    sectionHeader("Starting XI")
                    ForEach(sortedPlayers(lineup.starters)) { player in playerRow(player) }
                }
                if !lineup.substitutes.isEmpty {
                    sectionHeader("Subs")
                    ForEach(sortedPlayers(Array(lineup.substitutes.prefix(5)))) { player in playerRow(player) }
                }
            } else {
                Text("Not available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            .padding(.top, 4)
    }

    private func playerRow(_ player: LineupPlayer) -> some View {
        let mappedPos = player.position.map { europeanPosition($0) }
        return HStack(spacing: 6) {
            if let jersey = player.jersey {
                Text(jersey)
                    .font(.caption.monospacedDigit())
                    .frame(width: 20, alignment: .trailing)
                    .foregroundStyle(.secondary)
            }
            Text(player.name)
                .font(.caption)
                .lineLimit(1)
            Spacer()
            if let pos = mappedPos {
                Text(pos)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
    }

    /// Maps ESPN's American-style position abbreviations to European conventions.
    /// Examples: CD-L → CB, S → ST, DM → CDM, AM → CAM, etc.
    private func europeanPosition(_ pos: String) -> String {
        let normalized = pos.uppercased()
        let mapping: [String: String] = [
            // Goalkeeper
            "G": "GK",
            "GK": "GK",

            // Defenders
            "LWB": "LWB", "LB": "LB", "FB-L": "LB",
            "CD-L": "CB", "CD-R": "CB", "CD-C": "CB", "CD": "CB", "CB": "CB",
            "RWB": "RWB", "RB": "RB", "FB-R": "RB",
            "DF": "DF",

            // Midfielders
            "DM": "CDM", "DM-C": "CDM", "DM-L": "DM", "DM-R": "DM",
            "LM": "LM",
            "CM": "CM", "CM-C": "CM", "CM-L": "LCM", "CM-R": "RCM",
            "RM": "RM",
            "AM-L": "LW",
            "AM": "CAM", "AM-C": "CAM",
            "CAM": "CAM",
            "AM-R": "RW",
            "MF": "MF",

            // Forwards
            "CF": "CF",
            "LW": "LW", "LF": "LW", "WF-L": "LW",
            "FW": "FW", "S": "ST", "ST": "ST", "F": "ST", "CF-R": "ST", "CF-L": "ST",
            "RW": "RW", "RF": "RW", "WF-R": "RW",
        ]
        return mapping[normalized] ?? normalized
    }

    /// Returns the sort priority for a position based on the mapping order.
    /// Lower values appear first in the lineup. Uses the mapped European position.
    private func positionPriority(_ pos: String?) -> Int {
        guard let pos = pos else { return Int.max }
        let mapped = europeanPosition(pos).uppercased()
        let order: [String] = [
            "GK",
            "RWB", "RB",
            "CB",
            "LWB", "LB",
            "CDM", "DM",
            "RM",
            "CM", "LCM", "RCM",
            "LM",
            "CAM",
            "RW",
            "CF", "ST",
            "LW", 
        ]
        return order.firstIndex(of: mapped) ?? Int.max
    }

    /// Sorts players by their position priority (mapping order), then by jersey number.
    private func sortedPlayers(_ players: [LineupPlayer]) -> [LineupPlayer] {
        players.sorted { p1, p2 in
            let priority1 = positionPriority(p1.position)
            let priority2 = positionPriority(p2.position)
            if priority1 != priority2 {
                return priority1 < priority2
            }
            // Secondary sort by jersey number
            let jersey1 = Int(p1.jersey ?? "") ?? Int.max
            let jersey2 = Int(p2.jersey ?? "") ?? Int.max
            return jersey1 < jersey2
        }
    }
}

// MARK: - Box Score

private struct BoxScoreSection: View {
    let event: ScoreboardEvent
    let summary: BoxScoreSummary
    let sport: Sport

    private func teamColor(_ side: TeamSide) -> Color {
        let hex = side == .home ? event.home.primaryColor : event.away.primaryColor
        let secondaryHex = side == .home ? event.home.secondaryColor : event.away.secondaryColor

        // If colours clash and this is the away team, use secondary colour
        if side == .away && colorsClash(event.home.primaryColor, event.away.primaryColor) {
            return Color(hex: secondaryHex) ?? Color(hex: hex) ?? .orange
        }

        return Color(hex: hex) ?? (side == .home ? .blue : .orange)
    }

    var body: some View {
        VStack(spacing: 16) {
            if !summary.teamStats.isEmpty {
                CardSection(title: "Team Stats") {
                    HStack {
                        Text(event.home.shortName).font(.caption.weight(.bold))
                        Spacer()
                        Text(event.away.shortName).font(.caption.weight(.bold))
                    }
                    .foregroundStyle(.secondary)
                    VStack(spacing: 14) {
                        ForEach(summary.teamStats) { pair in
                            StatBar(pair: pair, homeColor: teamColor(.home), awayColor: teamColor(.away), sport: sport)
                        }
                    }
                }
            }
            if !summary.topPerformers.isEmpty {
                CardSection(title: "Top Performers") {
                    let grouped = Dictionary(grouping: summary.topPerformers, by: \.side)
                    HStack(alignment: .top, spacing: 12) {
                        PerformersColumn(title: event.home.shortName, performers: grouped[.home] ?? [])
                        Divider()
                        PerformersColumn(title: event.away.shortName, performers: grouped[.away] ?? [])
                    }
                }
            }
        }
    }
}

private struct PerformersColumn: View {
    let title: String
    let performers: [Performer]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            if performers.isEmpty {
                Text("Not available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(performers) { p in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(p.category.uppercased())
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(p.playerName)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text(p.detail)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Previews

#Preview("Football") {
    let env = AppEnvironment.preview()
    let event = MockScoresService.sampleEvents[0]
    let sport = Sport.all.first { $0.kind == .football }!
    return NavigationStack {
        MatchDetailView(viewModel: MatchDetailViewModel(event: event, sport: sport, service: env.scoresService))
    }
}

#Preview("Box Score") {
    let env = AppEnvironment.preview()
    let event = MockScoresService.sampleEvents[0]
    let sport = Sport.all.first { $0.kind == .basketball }!
    return NavigationStack {
        MatchDetailView(viewModel: MatchDetailViewModel(event: event, sport: sport, service: env.scoresService))
    }
}
