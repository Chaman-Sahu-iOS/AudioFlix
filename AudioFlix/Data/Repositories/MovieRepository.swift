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

protocol MovieRepositoryProtocol {

    func searchMovies(
        query: String,
        page: Int
    ) async throws -> MovieSearchResponse
}

final class MovieRepository: MovieRepositoryProtocol {

    private let remoteDataSource:
            RemoteMovieDataSourceProtocol

        // Optional: nil when the local SwiftData store failed to open.
        private let localDataSource:
            LocalMovieDataSourceProtocol?

        private let cache: MovieCache

        private let cacheMaxAge:
            TimeInterval = 60 * 10


    init(
        remoteDataSource:
            RemoteMovieDataSourceProtocol,

        localDataSource:
            LocalMovieDataSourceProtocol?,

        cache: MovieCache
    ) {

        self.remoteDataSource =
            remoteDataSource

        self.localDataSource =
            localDataSource

        self.cache = cache
    }

    func searchMovies(
        query: String,
        page: Int
    ) async throws -> MovieSearchResponse {

        // 1. Memory cache
        if let cached = await cache.get(
            query: query,
            page: page,
            maxAge: cacheMaxAge
        ) {
            return cached
        }

        // 2. Local persistence (skipped when the store is unavailable)
        let localMovies =
            try localDataSource?.movies(
                query: query,
                page: page
            ) ?? []

        if !localMovies.isEmpty {

            let response =
                MovieSearchResponse(
                    search: localMovies,
                    totalResults: nil,
                    response: "True"
                )

            return response
        }

        // 3. Network
        let response =
            try await remoteDataSource.searchMovies(
                query: query,
                page: page
            )

        // 4. Save locally
        try localDataSource?.save(
            movies: response.search ?? [],
            query: query,
            page: page
        )

        // 5. Save memory cache
        await cache.save(
            response: response,
            query: query,
            page: page
        )

        return response
    }
}
