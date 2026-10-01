//
//  MovieEntity.swift
//  AudioFlix
//
//  Created by Chaman Lal Sahu on 01/10/26.
//

import Foundation
import SwiftData

@Model
final class MovieEntity {

    @Attribute(.unique)
    var cacheKey: String

    var imdbID: String
    var title: String
    var year: String
    var poster: String

    var query: String
    var page: Int
    var position: Int

    init(
        imdbID: String,
        title: String,
        year: String,
        poster: String,
        query: String,
        page: Int,
        position: Int
    ) {
        self.imdbID = imdbID
        self.title = title
        self.year = year
        self.poster = poster
        self.query = query
        self.page = page
        self.position = position

        self.cacheKey =
            "\(query.lowercased())_\(page)_\(imdbID)"
    }
}
