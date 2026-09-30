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
        movies: [Movie],
        query: String,
        page: Int
    ) throws

    func movies(
        query: String,
        page: Int
    ) throws -> [Movie]

    func clear() throws
}


@MainActor
final class LocalMovieDataSource:
    LocalMovieDataSourceProtocol {

    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    init() throws {

        let schema = Schema([
            MovieEntity.self
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        modelContainer = try ModelContainer(
            for: schema,
            configurations: configuration
        )

        modelContext = ModelContext(
            modelContainer
        )
    }

    func save(
        movies: [Movie],
        query: String,
        page: Int
    ) throws {

        for movie in movies {

            let entity = MovieEntity(
                imdbID: movie.imdbID,
                title: movie.title,
                year: movie.year,
                poster: movie.poster,
                query: query,
                page: page
            )

            modelContext.insert(entity)
        }

        try modelContext.save()
    }

    func movies(
        query: String,
        page: Int
    ) throws -> [Movie] {

        let descriptor = FetchDescriptor<MovieEntity>(
            predicate: #Predicate {
                $0.query == query &&
                $0.page == page
            }
        )

        let entities = try modelContext.fetch(
            descriptor
        )

        return entities.map {
            Movie(
                imdbID: $0.imdbID,
                title: $0.title,
                year: $0.year,
                poster: $0.poster
            )
        }
    }

    func clear() throws {

        try modelContext.delete(
            model: MovieEntity.self
        )

        try modelContext.save()
    }
}
