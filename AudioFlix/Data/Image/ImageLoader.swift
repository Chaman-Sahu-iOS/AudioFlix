//
//  ImageLoader.swift
//  AudioFlix
//
//  Created by Chaman Lal Sahu on 30/09/26.
//

import Foundation
import UIKit

actor ImageLoader {

    static let shared = ImageLoader()

    private let cache = NSCache<NSURL, UIImage>()

    func image(
        from url: URL
    ) async throws -> UIImage {

        // 1. Check memory cache
        if let cachedImage = cache.object(
            forKey: url as NSURL
        ) {
            return cachedImage
        }

        // 2. Download
        let (data, response) = try await URLSession.shared.data(
            from: url
        )

        // 3. Validate response
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw APIError.invalidResponse
        }

        // 4. Decode image
        guard let image = UIImage(data: data) else {
            throw APIError.decodingFailed
        }

        // 5. Store in cache
        cache.setObject(
            image,
            forKey: url as NSURL
        )

        return image
    }
}
