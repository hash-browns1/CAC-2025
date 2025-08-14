import SwiftUI

struct SettingsView: View {
    @ObservedObject var locationService: LocationAndDataService
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        ZStack {
            Color.appbackground
                .ignoresSafeArea()
            
            // MARK: - Manual Location Settings (Card)
            ScrollView{
                VStack(alignment: .leading, spacing: 10) {
                    Text("Location Settings")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Toggle("Use Manual Location", isOn: $locationService.isManualLocationEnabled)
                        .onChange(of: locationService.isManualLocationEnabled) { _, newValue in
                            if !newValue {
                                locationService.startLocationUpdates()
                            }
                        }
                    
                    if locationService.isManualLocationEnabled {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Enter an address")
                                .font(.subheadline)
                            
                            TextField("E.g., 100 Main St, Stayton, OR", text: $locationService.manualAddress)
                                .textFieldStyle(.roundedBorder)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                            
                            Button("Find Burn Status") {
                                locationService.setLocationFromAddress()
                            }
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            
                            if let errorMessage = locationService.geocodingErrorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                VStack(spacing: 20) {
                    // MARK: - Location Permissions Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Manage Permissions")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("You can change the app's location access by managing permissions in your device settings.")
                            .font(.subheadline)
                        
                        Button("Open Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                openURL(url)
                            }
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    
                    
                    
                    // MARK: - About Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("About")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Made By: Anthony Papathanasopoulos")
                        Text("Version: 1.0")
                        
                        Link("Contact Me: toto@laterravita.com", destination: URL(string: "mailto:toto@laterravita.com")!)
                            .frame(maxWidth: .infinity)

                           
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                    
                }
                .padding(.vertical)
                .navigationTitle("Settings")
            }
        }
    }
}

