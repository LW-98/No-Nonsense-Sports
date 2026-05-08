//
//  LiveScoresView.swift
//  No Nonsense Sports
//

import SwiftUI

struct LiveScoresView: View {
    @Bindable var viewModel: LiveScoresViewModel

    private var isOnToday: Bool {
        Calendar.current.isDateInToday(viewModel.selectedDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DateScroller(selection: $viewModel.selectedDate)
                content
            }
            .navigationTitle("Live Scores")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !isOnToday {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                viewModel.selectedDate = Calendar.current.startOfDay(for: .now)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                Text("Back to Today")
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.small)
                        .accessibilityLabel("Back to today")
                        .accessibilityHint("Returns the date selector to today's date")
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    SportPicker(selection: $viewModel.selectedSport)
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isOnToday)
            .refreshable { await viewModel.refresh() }
            .task { await viewModel.load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loading where viewModel.events.isEmpty:
            ProgressView("Loading scores…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .failed(let message) where viewModel.events.isEmpty:
            ContentUnavailableView {
                Label("Couldn't load scores", systemImage: "wifi.exclamationmark")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") { Task { await viewModel.load() } }
                    .buttonStyle(.borderedProminent)
            }
        default:
            if viewModel.events.isEmpty {
                ContentUnavailableView("No games scheduled",
                                       systemImage: "sportscourt",
                                       description: Text("Try a different date or pull down to refresh."))
            } else {
                List(viewModel.events) { event in
                    NavigationLink(value: event) {
                        EventRow(event: event)
                    }
                }
                .listStyle(.plain)
                .navigationDestination(for: ScoreboardEvent.self) { event in
                    MatchDetailView(viewModel: MatchDetailViewModel(
                        event: event,
                        sport: viewModel.selectedSport,
                        service: viewModel.service
                    ))
                }
            }
        }
    }
}

#Preview {
    let env = AppEnvironment.preview()
    LiveScoresView(viewModel: LiveScoresViewModel(service: env.scoresService))
}
