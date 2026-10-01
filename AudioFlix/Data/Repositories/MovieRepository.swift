//
//  MovieRepository.swift
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

enum MovieDataSource {
    case memory
    case local
    case remote
}

struct MovieRepositoryResult {
    let response: MovieSearchResponse
    let source: MovieDataSource
    let isStale: Bool
}

protocol MovieRepositoryProtocol {
    func searchMovies(
        query: String,
        page: Int
    ) async throws -> MovieRepositoryResult

    func refreshMovies(
        query: String,
        page: Int
    ) async throws -> MovieRepositoryResult
}

@MainActor
final class MovieRepository: MovieRepositoryProtocol {

    private let remoteDataSource: RemoteMovieDataSourceProtocol
    private let localDataSource: LocalMovieDataSourceProtocol
    private let cache: MovieCache

    private let cacheMaxAge: TimeInterval = 60 * 10
    private let localMaxAge: TimeInterval = 60 * 60

    init(
        remoteDataSource: RemoteMovieDataSourceProtocol,
        localDataSource: LocalMovieDataSourceProtocol,
        cache: MovieCache
    ) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
        self.cache = cache
    }

    // MARK: - Normal Read

    func searchMovies(
        query: String,
        page: Int
    ) async throws -> MovieRepositoryResult {

        let normalizedQuery = normalize(query)

        // 1. Memory cache
        if let response = await cache.get(
            query: normalizedQuery,
            page: page,
            maxAge: cacheMaxAge
        ) {
            return MovieRepositoryResult(
                response: response,
                source: .memory,
                isStale: false
            )
        }

        // 2. Local persistence
        if let response = try localDataSource.fetch(
            query: normalizedQuery,
            page: page
        ) {
            let savedAt = try localDataSource.savedAt(
                query: normalizedQuery,
                page: page
            )

            let isStale: Bool

            if let savedAt {
                isStale =
                    Date().timeIntervalSince(savedAt) > localMaxAge
            } else {
                isStale = true
            }

            // Promote local data into memory cache.
            await cache.save(
                response: response,
                query: normalizedQuery,
                page: page
            )

            return MovieRepositoryResult(
                response: response,
                source: .local,
                isStale: isStale
            )
        }

        // 3. Remote API
        return try await refreshMovies(
            query: normalizedQuery,
            page: page
        )
    }

    // MARK: - Remote Refresh

    func refreshMovies(
        query: String,
        page: Int
    ) async throws -> MovieRepositoryResult {

        let normalizedQuery = normalize(query)

        let response = try await remoteDataSource.searchMovies(
            query: normalizedQuery,
            page: page
        )

        // Save to local persistence.
        try localDataSource.save(
            response: response,
            query: normalizedQuery,
            page: page
        )

        // Save to memory cache.
        await cache.save(
            response: response,
            query: normalizedQuery,
            page: page
        )

        return MovieRepositoryResult(
            response: response,
            source: .remote,
            isStale: false
        )
    }

    private func normalize(_ query: String) -> String {
        query
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
