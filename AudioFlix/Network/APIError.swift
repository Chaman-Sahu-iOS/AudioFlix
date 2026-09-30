//
//  APIError.swift
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

enum APIError: LocalizedError {

    case invalidURL
    case invalidResponse
    case decodingFailed
    case serverError
    case apiError(String)

    var errorDescription: String? {

        switch self {

        case .invalidURL:
            return "Invalid URL."

        case .invalidResponse:
            return "Invalid server response."

        case .decodingFailed:
            return "Unable to process server response."

        case .serverError:
            return "Server error."

        case .apiError(let message):
            return message
        }
    }
}
