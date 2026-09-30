//
//  APIService.swift
//  MyApp
//
//  Created by Chaman Lal Sahu on 30/09/26.
//

import Foundation

final class APIService {

    func searchMovies(query: String) async throws -> [Movie] {

        guard var components = URLComponents(
            string: APIConfig.baseURL
        ) else {
            throw APIError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(name: "apikey", value: APIConfig.apiKey),
            URLQueryItem(name: "s", value: query)
        ]

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(
            from: url
        )

        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw APIError.invalidResponse
        }

        do {
            let result = try JSONDecoder().decode(
                MovieSearchResponse.self,
                from: data
            )

            if result.response == "False" {
                throw APIError.apiError(
                    "No movies found"
                )
            }

            return result.search ?? []

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingFailed
        }
    }
}
