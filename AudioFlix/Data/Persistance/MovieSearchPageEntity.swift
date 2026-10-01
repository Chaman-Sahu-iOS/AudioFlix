//
//  MovieSearchPageEntity.swift
//  AudioFlix
//
//  Created by Chaman Lal Sahu on 01/10/26.
//

import Foundation
import SwiftData

@Model
final class MovieSearchPageEntity {

    @Attribute(.unique)
    var cacheKey: String

    var query: String
    var page: Int
    var totalResults: Int
    var savedAt: Date

    init(
        query: String,
        page: Int,
        totalResults: Int,
        savedAt: Date = Date()
    ) {
        self.query = query
        self.page = page
        self.totalResults = totalResults
        self.savedAt = savedAt

        self.cacheKey =
            "\(query.lowercased())_\(page)"
    }
}
