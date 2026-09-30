//
//  MovieCache.swift
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

private final class MovieCacheObject: NSObject {

    let response: MovieSearchResponse
    let cachedAt: Date

    init(
        response: MovieSearchResponse,
        cachedAt: Date
    ) {
        self.response = response
        self.cachedAt = cachedAt
    }
}

actor MovieCache {

    private let cache = NSCache<NSString, MovieCacheObject>()

    func save(
        response: MovieSearchResponse,
        query: String,
        page: Int
    ) {

        let key = cacheKey(
            query: query,
            page: page
        )

        let object = MovieCacheObject(
            response: response,
            cachedAt: Date()
        )

        cache.setObject(
            object,
            forKey: key as NSString
        )
    }

    func get(
        query: String,
        page: Int,
        maxAge: TimeInterval
    ) -> MovieSearchResponse? {

        let key = cacheKey(
            query: query,
            page: page
        )

        guard let object = cache.object(
            forKey: key as NSString
        ) else {
            return nil
        }

        let age = Date().timeIntervalSince(
            object.cachedAt
        )

        if age > maxAge {

            cache.removeObject(
                forKey: key as NSString
            )

            return nil
        }

        return object.response
    }

    func removeAll() {
        cache.removeAllObjects()
    }

    private func cacheKey(
        query: String,
        page: Int
    ) -> String {

        "\(query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))_page_\(page)"
    }
}
