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
    @Published private(set) var isRefreshing = false
    @Published private(set) var isOfflineData = false

    @Published var errorMessage: String?

    private let repository: MovieRepositoryProtocol

    private var searchTask: Task<Void, Never>?
    private var refreshTasks: [Int: Task<Void, Never>] = [:]

    private var currentQuery = ""
    private var currentPage = 0
    private var totalResults = 0

    init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    deinit {
        searchTask?.cancel()

        for task in refreshTasks.values {
            task.cancel()
        }
    }

    // MARK: - Search

    func searchMovies(query: String) {

        searchTask?.cancel()

        let trimmedQuery =
            query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedQuery.isEmpty else {
            reset()
            return
        }

        currentQuery = trimmedQuery
        currentPage = 0
        totalResults = 0
        movies = []
        errorMessage = nil
        isOfflineData = false

        searchTask = Task { [weak self] in

            do {
                try await Task.sleep(
                    for: .milliseconds(400)
                )

                try Task.checkCancellation()

                guard let self else { return }

                await self.loadFirstPage(
                    query: trimmedQuery
                )

            } catch is CancellationError {

                // Expected when user keeps typing.

            } catch {

                guard let self else { return }

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

            let result =
                try await repository.searchMovies(
                    query: query,
                    page: 1
                )

            try Task.checkCancellation()

            guard query == currentQuery else {
                return
            }

            apply(
                response: result.response,
                page: 1,
                append: false
            )

            isOfflineData =
                result.source == .local

            // Stale-While-Revalidate
            if result.isStale {
                startRefresh(
                    query: query,
                    page: 1
                )
            }

        } catch is CancellationError {

            return

        } catch {

            errorMessage =
                error.localizedDescription
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

        guard movies.count < totalResults else {
            return
        }

        guard let index =
                movies.firstIndex(
                    where: { $0.id == movie.id }
                )
        else {
            return
        }

        // Start loading when 5 items remain.
        let threshold = max(
            movies.count - 5,
            0
        )

        guard index >= threshold else {
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

                let result =
                    try await repository.searchMovies(
                        query: currentQuery,
                        page: nextPage
                    )

                try Task.checkCancellation()

                guard nextPage ==
                        currentPage + 1
                else {
                    return
                }

                apply(
                    response: result.response,
                    page: nextPage,
                    append: true
                )

                if result.source == .local {
                    isOfflineData = true
                }

                if result.isStale {
                    startRefresh(
                        query: currentQuery,
                        page: nextPage
                    )
                }

            } catch is CancellationError {

                return

            } catch {

                errorMessage =
                    error.localizedDescription
            }
        }
    }

    // MARK: - Refresh

    private func startRefresh(
        query: String,
        page: Int
    ) {

        refreshTasks[page]?.cancel()

        refreshTasks[page] = Task { [weak self] in

            guard let self else {
                return
            }

            do {

                if page == 1 {
                    isRefreshing = true
                }

                let result =
                    try await repository.refreshMovies(
                        query: query,
                        page: page
                    )

                try Task.checkCancellation()

                guard query == currentQuery else {
                    return
                }

                if page == 1 {

                    apply(
                        response: result.response,
                        page: page,
                        append: false
                    )

                    isOfflineData = false

                } else {

                    replacePage(
                        response: result.response,
                        page: page
                    )
                }

            } catch is CancellationError {

                return

            } catch {

                // Stale/local data is still usable.
                // Don't replace the UI with an error
                // just because background refresh failed.

            }

            if page == 1 {
                isRefreshing = false
            }

            refreshTasks[page] = nil
        }
    }

    // MARK: - Apply Response

    private func apply(
        response: MovieSearchResponse,
        page: Int,
        append: Bool
    ) {

        let newMovies =
            response.search ?? []

        if append {
            movies.append(contentsOf: newMovies)
        } else {
            movies = newMovies
        }

        currentPage = page

        totalResults =
            Int(response.totalResults ?? "0")
            ?? totalResults
    }

    // MARK: - Replace Refreshed Page

    private func replacePage(
        response: MovieSearchResponse,
        page: Int
    ) {

        guard page > 0 else {
            return
        }

        let newMovies =
            response.search ?? []

        let startIndex =
            (page - 1) * 10

        guard startIndex < movies.count else {
            return
        }

        let endIndex =
            min(
                startIndex + 10,
                movies.count
            )

        movies.replaceSubrange(
            startIndex..<endIndex,
            with: newMovies
        )

        totalResults =
            Int(response.totalResults ?? "0")
            ?? totalResults
    }

    // MARK: - Images

    func prefetchImages(
        after movie: Movie,
        count: Int = 5
    ) {

        guard let index =
                movies.firstIndex(
                    where: { $0.id == movie.id }
                )
        else {
            return
        }

        let startIndex = index + 1

        guard startIndex < movies.count else {
            return
        }

        let endIndex =
            min(
                startIndex + count,
                movies.count
            )

        let urls =
            movies[startIndex..<endIndex]
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

    // MARK: - Reset

    private func reset() {

        currentQuery = ""
        currentPage = 0
        totalResults = 0

        movies = []

        errorMessage = nil
        isOfflineData = false
        isRefreshing = false

        for task in refreshTasks.values {
            task.cancel()
        }

        refreshTasks.removeAll()
    }
}
