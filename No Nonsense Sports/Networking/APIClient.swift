//
//  APIClient.swift
//  No Nonsense Sports
//

import Foundation

protocol APIClient: Sendable {
    nonisolated func send<T: Decodable & Sendable>(_ endpoint: Endpoint, as type: T.Type, decoder: JSONDecoder) async throws -> T
}

extension APIClient {
    nonisolated func send<T: Decodable & Sendable>(_ endpoint: Endpoint, as type: T.Type) async throws -> T {
        try await send(endpoint, as: type, decoder: JSONDecoder())
    }
}

final class URLSessionAPIClient: APIClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    nonisolated func send<T: Decodable & Sendable>(_ endpoint: Endpoint, as type: T.Type, decoder: JSONDecoder) async throws -> T {
        guard let url = endpoint.makeURL() else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw APIError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else { throw APIError.http(status: http.statusCode) }

        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw APIError.decoding(Self.describe(error))
        } catch {
            throw APIError.decoding(error.localizedDescription)
        }
    }

    /// Produces a human-readable description of a `DecodingError` that
    /// includes the JSON path of the offending field, which makes
    /// vendor-API schema drift much easier to diagnose than the default
    /// "data couldn't be read because it isn't in the correct format".
    nonisolated private static func describe(_ error: DecodingError) -> String {
        func path(_ ctx: DecodingError.Context) -> String {
            ctx.codingPath.map(\.stringValue).joined(separator: ".").nilIfEmpty ?? "<root>"
        }
        switch error {
        case .typeMismatch(let type, let ctx):
            return "Type mismatch at \(path(ctx)): expected \(type) — \(ctx.debugDescription)"
        case .valueNotFound(let type, let ctx):
            return "Missing value at \(path(ctx)): expected \(type) — \(ctx.debugDescription)"
        case .keyNotFound(let key, let ctx):
            return "Missing key '\(key.stringValue)' at \(path(ctx))"
        case .dataCorrupted(let ctx):
            return "Corrupted data at \(path(ctx)): \(ctx.debugDescription)"
        @unknown default:
            return error.localizedDescription
        }
    }
}

extension String {
    nonisolated var nilIfEmpty: String? { isEmpty ? nil : self }
}
