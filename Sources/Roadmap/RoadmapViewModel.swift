//
//  RoadmapViewModel.swift
//  Roadmap
//
//  Created by Antoine van der Lee on 19/02/2023.
//

import Foundation

final class RoadmapViewModel: ObservableObject {
    static let allStatusFilter: String = "all"

    @Published private var features: [RoadmapFeature] = []
    @Published var searchText = ""
    @Published var statusToFilter = RoadmapViewModel.allStatusFilter

    var filteredFeatures: [RoadmapFeature] {
        if statusToFilter == "all" && searchText.isEmpty {
            return features
        } else if statusToFilter != "all" && searchText.isEmpty {
            if searchText.isEmpty {
                return features.filter { feature in
                    feature.localizedFeatureStatus == statusToFilter
                }
            } else {
                return features.filter { feature in
                    (feature
                        .localizedFeatureTitle // check title field...
                        .lowercased() // Roadmap localizes strings in Roadmap.json, so avoid .localizedCaseInsensitiveContains()
                        .contains(searchText.lowercased())  ||
                    feature
                        .localizedFeatureDescription // ...and check description field
                        .lowercased()
                        .contains(searchText.lowercased()))
                    &&
                    feature.localizedFeatureStatus == statusToFilter
                }
            }
        } else {
            return features.filter { feature in
                feature
                    .localizedFeatureTitle // check title field...
                    .lowercased() // Roadmap localizes strings in Roadmap.json, so avoid .localizedCaseInsensitiveContains()
                    .contains(searchText.lowercased())  ||
                feature
                    .localizedFeatureDescription // ...and check description field
                    .lowercased()
                    .contains(searchText.lowercased())
            }
        }
    }
    
    let allowSearching: Bool
    let allowsFilterByStatus: Bool
    var statuses: [String] = []

    private let configuration: RoadmapConfiguration
    
    init(configuration: RoadmapConfiguration) {
        self.configuration = configuration
        self.allowSearching = configuration.allowSearching
        self.allowsFilterByStatus = configuration.allowsFilterByStatus
        loadFeatures(request: configuration.roadmapRequest)
    }

    func loadFeatures(request: URLRequest) {
        
        Task { @MainActor in
            if configuration.shuffledOrder {
                self.features = await FeaturesFetcher(featureRequest: request).fetch().shuffled()
            } else if let sorting = configuration.sorting {
                self.features = await FeaturesFetcher(featureRequest: request).fetch().sorted(by: sorting)
            } else {
                self.features = await FeaturesFetcher(featureRequest: request).fetch()
            }
            
            self.statuses = {
                var featureStatuses = [RoadmapViewModel.allStatusFilter]
                featureStatuses.append(contentsOf: Array(Set(self.features.map { $0.localizedFeatureStatus ?? "" })))
                return featureStatuses
            }()
        }
    }
    
    func filterFeatures(by status: String) {
        self.statusToFilter = status
    }

    func featureViewModel(for feature: RoadmapFeature) -> RoadmapFeatureViewModel {
        .init(feature: feature, configuration: configuration)
    }
}
