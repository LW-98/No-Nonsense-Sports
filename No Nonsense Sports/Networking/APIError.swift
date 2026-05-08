//
//  APIError.swift
//  No Nonsense Sports
//

import Foundation

enum APIError: LocalizedError, Equatable {
    case invalidURL
    case transport(String)
    case invalidResponse
    case http(status: Int)
    case decoding(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "The request URL was invalid."
        case .transport(let m):     return "Network error: \(m)"
        case .invalidResponse:      return "The server returned an invalid response."
        case .http(let status):     return "Server returned HTTP \(status)."
        case .decoding(let m):      return "Failed to decode response: \(m)"
        }
    }
}
