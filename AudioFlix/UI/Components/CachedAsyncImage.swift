//
//  CachedAsyncImage.swift
//  AudioFlix
//
//  Created by Chaman Lal Sahu on 01/10/26.
//

import SwiftUI

struct CachedAsyncImage: View {

    let url: URL?
    let size: CGSize

    @Environment(\.displayScale) private var displayScale

    @State private var image: UIImage?
    @State private var isLoading = false

    var body: some View {

        Group {

            if let image {

                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()

            } else if isLoading {

                ProgressView()

            } else {

                Rectangle()
                    .fill(.quaternary)
                    .overlay {

                        Image(systemName: "photo")
                            .foregroundStyle(
                                .secondary
                            )
                    }
            }
        }
        .task(id: url) {

            await loadImage()
        }
    }

    private func loadImage() async {

        guard let url else {
            return
        }

        isLoading = true

        defer {
            isLoading = false
        }

        do {

            image = try await ImageLoader.shared.image(
                from: url,
                size: size,
                scale: displayScale
            )

        } catch is CancellationError {

            return

        } catch {

            image = nil
        }
    }
}
