//
//  RemoteMoviewDataSource.swift
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

protocol RemoteMovieDataSourceProtocol {
    func searchMovies(
        query: String,
        page: Int
    ) async throws -> MovieSearchResponse
}

final class RemoteMovieDataSource:
    RemoteMovieDataSourceProtocol {

    private let apiService: APIService

    init(
        apiService: APIService = APIService()
    ) {
        self.apiService = apiService
    }

    func searchMovies(
        query: String,
        page: Int
    ) async throws -> MovieSearchResponse {

        try await apiService.searchMovies(
            query: query,
            page: page
        )
    }
}
