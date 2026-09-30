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
    var imdbID: String

    var title: String
    var year: String
    var poster: String

    var query: String
    var page: Int

    var savedAt: Date

    init(
        imdbID: String,
        title: String,
        year: String,
        poster: String,
        query: String,
        page: Int,
        savedAt: Date = Date()
    ) {
        self.imdbID = imdbID
        self.title = title
        self.year = year
        self.poster = poster
        self.query = query
        self.page = page
        self.savedAt = savedAt
    }
}
