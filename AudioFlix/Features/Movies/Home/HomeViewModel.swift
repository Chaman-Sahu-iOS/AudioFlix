//
//  HomeViewModel.swift
//  MyApp
//
//  Created by Chaman Lal Sahu on 30/09/26.
//

import Foundation
import SwiftUI
import Combine

protocol MovieRepositoryProtocol {
    func searchMovies(query: String) async throws -> [Movie]
}

final class MovieRepository: MovieRepositoryProtocol {

    private let remoteDataSource: RemoteMovieDataSourceProtocol
    private let cache: MovieCache

    private let cacheMaxAge: TimeInterval = 60 * 10

    init(
        remoteDataSource: RemoteMovieDataSourceProtocol,
        cache: MovieCache
    ) {
        self.remoteDataSource = remoteDataSource
        self.cache = cache
    }

    func searchMovies(query: String) async throws -> [Movie] {

        if let cachedMovies = cache.movies(
            for: query,
            maxAge: cacheMaxAge
        ) {
            return cachedMovies
        }

        let movies = try await remoteDataSource.searchMovies(
            query: query
        )

        cache.save(
            movies: movies,
            for: query
        )

        return movies
    }
}
