import SwiftUI
import NOCTOCore

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var favorites = FavoritesManager()
    @StateObject private var locationManager = LocationManager()
    @State private var venues: [Venue] = []
    @State private var loadError: String?
    @State private var isLoading = true
    @State private var loadLatencyMs = 0
    @State private var lastLoadSucceeded = false

    var body: some View {
        ZStack {
            NoctoTheme.background.ignoresSafeArea()

            if isLoading {
                ProgressView("Зареждане...")
                    .tint(NoctoTheme.accent)
            } else if let loadError {
                ContentUnavailableView(
                    "Неуспешно зареждане",
                    systemImage: "exclamationmark.triangle",
                    description: Text(loadError)
                )
                .padding()
            } else {
                TabView {
                    HomeView(venues: displayedVenues, favorites: favorites)
                        .tabItem { Label("Начало", systemImage: "house") }

                    AllVenuesMapView(venues: venues)
                        .tabItem { Label("Карта", systemImage: "map") }

                    FavoritesView(venues: venues, favorites: favorites)
                        .tabItem { Label("Любими", systemImage: "heart") }

                    NightPulseView(snapshot: snapshot)
                        .tabItem { Label("Пулс", systemImage: "waveform.path.ecg") }

                    ProfileView(
                        favoritesCount: favorites.favoriteIDs.count,
                        snapshot: snapshot,
                        venues: venues,
                        favorites: favorites
                    )
                    .tabItem { Label("Профил", systemImage: "person.crop.circle") }
                }
                .tint(NoctoTheme.accent)
            }
        }
        .task {
            let startedAt = Date()
            isLoading = true
            loadError = nil
            do {
                venues = try await VenueRepository().loadVenues()
                lastLoadSucceeded = true
                locationManager.requestAccess()
            } catch is CancellationError {
                isLoading = false
                return
            } catch {
                loadError = error.localizedDescription
                lastLoadSucceeded = false
            }
            loadLatencyMs = Int(Date().timeIntervalSince(startedAt) * 1000)
            isLoading = false

        }
        .onChange(of: scenePhase, initial: true) { _, newPhase in
            guard newPhase == .active, !isLoading else { return }
            Task {
                if #available(iOS 16.1, *) {
                    await NoctoLiveActivityHandler.shared.sync(with: snapshot)
                }
            }
        }
        .onChange(of: isLoading, initial: false) { _, loading in
            guard loading == false, scenePhase == .active else { return }
            Task {
                if #available(iOS 16.1, *) {
                    await NoctoLiveActivityHandler.shared.sync(with: snapshot)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var displayedVenues: [Venue] {
        guard let location = locationManager.lastKnownLocation else {
            return venues
        }

        return ProximityRanker.rank(venues: venues, from: location).map(\.venue)
    }

    private var snapshot: OperationalSnapshot {
        OperationalSnapshot(
            loadLatencyMs: loadLatencyMs,
            didLoadSucceed: lastLoadSucceeded,
            lastErrorMessage: loadError,
            venues: venues
        )
    }
}
