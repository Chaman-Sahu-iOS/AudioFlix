//
//  HomeView.swift
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

import SwiftUI

struct HomeView: View {

    @StateObject private var viewModel: HomeViewModel

    @State private var searchText = ""

    init() {

        let apiService = APIService()

    
        let cache = MovieCache()
        
        // Opening the SwiftData store can fail; fall back to
        // network + memory cache only rather than crashing.
        let localDataSource = try? LocalMovieDataSource()

        let remoteDataSource = RemoteMovieDataSource(
            apiService: apiService
        )

        let repository = MovieRepository(
            remoteDataSource: remoteDataSource, localDataSource: localDataSource,
            cache: cache
        )

        _viewModel = StateObject(
            wrappedValue: HomeViewModel(
                repository: repository
            )
        )
    }

    var body: some View {

        NavigationStack {

            Group {

                if viewModel.isLoading &&
                    viewModel.movies.isEmpty {

                    ProgressView("Searching...")

                } else if let errorMessage =
                            viewModel.errorMessage,
                          viewModel.movies.isEmpty {

                    ContentUnavailableView(
                        "Something went wrong",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )

                } else {

                    movieList
                }
            }
            .navigationTitle("AudioFlix")
            .searchable(
                text: $searchText,
                prompt: "Search movies"
            )
            .onChange(of: searchText) { _, newValue in

                viewModel.searchMovies(
                    query: newValue
                )
            }
        }
    }

    private var movieList: some View {

        List(viewModel.movies) { movie in

            HStack(spacing: 12) {

                CachedAsyncImage(
                    url: URL(
                        string: movie.poster
                    ),
                    size: CGSize(
                        width: 70,
                        height: 100
                    )
                )
                .frame(
                    width: 70,
                    height: 100
                )
                .clipped()
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 8
                    )
                )

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text(movie.title)
                        .font(.headline)

                    Text(movie.year)
                        .foregroundStyle(
                            .secondary
                        )
                }

                Spacer()
            }
            .onAppear {

                viewModel.loadNextPageIfNeeded(
                    currentMovie: movie
                )

                viewModel.prefetchImages(
                    after: movie
                )
            }
        }
        .overlay {

            if viewModel.isLoadingNextPage {

                VStack {

                    Spacer()

                    ProgressView()
                        .padding()
                }
            }
        }
    }
}
