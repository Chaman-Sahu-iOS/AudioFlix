//
//  MemoryCache.swift
//  MyApp
//
//  Created by Chaman Lal Sahu on 30/09/26.
//

import Foundation



final class CacheObject: NSObject {

    let movies: [Movie]
    let cachedAt: Date

    init(
        movies: [Movie],
        cachedAt: Date
    ) {
        self.movies = movies
        self.cachedAt = cachedAt
    }
}


final class MovieCache {

    private let cache = NSCache<NSString, CacheObject>()

    func save(
        movies: [Movie],
        for query: String
    ) {
        let object = CacheObject(
            movies: movies,
            cachedAt: Date()
        )

        cache.setObject(
            object,
            forKey: query as NSString
        )
    }

    func movies(
        for query: String,
        maxAge: TimeInterval
    ) -> [Movie]? {

        guard let object = cache.object(
            forKey: query as NSString
        ) else {
            return nil
        }

        let age = Date().timeIntervalSince(
            object.cachedAt
        )

        guard age < maxAge else {
            cache.removeObject(
                forKey: query as NSString
            )
            return nil
        }

        return object.movies
    }

    func removeAll() {
        cache.removeAllObjects()
    }
}
