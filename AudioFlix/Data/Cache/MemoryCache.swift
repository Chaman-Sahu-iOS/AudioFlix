//
//  MemoryCache.swift
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
