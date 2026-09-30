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

    private let remoteDataSource: RemoteMovieDataSourceProtocol
    private let cache: MovieCache

    // 10 minutes
    private let cacheMaxAge: TimeInterval = 60 * 10

    init(
        remoteDataSource: RemoteMovieDataSourceProtocol,
        cache: MovieCache
    ) {
        self.remoteDataSource = remoteDataSource
        self.cache = cache
    }

    func searchMovies(
        query: String,
        page: Int
    ) async throws -> MovieSearchResponse {

        // 1. Check valid cache
        if let cachedResponse = await cache.get(
            query: query,
            page: page,
            maxAge: cacheMaxAge
        ) {
            return cachedResponse
        }

        // 2. Cache miss / expired
        let response = try await remoteDataSource.searchMovies(
            query: query,
            page: page
        )

        // 3. Update cache
        await cache.save(
            response: response,
            query: query,
            page: page
        )

        // 4. Return fresh response
        return response
    }
}
