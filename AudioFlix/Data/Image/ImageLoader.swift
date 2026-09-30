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

    private let cache = NSCache<NSString, UIImage>()

    func image(
        from url: URL,
        size: CGSize,
        scale: CGFloat
    ) async throws -> UIImage {

        let key = cacheKey(
            url: url,
            size: size,
            scale: scale
        )

        // 1. Memory cache
        if let cachedImage = cache.object(
            forKey: key as NSString
        ) {
            return cachedImage
        }

        // 2. Network
        let (data, response) =
            try await URLSession.shared.data(
                from: url
            )

        try Task.checkCancellation()

        guard let httpResponse =
                response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode
        else {
            throw APIError.invalidResponse
        }

        // 3. Downsample
        guard let image =
                ImageDownsampler.downsample(
                    data: data,
                    to: size,
                    scale: scale
                )
        else {
            throw APIError.decodingFailed
        }

        try Task.checkCancellation()

        // 4. Cache
        cache.setObject(
            image,
            forKey: key as NSString
        )

        return image
    }

    // MARK: - Prefetch

    func prefetch(
        urls: [URL],
        size: CGSize,
        scale: CGFloat
    ) {

        for url in urls {

            let key = cacheKey(
                url: url,
                size: size,
                scale: scale
            )

            if cache.object(
                forKey: key as NSString
            ) != nil {
                continue
            }

            Task { [weak self] in

                guard let self else {
                    return
                }

                do {

                    _ = try await self.image(
                        from: url,
                        size: size,
                        scale: scale
                    )

                } catch {
                    // Prefetch failure should not
                    // affect visible UI.
                }
            }
        }
    }

    func removeAll() {
        cache.removeAllObjects()
    }

    private func cacheKey(
        url: URL,
        size: CGSize,
        scale: CGFloat
    ) -> String {

        "\(url.absoluteString)_\(Int(size.width))x\(Int(size.height))_\(scale)"
    }
}
