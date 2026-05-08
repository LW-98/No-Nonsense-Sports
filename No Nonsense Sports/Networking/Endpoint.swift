//
//  Endpoint.swift
//  No Nonsense Sports
//

import Foundation

struct Endpoint: Sendable {
    var scheme: String = "https"
    var host: String
    var path: String
    var queryItems: [URLQueryItem] = []
    var method: String = "GET"
    var headers: [String: String] = [:]

    nonisolated func makeURL() -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = host
        components.path = path.hasPrefix("/") ? path : "/" + path
        if !queryItems.isEmpty { components.queryItems = queryItems }
        return components.url
    }
}
