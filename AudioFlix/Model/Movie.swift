//
//  Movie.swift
//  MyApp
//
//  Created by Chaman Lal Sahu on 30/09/26.
//

import Foundation

struct Movie: Identifiable, Codable {
    let imdbID: String
    let title: String
    let year: String
    let poster: String

    var id: String {
        imdbID
    }

    enum CodingKeys: String, CodingKey {
        case imdbID
        case title = "Title"
        case year = "Year"
        case poster = "Poster"
    }
}

struct MovieSearchResponse: Codable {
    let search: [Movie]?
    let totalResults: String?
    let response: String

    enum CodingKeys: String, CodingKey {
        case search = "Search"
        case totalResults
        case response = "Response"
    }
}



