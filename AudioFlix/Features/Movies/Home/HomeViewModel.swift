//
//  HomeViewModel.swift
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
import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {

    @Published private(set) var movies: [Movie] = []
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    
    private var searchTask: Task<Void, Never>?

    private let repository: MovieRepositoryProtocol
    
    private var currentPage = 0
    private var totalResults = 0
    private var currentQuery = ""
    private var isLoadingNextPage = false

    init(
        repository: MovieRepositoryProtocol
    ) {
        self.repository = repository
    }

    func searchMovies(query: String) {

        searchTask?.cancel()

        currentQuery = query
        currentPage = 0
        movies = []

        searchTask = Task {

            do {
                try await Task.sleep(
                    for: .milliseconds(400)
                )

                guard !Task.isCancelled else {
                    return
                }

                isLoading = true

                let response = try await repository.searchMovies(
                    query: query,
                    page: 1
                )

                guard !Task.isCancelled else {
                    return
                }

                movies = response.search ?? []

                currentPage = 1
                totalResults = Int(
                    response.totalResults ?? "0"
                ) ?? 0

                isLoading = false

            } catch is CancellationError {
                // Expected.
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
    
    func loadNextPage() {

        guard !isLoadingNextPage else {
            return
        }

        let nextPage = currentPage + 1

        guard movies.count < totalResults else {
            return
        }

        isLoadingNextPage = true

        Task {

            do {

                let response = try await repository.searchMovies(
                    query: currentQuery,
                    page: nextPage
                )

                guard !Task.isCancelled else {
                    return
                }

                let newMovies = response.search ?? []

                movies.append(contentsOf: newMovies)

                currentPage = nextPage

                isLoadingNextPage = false

            } catch {

                isLoadingNextPage = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
