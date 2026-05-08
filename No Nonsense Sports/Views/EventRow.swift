//
//  EventRow.swift
//  No Nonsense Sports
//

import SwiftUI

struct EventRow: View {
    let event: ScoreboardEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                statusBadge
                Spacer()
                Text(event.startDate, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            teamLine(event.home)
            teamLine(event.away)
            if let venue = event.venue {
                Text(venue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func teamLine(_ team: Competitor) -> some View {
        HStack {
            Text(team.shortName)
                .font(.headline)
                .frame(width: 56, alignment: .leading)
            Text(team.name)
                .font(.subheadline)
            Spacer()
            Text(team.score.map(String.init) ?? "—")
                .font(.title3.monospacedDigit())
                .fontWeight(.semibold)
        }
    }

    private var statusBadge: some View {
        Text(event.status.label.uppercased())
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.15), in: Capsule())
            .foregroundStyle(badgeColor)
    }

    private var badgeColor: Color {
        switch event.status {
        case .inProgress: return .red
        case .final:      return .secondary
        case .scheduled:  return .blue
        case .postponed:  return .orange
        case .unknown:    return .gray
        }
    }
}

#Preview {
    List(MockScoresService.sampleEvents) { EventRow(event: $0) }
}
