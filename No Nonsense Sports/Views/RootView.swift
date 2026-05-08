//
//  RootView.swift
//  No Nonsense Sports
//

import SwiftUI

struct RootView: View {
    @State private var environment = AppEnvironment.live()

    var body: some View {
        LiveScoresView(viewModel: LiveScoresViewModel(service: environment.scoresService))
    }
}

#Preview {
    let env = AppEnvironment.preview()
    LiveScoresView(viewModel: LiveScoresViewModel(service: env.scoresService))
}
