

import SwiftUI
import CoreLocation

struct MainPageView: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var locationService: LocationAndDataService

    var body: some View {
        ZStack {
            Color.appbackground
                .ignoresSafeArea()
            
            VStack(spacing: 8) {
                Text("")
                    .padding(5)
                Text("ROB𝓲")
                    .font(.system(size: 70))
                    .fontWeight(.bold)
                    .padding(.bottom, 5)
                Text("Rural Open Burning 𝓲nformation")
                Text("Oregon")
                    .padding(.bottom, 5)
                
                // MARK: - Location Info Section
                VStack(spacing: 5) {
                    Text("Your Location:")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                    if let location = locationService.currentlocation {
                        Text("Lat: \(location.latitude, specifier: "%.4f"), Lon: \(location.longitude, specifier: "%.4f")")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.bottom, 5)
                    } else {
                        Text("Location not available")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)

                // MARK: - Conditional Burn Advisory Card Block
                if locationService.currentFireDistrictName == "SUTHERLIN FD" {

                    VStack(spacing: 10) {
                        Text("Sutherlin FD Fire Danger Level:")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                        Text(locationService.sutherlinRestrictionLevel)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(
                                getRestrictionColor(for: locationService.sutherlinRestrictionLevel)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                } else {
 
                    VStack(spacing: 10) {
                        Text("Today's Burn Advisory For Willamette Valley:")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.bottom, 5)
                        VStack() {
                            Text("Agricultural Burning:")
                                .font(.subheadline)
                                .foregroundColor(.black)
                            Text(locationService.agriculturalBurnTimes)
                                .font(.callout)
                                .bold()
                                .foregroundColor(
                                    locationService.agriculturalBurnTimes.contains("N/A") || locationService.agriculturalBurnTimes.contains("No burning permitted today") ? .red : .green
                                )
                        }
                        VStack() {
                            Text("Backyard Burning (Special Control Areas):")
                                .font(.subheadline)
                                .foregroundColor(.black)
                            Text(locationService.backyardBurnTimes)
                                .font(.callout)
                                .bold()
                                .foregroundColor(
                                    locationService.backyardBurnTimes.contains("N/A") || locationService.backyardBurnTimes.contains("No burning permitted today") ? .red : .green
                                )
                        }
                        if let error = locationService.burnAdvisoryErrorMessage {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .padding(.top, 5)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(15)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                    .padding(.horizontal, 20)
                }

                // MARK: - Fire District Info Section (Combined Card)
                VStack(spacing: 10) {
                    Text("Your Fire District:")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .padding(.bottom, 5)
                    if let districtName = locationService.currentFireDistrictName {
                        Text(districtName)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    } else {
                        Text("No district found for your location")
                            .font(.title2)
                            .foregroundColor(.red)
                    }
                    // MARK: - Contact Info (Burn Lines Lookup)
                    if let contactInfo = locationService.contactInfo {
                        VStack(spacing: 5) {
                            Text("Contact Info:")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.top, 3)
                            if let burnLine = contactInfo.BurnLinePhone, !burnLine.isEmpty {
                                Link("Burn Line: \(burnLine)", destination: URL(string: "tel:\(burnLine.filter("0123456789".contains))")!)
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                            if let mainPhone = contactInfo.MainPhone, !mainPhone.isEmpty {
                                Link("Main Office: \(mainPhone)", destination: URL(string: "tel:\(mainPhone.filter("0123456789".contains))")!)
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                            if let website = contactInfo.Website, let url = URL(string: website) {
                                Link("Website", destination: url)
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 10)
                        .frame(maxWidth: .infinity)
                    } else if locationService.currentFireDistrictName != nil {
                        Text("No specific contact info found for this district in our database.")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .multilineTextAlignment(.center)
                            .padding(.top, 5)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(15)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 20)
                
                Spacer()
                
                Button {
                    locationService.requestLocationAuthorization()
                    locationService.startLocationUpdates()
                    locationService.fetchAndParseBurnStatus()
                    locationService.fetchSutherlinRestrictionLevel()
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 9)
                        .padding(.horizontal, 20)
                        .background(Color.blue)
                        .cornerRadius(25)
                        .shadow(radius: 5)
                }
                .padding(.bottom, 30)
            }
            .minimumScaleFactor(0.8)
        }
        .onAppear {
            locationService.requestLocationAuthorization()
            locationService.startLocationUpdates()
            locationService.fetchAndParseBurnStatus()
            locationService.fetchSutherlinRestrictionLevel()
        }
    }
    
    private func getRestrictionColor(for level: String) -> Color {
        let normalizedLevel = level.uppercased()
        switch normalizedLevel {
        case "EXTREME":
            return .red
        case "HIGH":
            return .orange
        case "MODERATE":
            return .yellow
        case "LOW":
            return .green
        default:
            return .gray
        }
    }
}
