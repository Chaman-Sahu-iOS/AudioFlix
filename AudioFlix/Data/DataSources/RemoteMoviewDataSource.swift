//
//  RemoteMoviewDataSource.swift
//  MyApp
//
//  Created by Chaman Lal Sahu on 30/09/26.
//

import Foundation

protocol RemoteMovieDataSourceProtocol {
    func searchMovies(query: String) async throws -> [Movie]
}

final class RemoteMovieDataSource: RemoteMovieDataSourceProtocol {

    private let apiService: APIService

    init(apiService: APIService = APIService()) {
        self.apiService = apiService
    }

    func searchMovies(query: String) async throws -> [Movie] {
        try await apiService.searchMovies(query: query)
    }
}
