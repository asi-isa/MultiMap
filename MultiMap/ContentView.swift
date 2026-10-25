import MapKit
import SwiftUI
import Playgrounds

struct ContentView: View {
    @AppStorage("searchText") private var searchText = ""
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(
            latitude: 51.507222,
            longitude: -0.1275),
        span: MKCoordinateSpan(
            latitudeDelta: 0.5,
            longitudeDelta: 0.5)))
    
    @State private var locations = [Location]()
    @State private var selectedLocations = Set<Location>()
    
    var body: some View {
        NavigationSplitView {
            List(locations, selection: $selectedLocations) { location in
                Text(location.name)
                    .tag(location)
                    .contextMenu {
                        Button("Delete", role: .destructive) {
                            delete(location)
                        }
                    }
            }
            .onDeleteCommand(perform: {
                for location in selectedLocations {
                    delete(location)
                }
            })
            .frame(minWidth: 200)
            
        } detail: {
            Map(position: $position) {
                ForEach(locations) { location in
                    Annotation(location.name, coordinate: location.coordinate) {
                        Text(location.name)
                            .font(.headline)
                            .padding(5)
                            .padding(.horizontal, 5)
                            .background(.black)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .onSubmit(of: .search) { Task { await runSearch() } }
        .onChange(of: selectedLocations) { handleSelect() }
    }
    
    private func runSearch() async {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.naturalLanguageQuery = searchText
        
        let search = MKLocalSearch(request: searchRequest)
        
        do {
            let response = try await search.start()
            
            guard let item = response.mapItems.first else { return }
            guard let itemName = item.name else { return }
            
            let newLocation = Location(
                name: itemName,
                latitude: item.location.coordinate.latitude,
                longitude: item.location.coordinate.longitude
            )
            
            locations.append(newLocation)
            selectedLocations = [newLocation]
            searchText = ""
        } catch {
            print("Search failed: \(error.localizedDescription)")
        }
    }
    
    private func handleSelect() {
        var visibleMap = MKMapRect.null
        for selectedLocation in selectedLocations {
            let mapPoint = MKMapPoint(selectedLocation.coordinate)
            let pointRect = MKMapRect(
                x: mapPoint.x - 100_000,
                y: mapPoint.y - 100_000,
                width: 200_000,
                height: 200_000
            )
            visibleMap = visibleMap.union(pointRect)
            var newRegion = MKCoordinateRegion(visibleMap)
            newRegion.span.latitudeDelta *= 1.5
            newRegion.span.longitudeDelta *= 1.5
            withAnimation {
                position = .region(newRegion)
            }
        }
    }
    
    private func delete(_ location: Location) {
        guard let index = locations.firstIndex(of: location) else { return }
        
        locations.remove(at: index)
    }
}

#Preview {
    ContentView()
}

#Playground {
    _ = 1 + 2
}
