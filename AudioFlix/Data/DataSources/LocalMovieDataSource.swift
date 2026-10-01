//
//  LocalMovieDataSource.swift
//  AudioFlix
//
//  Created by Chaman Lal Sahu on 01/10/26.
//

import Foundation
import SwiftData

protocol LocalMovieDataSourceProtocol {
    func save(
        response: MovieSearchResponse,
        query: String,
        page: Int
    ) throws

    func fetch(
        query: String,
        page: Int
    ) throws -> MovieSearchResponse?

    func savedAt(
        query: String,
        page: Int
    ) throws -> Date?

    func clear() throws
}

@MainActor
final class LocalMovieDataSource: LocalMovieDataSourceProtocol {

    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    init() throws {

        let schema = Schema([
            MovieEntity.self,
            MovieSearchPageEntity.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: configuration
            )
        } catch {
            // The on-disk store was written with an older, incompatible
            // schema (e.g. a new required attribute was added) and cannot
            // be migrated in place. This store is only a cache of remote
            // data, so discard it and start with a fresh store rather
            // than failing to launch.
            Self.removeStoreFiles(at: configuration.url)

            modelContainer = try ModelContainer(
                for: schema,
                configurations: configuration
            )
        }

        modelContext = ModelContext(modelContainer)
    }

    /// Deletes the SQLite store together with its `-wal` and `-shm`
    /// sidecar files so SwiftData can create a clean store on the next open.
    private static func removeStoreFiles(at url: URL) {

        let fileManager = FileManager.default

        let storeURLs = [
            url,
            URL(fileURLWithPath: url.path + "-wal"),
            URL(fileURLWithPath: url.path + "-shm")
        ]

        for storeURL in storeURLs
        where fileManager.fileExists(atPath: storeURL.path) {
            try? fileManager.removeItem(at: storeURL)
        }
    }

    func save(
        response: MovieSearchResponse,
        query: String,
        page: Int
    ) throws {

        let normalizedQuery =
            query
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

        let movies = response.search ?? []

        // Remove existing page data first.
        let movieDescriptor = FetchDescriptor<MovieEntity>(
            predicate: #Predicate {
                $0.query == normalizedQuery &&
                $0.page == page
            }
        )

        let existingMovies =
            try modelContext.fetch(movieDescriptor)

        for movie in existingMovies {
            modelContext.delete(movie)
        }

        let pageDescriptor =
            FetchDescriptor<MovieSearchPageEntity>(
                predicate: #Predicate {
                    $0.query == normalizedQuery &&
                    $0.page == page
                }
            )

        let existingPages =
            try modelContext.fetch(pageDescriptor)

        for existingPage in existingPages {
            modelContext.delete(existingPage)
        }

        // Save movies.
        for (index, movie) in movies.enumerated() {

            let entity = MovieEntity(
                imdbID: movie.imdbID,
                title: movie.title,
                year: movie.year,
                poster: movie.poster,
                query: normalizedQuery,
                page: page,
                position: index
            )

            modelContext.insert(entity)
        }

        // Save pagination metadata.
        let metadata = MovieSearchPageEntity(
            query: normalizedQuery,
            page: page,
            totalResults:
                Int(response.totalResults ?? "0") ?? 0
        )

        modelContext.insert(metadata)

        try modelContext.save()
    }

    func fetch(
        query: String,
        page: Int
    ) throws -> MovieSearchResponse? {

        let normalizedQuery =
            query
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

        let movieDescriptor =
            FetchDescriptor<MovieEntity>(
                predicate: #Predicate {
                    $0.query == normalizedQuery &&
                    $0.page == page
                },
                sortBy: [
                    SortDescriptor(\.position)
                ]
            )

        let entities =
            try modelContext.fetch(movieDescriptor)

        guard !entities.isEmpty else {
            return nil
        }

        let metadataDescriptor =
            FetchDescriptor<MovieSearchPageEntity>(
                predicate: #Predicate {
                    $0.query == normalizedQuery &&
                    $0.page == page
                }
            )

        let metadata =
            try modelContext.fetch(metadataDescriptor).first

        let movies = entities.map {
            Movie(
                imdbID: $0.imdbID,
                title: $0.title,
                year: $0.year,
                poster: $0.poster
            )
        }

        return MovieSearchResponse(
            search: movies,
            totalResults: String(
                metadata?.totalResults ?? movies.count
            ),
            response: "True"
        )
    }

    func savedAt(
        query: String,
        page: Int
    ) throws -> Date? {

        let normalizedQuery =
            query
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

        let descriptor =
            FetchDescriptor<MovieSearchPageEntity>(
                predicate: #Predicate {
                    $0.query == normalizedQuery &&
                    $0.page == page
                }
            )

        return try modelContext.fetch(descriptor).first?.savedAt
    }

    func clear() throws {
        try modelContext.delete(
            model: MovieEntity.self
        )

        try modelContext.delete(
            model: MovieSearchPageEntity.self
        )

        try modelContext.save()
    }
}
