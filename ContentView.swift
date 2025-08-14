
import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    @StateObject private var locationService = LocationAndDataService()
    
    var body: some View {
        ZStack {

            TabView {
 
                NavigationView {
                    MainPageView(locationService: locationService)
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            

                NavigationView {
                    InfoView()
                }
                .tabItem {
                    Label("Info", systemImage: "i.circle.fill")
                }
            

                NavigationView {                     SettingsView(locationService: locationService)
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            }
            .onAppear {
                if !locationService.isManualLocationEnabled {
                    locationService.startLocationUpdates()
                }
            }
            

            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
            }
        }
        .onAppear {

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    self.showSplash = false
                }
            }
        }
    }
}
