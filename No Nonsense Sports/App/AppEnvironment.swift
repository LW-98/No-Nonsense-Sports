//
//  AppEnvironment.swift
//  No Nonsense Sports
//

import Foundation

@MainActor
final class AppEnvironment {
    let scoresService: ScoresService

    init(scoresService: ScoresService) {
        self.scoresService = scoresService
    }

    /// Live network service
    static func live() -> AppEnvironment {
        let client = URLSessionAPIClient()
        let service = ESPNScoresService(client: client)
        return AppEnvironment(scoresService: service)
    }

    /// Mock service for previews
    static func preview() -> AppEnvironment {
        AppEnvironment(scoresService: MockScoresService())
    }
}
