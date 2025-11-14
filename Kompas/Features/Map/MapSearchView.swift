import SwiftUI
import MapKit
import Combine

class MapSearchVM: ObservableObject {
    @Published var searchText = ""
    @Published var results: [MKMapItem] = []
    @Published var isSearching = false
    
    private var cancellables = Set<AnyCancellable>()
    
    func search(query: String) {
        guard !query.isEmpty else {
            results = []
            return
        }
        
        isSearching = true
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isSearching = false
                
                if let error = error {
                    print("Error en búsqueda: \(error.localizedDescription)")
                    self.results = []
                    return
                }
                
                if let response = response {
                    self.results = response.mapItems
                } else {
                    self.results = []
                }
            }
        }
    }
    
    func clearResults() {
        results = []
        searchText = ""
    }
}
