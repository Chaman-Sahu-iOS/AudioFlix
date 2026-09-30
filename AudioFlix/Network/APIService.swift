//
//  APIService.swift
//  AudioFlix
//
//  Copyright 2026 Chaman Lal Sahu
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

final class APIService {

    func searchMovies(
        query: String,
        page: Int
    ) async throws -> MovieSearchResponse {

        guard var components = URLComponents(
            string: APIConfig.baseURL
        ) else {
            throw APIError.invalidURL
        }

        components.queryItems = [
            URLQueryItem(
                name: "apikey",
                value: APIConfig.apiKey
            ),
            URLQueryItem(
                name: "s",
                value: query
            ),
            URLQueryItem(
                name: "page",
                value: String(page)
            )
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

            return result

        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.decodingFailed
        }
    }
}
