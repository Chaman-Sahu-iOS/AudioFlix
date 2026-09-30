//
//  ImageDownSampler.swift
//  AudioFlix
//
//  Created by Chaman Lal Sahu on 01/10/26.
//

import ImageIO
import UIKit

enum ImageDownsampler {

    static func downsample(
        data: Data,
        to pointSize: CGSize,
        scale: CGFloat
    ) -> UIImage? {

        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]

        guard let source = CGImageSourceCreateWithData(
            data as CFData,
            sourceOptions as CFDictionary
        ) else {
            return nil
        }

        let maxDimension = max(
            pointSize.width,
            pointSize.height
        ) * scale

        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]

        guard let image = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            thumbnailOptions as CFDictionary
        ) else {
            return nil
        }

        return UIImage(
            cgImage: image,
            scale: scale,
            orientation: .up
        )
    }
}
