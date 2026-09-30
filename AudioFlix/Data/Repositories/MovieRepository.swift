//
//  MovieRepository.swift
//  MyApp
//
//  Created by Chaman Lal Sahu on 30/09/26.
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
