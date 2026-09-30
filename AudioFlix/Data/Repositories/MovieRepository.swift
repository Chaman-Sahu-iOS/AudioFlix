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
    func searchMovies(query: String) async throws -> [Movie]
}

final class MovieRepository: MovieRepositoryProtocol {

    private let remoteDataSource: RemoteMovieDataSourceProtocol
    private let cache: MovieCache

    init(
        remoteDataSource: RemoteMovieDataSourceProtocol,
        cache: MovieCache
    ) {
        self.remoteDataSource = remoteDataSource
        self.cache = cache
    }

    func searchMovies(query: String) async throws -> [Movie] {

        // 1. Check cache
        if let cachedMovies = cache.movies(for: query) {
            return cachedMovies
        }

        // 2. Fetch from remote
        let movies = try await remoteDataSource.searchMovies(
            query: query
        )

        // 3. Save response in cache
        cache.save(
            movies: movies,
            for: query
        )

        // 4. Return data
        return movies
    }
}
