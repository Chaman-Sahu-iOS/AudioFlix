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


import SwiftUI
import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {

    @Published private(set) var movies: [Movie] = []
    @Published private(set) var isLoading = false
    @Published private(set) var isLoadingNextPage = false

    @Published var errorMessage: String?

    private let repository: MovieRepositoryProtocol

    private var searchTask: Task<Void, Never>?

    private var currentQuery = ""
    private var currentPage = 0
    private var totalResults = 0

    init(
        repository: MovieRepositoryProtocol
    ) {
        self.repository = repository
    }

    // MARK: - Search

    func searchMovies(query: String) {

        searchTask?.cancel()

        let trimmedQuery = query
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !trimmedQuery.isEmpty else {

            movies = []
            currentQuery = ""
            currentPage = 0
            totalResults = 0

            return
        }

        currentQuery = trimmedQuery
        currentPage = 0
        totalResults = 0
        movies = []
        errorMessage = nil

        searchTask = Task { [weak self] in

            do {

                // Debounce
                try await Task.sleep(
                    for: .milliseconds(400)
                )

                try Task.checkCancellation()

                guard let self else {
                    return
                }

                await self.loadFirstPage(
                    query: trimmedQuery
                )

            } catch is CancellationError {

                // Expected when user keeps typing.

            } catch {

                guard let self else {
                    return
                }

                self.errorMessage =
                    error.localizedDescription
            }
        }
    }

    // MARK: - First Page

    private func loadFirstPage(
        query: String
    ) async {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {

            let response = try await repository.searchMovies(
                query: query,
                page: 1
            )

            try Task.checkCancellation()

            guard query == currentQuery else {
                return
            }

            movies = response.search ?? []

            currentPage = 1

            totalResults = Int(
                response.totalResults ?? "0"
            ) ?? 0

        } catch is CancellationError {

            return

        } catch {

            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Pagination

    func loadNextPageIfNeeded(
        currentMovie movie: Movie
    ) {

        guard !isLoading else {
            return
        }

        guard !isLoadingNextPage else {
            return
        }

        guard !currentQuery.isEmpty else {
            return
        }

        guard currentPage > 0 else {
            return
        }

        guard movies.last?.id == movie.id else {
            return
        }

        guard movies.count < totalResults else {
            return
        }

        let nextPage = currentPage + 1

        isLoadingNextPage = true

        Task { [weak self] in

            guard let self else {
                return
            }

            defer {
                self.isLoadingNextPage = false
            }

            do {

                let response = try await repository.searchMovies(
                    query: currentQuery,
                    page: nextPage
                )

                try Task.checkCancellation()

                guard nextPage == currentPage + 1 else {
                    return
                }

                movies.append(
                    contentsOf: response.search ?? []
                )

                currentPage = nextPage

                totalResults = Int(
                    response.totalResults ?? "0"
                ) ?? totalResults

            } catch is CancellationError {

                return

            } catch {

                errorMessage =
                    error.localizedDescription
            }
        }
    }

    deinit {
        searchTask?.cancel()
    }
    
    
    func prefetchImages(
        after movie: Movie,
        count: Int = 5
    ) {

        guard let index = movies.firstIndex(
            where: { $0.id == movie.id }
        ) else {
            return
        }

        let startIndex = index + 1

        guard startIndex < movies.count else {
            return
        }

        let endIndex = min(
            startIndex + count,
            movies.count
        )

        let urls = movies[
            startIndex..<endIndex
        ]
        .compactMap {
            URL(string: $0.poster)
        }

        guard !urls.isEmpty else {
            return
        }

        Task {

            await ImageLoader.shared.prefetch(
                urls: urls,
                size: CGSize(
                    width: 70,
                    height: 100
                ),
                scale: 2
            )
        }
    }
}
