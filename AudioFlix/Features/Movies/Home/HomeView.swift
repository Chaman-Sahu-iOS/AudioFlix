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
    
    init() {
        let apiService = APIService()
        
        let remoteDataSource = RemoteMovieDataSource(
            apiService: apiService
        )
        
        let cache = MovieCache()
        
        let repository = MovieRepository(
            remoteDataSource: remoteDataSource,
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
                
                if viewModel.isLoading {
                    
                    ProgressView()
                    
                } else {
                    
                    List(viewModel.movies) { movie in
                        
                        HStack(spacing: 12) {
                            
                            CachedAsyncImage(
                                url: URL(string: movie.poster)
                            )
                            .frame(
                                width: 70,
                                height: 100
                            )
                            .clipped()
                            
                            VStack(alignment: .leading) {
                                Text(movie.title)
                                    .font(.headline)
                                
                                Text(movie.year)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Movies")
            .task {
                viewModel.searchMovies(query: "Batman")
            }
        }
    }
}
