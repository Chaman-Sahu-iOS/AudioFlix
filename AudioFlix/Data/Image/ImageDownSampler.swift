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

        let sourceOptions = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary

        guard let source = CGImageSourceCreateWithData(
            data as CFData,
            sourceOptions
        ) else {
            return nil
        }

        let maxDimension = max(
            pointSize.width,
            pointSize.height
        ) * scale

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ] as CFDictionary

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source,
            0,
            options
        ) else {
            return nil
        }

        return UIImage(
            cgImage: cgImage
        )
    }
}
