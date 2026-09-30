//
//  HomeView.swift
//  MyApp
//
//  Created by Chaman Lal Sahu on 30/09/26.
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
                            
                            AsyncImage(
                                url: URL(string: movie.poster)
                            ) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                ProgressView()
                            }
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
