//
//  APIError.swift
//  MyApp
//
//  Created by Chaman Lal Sahu on 30/09/26.
//

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case decodingFailed
    case serverError
    case apiError(String)
}
