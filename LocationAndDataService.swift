import Foundation
import CoreLocation
import Kanna

// MARK: - LocationAndDataService Class

class LocationAndDataService: NSObject, ObservableObject, CLLocationManagerDelegate {

    // MARK: - Published Properties

    @Published var currentFireDistrictName: String?
    @Published var contactInfo: FireDistrictContactInfo?
    @Published var currentlocation: CLLocationCoordinate2D?
    
    @Published var agriculturalBurnTimes: String = "Loading..."
    @Published var backyardBurnTimes: String = "Loading..."
    @Published var burnAdvisoryErrorMessage: String?

    // MARK: - New Sutherlin FD Scraping Property
    @Published var sutherlinRestrictionLevel: String = "Loading..."

    // MARK: - New Manual Location Properties
    @Published var isManualLocationEnabled: Bool = false
    @Published var manualLocation: CLLocationCoordinate2D?
    @Published var manualAddress: String = ""
    @Published var geocodingErrorMessage: String?

    // MARK: - Private Properties
    private let locationManager = CLLocationManager()
    private var fireDistrictPolygons: [FireDistrictPolygon] = []
    
    @Published var burnLinesLookup: [String: FireDistrictContactInfo]?

    // MARK: - Initialization

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        loadFireDistrictPolygons()
        loadBurnLinesLookup()
    }

    // MARK: - Public Methods for Location Management

    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startLocationUpdates() {
        guard !isManualLocationEnabled else {
            return
        }
        
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
            print("Started location updates.")
        } else {
            print("Location authorization not granted to start updates.")
        }
    }

    // MARK: - Location Manager Delegate Methods

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.currentlocation = location.coordinate
        print("Location updated: Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)")
        findFireDistrictForCurrentLocation()
        locationManager.stopUpdatingLocation()
        print("Stopped location updates.")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location access authorized.")
            startLocationUpdates()
        case .denied, .restricted:
            print("Location access denied or restricted.")
        case .notDetermined:
            print("Location authorization not determined.")
        @unknown default:
            print("Unknown location authorization status.")
        }
    }
    
    // MARK: - New Address Geocoding Method

    func setLocationFromAddress() {
        guard !manualAddress.isEmpty else {
            DispatchQueue.main.async {
                self.geocodingErrorMessage = "Please enter an address."
                self.currentFireDistrictName = "Please enter an address."
                self.contactInfo = nil
            }
            return
        }

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(manualAddress) { [weak self] (placemarks, error) in
            guard let self = self else { return }

            DispatchQueue.main.async {
                if let error = error {
                    self.geocodingErrorMessage = "Geocoding failed: \(error.localizedDescription)"
                    self.manualLocation = nil
                    self.currentFireDistrictName = "Address not found."
                    self.contactInfo = nil
                    return
                }

                guard let placemark = placemarks?.first,
                      let location = placemark.location else {
                    self.geocodingErrorMessage = "Address not found."
                    self.manualLocation = nil
                    self.currentFireDistrictName = "Address not found."
                    self.contactInfo = nil
                    return
                }

                self.geocodingErrorMessage = nil
                self.manualLocation = location.coordinate
                
                print("Successfully geocoded address to coordinates: Lat: \(location.coordinate.latitude), Lon: \(location.coordinate.longitude)")
                
                self.findFireDistrictForCurrentLocation()
            }
        }
    }
    
    // MARK: - Data Loading Methods

    private func loadFireDistrictPolygons() {
        guard let url = Bundle.main.url(forResource: "Oregon Structural Fire Districts (1).geojson", withExtension: nil) else {
            print("Error: Could not find Oregon Structural Fire Districts (1).geojson in the main bundle.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let geoJSON = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

            guard let features = geoJSON?["features"] as? [[String: Any]] else {
                print("Error: GeoJSON 'features' array not found or invalid.")
                return
            }

            self.fireDistrictPolygons = features.compactMap { feature in
                guard let properties = feature["properties"] as? [String: Any],
                      let districtName = properties["Agency_Name"] as? String,
                      let geometry = feature["geometry"] as? [String: Any],
                      let type = geometry["type"] as? String else {
                    print("Skipping feature without 'Agency_Name' string property or invalid format.")
                    return nil
                }

                guard let coordinates = normalizeCoordinates(geometry: geometry, type: type) else {
                    print("Failed to normalize coordinates for district: \(districtName)")
                    return nil
                }

                return FireDistrictPolygon(name: districtName, type: type, coordinates: coordinates)
            }
            print("Successfully loaded \(self.fireDistrictPolygons.count) fire district polygons.")
        } catch {
            print("Error loading GeoJSON: \(error.localizedDescription)")
        }
    }

    private func normalizeCoordinates(geometry: [String: Any], type: String) -> [[CLLocationCoordinate2D]]? {
        switch type {
        case "Polygon":
            guard let rawCoordinates = geometry["coordinates"] as? [[[Double]]] else { return nil }
            return rawCoordinates.map { ring in
                return ring.map { coordArray in
                    CLLocationCoordinate2D(latitude: coordArray[1], longitude: coordArray[0])
                }
            }
        case "MultiPolygon":
            guard let rawCoordinates = geometry["coordinates"] as? [[[[Double]]]] else { return nil }
            return rawCoordinates.flatMap { polygon in
                return polygon.map { ring in
                    return ring.map { coordArray in
                        CLLocationCoordinate2D(latitude: coordArray[1], longitude: coordArray[0])
                    }
                }
            }
        default:
            return nil
        }
    }
    
    private func loadBurnLinesLookup() {
        guard let url = Bundle.main.url(forResource: "burn_lines_lookup", withExtension: "json") else {
            print("Error: Could not find burn_lines_lookup.json in the main bundle.")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let decodedArray = try decoder.decode([FireDistrictContactInfo].self, from: data)

            self.burnLinesLookup = Dictionary(uniqueKeysWithValues: decodedArray.compactMap { contact in
                guard let districtName = contact.DistrictName, !districtName.isEmpty else {
                    print("Warning: Skipping contact info with missing or empty DistrictName.")
                    return nil
                }
                return (districtName, contact)
            })
            print("Successfully loaded burn_lines_lookup.json")
        } catch {
            print("Error loading or decoding burn_lines_lookup.json: \(error.localizedDescription)")
        }
    }

    // MARK: - Point-in-Polygon Logic with Fallback
    func findFireDistrictForCurrentLocation() {
        let locationToUse: CLLocationCoordinate2D?
        if isManualLocationEnabled {
            locationToUse = self.manualLocation
        } else {
            locationToUse = self.currentlocation
        }
        
        guard let location = locationToUse else {
            print("No location available to find district.")
            DispatchQueue.main.async {
                self.currentFireDistrictName = "Waiting for location..."
                self.contactInfo = nil
            }
            return
        }

        var foundDistrict: String?
        for district in fireDistrictPolygons {
            if isPoint(location, in: district) {
                foundDistrict = district.name
                break
            }
        }
        
        if foundDistrict == nil {
            print("No district found at exact location. Searching for nearest district...")
            if let nearestDistrict = findNearestDistrict(for: location) {
                foundDistrict = nearestDistrict
            }
        }

        if let districtName = foundDistrict {
            DispatchQueue.main.async {
                self.currentFireDistrictName = districtName
                if let contact = self.burnLinesLookup?[districtName] {
                    self.contactInfo = contact
                    print("Found contact info for \(districtName).")
                } else {
                    self.contactInfo = nil
                    print("No specific contact info found for district: \(districtName) in our database (burn_lines_lookup.json).")
                }
                

                if districtName == "Sutherlin FD" {
                    self.fetchSutherlinRestrictionLevel()
                } else {
                    self.fetchAndParseBurnStatus()
                }
            }
        } else {
            DispatchQueue.main.async {
                self.currentFireDistrictName = "No district found for location."
                self.contactInfo = nil
                print("No district found for location \(location.latitude), \(location.longitude)")

                self.sutherlinRestrictionLevel = "N/A"
                self.agriculturalBurnTimes = "N/A"
                self.backyardBurnTimes = "N/A"
            }
        }
    }

    private func findNearestDistrict(for location: CLLocationCoordinate2D) -> String? {
        print("DEBUG: Using point-to-polygon distance to find nearest district.")
        var nearestDistrictName: String?
        var minDistance: CLLocationDistance = .greatestFiniteMagnitude
        
        let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)

        for district in fireDistrictPolygons {
            let distance = distanceFromPoint(userLocation, toPolygon: district)
            
            if distance < minDistance {
                minDistance = distance
                nearestDistrictName = district.name
            }
        }
        return nearestDistrictName
    }

    private func distanceFromPoint(_ point: CLLocation, toPolygon polygon: FireDistrictPolygon) -> CLLocationDistance {
        var minDistance: CLLocationDistance = .greatestFiniteMagnitude
        
        for ring in polygon.coordinates {
            for i in 0..<(ring.count - 1) {
                let p1 = ring[i]
                let p2 = ring[i+1]
                
                let lineStart = CLLocation(latitude: p1.latitude, longitude: p1.longitude)
                let lineEnd = CLLocation(latitude: p2.latitude, longitude: p2.longitude)
                
                let distance = distanceFromPoint(point, toLineSegmentFrom: lineStart, to: lineEnd)
                
                if distance < minDistance {
                    minDistance = distance
                }
            }
        }
        
        return minDistance
    }
    
    private func distanceFromPoint(_ point: CLLocation, toLineSegmentFrom p1: CLLocation, to p2: CLLocation) -> CLLocationDistance {
        let x = point.coordinate.longitude
        let y = point.coordinate.latitude
        let x1 = p1.coordinate.longitude
        let y1 = p1.coordinate.latitude
        let x2 = p2.coordinate.longitude
        let y2 = p2.coordinate.latitude
        
        let A = x - x1
        let B = y - y1
        let C = x2 - x1
        let D = y2 - y1
        
        let dot = A * C + B * D
        let lenSq = C * C + D * D
        
        var param = -1.0
        if lenSq != 0 {
            param = dot / lenSq
        }
        
        let nearestPoint: CLLocationCoordinate2D
        if param < 0 {
            nearestPoint = p1.coordinate
        } else if param > 1 {
            nearestPoint = p2.coordinate
        } else {
            nearestPoint = CLLocationCoordinate2D(latitude: y1 + param * D, longitude: x1 + param * C)
        }
        
        return point.distance(from: CLLocation(latitude: nearestPoint.latitude, longitude: nearestPoint.longitude))
    }

    private func isPoint(_ point: CLLocationCoordinate2D, in polygon: FireDistrictPolygon) -> Bool {
        for ring in polygon.coordinates {
            if self.isPoint(point, inRing: ring) {
                return true
            }
        }
        return false
    }

    private func isPoint(_ point: CLLocationCoordinate2D, inRing ring: [CLLocationCoordinate2D]) -> Bool {
        guard ring.count > 2 else { return false }

        var intersections = 0
        let x = point.longitude
        let y = point.latitude

        for i in 0..<(ring.count - 1) {
            let p1 = ring[i]
            let p2 = ring[(i + 1) % ring.count]

            let x1 = p1.longitude
            let y1 = p1.latitude
            let x2 = p2.longitude
            let y2 = p2.latitude

            if ((y1 <= y && y < y2) || (y2 <= y && y < y1)) &&
                (x < ((x2 - x1) * (y - y1)) / (y2 - y1) + x1) {
                intersections += 1
            }
        }
        return intersections % 2 != 0
    }

    // MARK: - Burn Advisory Scraping Logic (Willamette Valley)

    func fetchAndParseBurnStatus() {
        DispatchQueue.main.async {
            self.agriculturalBurnTimes = "Loading..."
            self.backyardBurnTimes = "Loading..."
            self.burnAdvisoryErrorMessage = nil
        }

        var actualHeaderFoundText: String? = nil

        guard let url = URL(string: "https://smkmgt.com/burn.php") else {
            DispatchQueue.main.async {
                self.burnAdvisoryErrorMessage = "Invalid URL for burn advisory."
            }
            return
        }

        let referrerURL = "https://www.google.com/"

        print("DEBUG: Attempting to fetch burn advisory from: \(url.absoluteString) with Referer: \(referrerURL)")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(referrerURL, forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 120.0

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let networkError = error {
                let errorDescription = networkError.localizedDescription
                print("Network error: \(errorDescription)")
                DispatchQueue.main.async {
                    self.burnAdvisoryErrorMessage = "Network error: \(errorDescription)"
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    self.burnAdvisoryErrorMessage = "No HTTP response received."
                }
                print("ERROR: No HTTP response received.")
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let statusCode = httpResponse.statusCode
                let responseBody = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No response body."
                print("HTTP Error: Status code \(statusCode). Response body: \(responseBody.prefix(100))...")
                DispatchQueue.main.async {
                    self.burnAdvisoryErrorMessage = "HTTP Error: Status code \(statusCode). Check URL or website status. Response: \(responseBody.prefix(100))..."
                }
                return
            }

            guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self.burnAdvisoryErrorMessage = "Could not decode HTML content for burn advisory."
                }
                print("ERROR: Could not decode HTML content from data.")
                return
            }

            do {
                let doc = try HTML(html: htmlString, encoding: .utf8)

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMMM d, yyyy"
                let todayDate = Date()
                let dayOfMonth = Calendar.current.component(.day, from: todayDate)

                var dayStringWithSuffix = "\(dayOfMonth)"
                switch dayOfMonth {
                case 1, 21, 31: dayStringWithSuffix += "st"
                case 2, 22: dayStringWithSuffix += "nd"
                case 3, 23: dayStringWithSuffix += "rd"
                default: dayStringWithSuffix += "th"
                }

                let monthYearString = dateFormatter.string(from: todayDate)
                let datePartWithSuffix = monthYearString.replacingOccurrences(of: "\(dayOfMonth),", with: "\(dayStringWithSuffix),", options: .literal, range: monthYearString.range(of: "\(dayOfMonth),"))

                let dayOfWeekFormatter = DateFormatter()
                dayOfWeekFormatter.dateFormat = "EEEE"
                let dayOfWeek = dayOfWeekFormatter.string(from: todayDate)

                let targetAnnouncementHeader = "Open Burn Announcement for \(dayOfWeek), \(datePartWithSuffix)"
                print("DEBUG: App's Constructed Target Header: '\(targetAnnouncementHeader)'")

                var foundPreTagForToday: XMLElement? = nil
                var allBoldTagsFound: [String] = []

                for boldNode in doc.css("b") {
                    let boldNodeTextRaw = boldNode.text ?? ""
                    let normalizedBoldNodeText = boldNodeTextRaw
                        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    allBoldTagsFound.append(normalizedBoldNodeText)

                    if normalizedBoldNodeText == targetAnnouncementHeader {
                        actualHeaderFoundText = normalizedBoldNodeText
                        if let parentPre = boldNode.parent, parentPre.tagName == "pre" {
                            foundPreTagForToday = parentPre
                            print("DEBUG: Found the correct <pre> tag for today's announcement in service.")
                            break
                        }
                    }
                }

                print("DEBUG: All <b> tags found on page:")
                if allBoldTagsFound.isEmpty {
                    print("  (No bold tags found)")
                } else {
                    for tagText in allBoldTagsFound {
                        print("  - '\(tagText)'")
                    }
                }
                print("--- End <b> tags ---")

                if foundPreTagForToday == nil {
                    DispatchQueue.main.async {
                        self.agriculturalBurnTimes = "N/A"
                        self.backyardBurnTimes = "N/A"
                        self.burnAdvisoryErrorMessage = "Today's burn announcement not found. Expected: '\(targetAnnouncementHeader)'. Actual header from site: '\(actualHeaderFoundText ?? "None")'."
                    }
                    return
                }

                if let preTagContent = foundPreTagForToday?.text {
                    let fullAnnouncementText = preTagContent

                    let agPattern = "Agricultural burning:\\s*\\*?\\s*When allowed locally and based on air quality considerations recommend agricultural burning\\s*be limited to the period from\\s*(\\d{1,2}:\\d{2}\\s*[ap]\\.m\\.\\s*to\\s*\\d{1,2}:\\d{2}\\s*[ap]\\.m\\.)"
                    let backyardPattern = "Backyard burning inside special control areas:\\s*\\*?\\s*When allowed locally and based on air quality considerations backyard burning is allowed\\s*from\\s*(\\d{1,2}:\\d{2}\\s*[ap]\\.m\\.\\s*to\\s*\\d{1,2}:\\d{2}\\s*[ap]\\.m\\.)"

                    let agTimes = self.extractTime(from: fullAnnouncementText, pattern: agPattern) ?? "No burning permitted today"
                    let backyardTimes = self.extractTime(from: fullAnnouncementText, pattern: backyardPattern) ?? "No burning permitted today"

                    DispatchQueue.main.async {
                        self.agriculturalBurnTimes = agTimes
                        self.backyardBurnTimes = backyardTimes
                        self.burnAdvisoryErrorMessage = nil
                    }
                } else {
                    DispatchQueue.main.async {
                        self.agriculturalBurnTimes = "N/A"
                        self.backyardBurnTimes = "N/A"
                        self.burnAdvisoryErrorMessage = "Error: Could not extract text from found announcement block for burn advisory."
                    }
                }

            } catch let parsingError {
                print("HTML parsing error in service: \(parsingError)")
                DispatchQueue.main.async {
                    self.burnAdvisoryErrorMessage = "Parsing error: \(parsingError.localizedDescription)"
                }
            }
        }.resume()
    }

    // MARK: - Sutherlin Fire Danger Scraping Logic
    func fetchSutherlinRestrictionLevel() {
        DispatchQueue.main.async {
            self.sutherlinRestrictionLevel = "Loading..."
        }

        let urlString = "https://www.dfpa.net/"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async {
                self.sutherlinRestrictionLevel = "Error"
            }
            return
        }

        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("Error fetching Sutherlin fire danger: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.sutherlinRestrictionLevel = "Error"
                }
                return
            }

            guard let data = data, let htmlString = String(data: data, encoding: .utf8) else {
                print("Failed to decode HTML for Sutherlin fire danger.")
                DispatchQueue.main.async {
                    self.sutherlinRestrictionLevel = "Error"
                }
                return
            }

            do {
                let doc = try HTML(html: htmlString, encoding: .utf8)


                if let levelElement = doc.xpath("//h2[contains(., 'Current Public Use Restriction Level')]/span[contains(., 'Current Public Use Restriction Level:')]/following-sibling::br/following-sibling::span").first {
                    let level = levelElement.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "N/A"
                    DispatchQueue.main.async {
                        self.sutherlinRestrictionLevel = level
                        print("Successfully scraped Sutherlin fire danger: \(level)")
                    }
                } else {
                    print("Could not find the fire danger level element.")
                    DispatchQueue.main.async {
                        self.sutherlinRestrictionLevel = "N/A"
                    }
                }
            } catch let parsingError {
                print("HTML parsing error for Sutherlin fire danger: \(parsingError)")
                DispatchQueue.main.async {
                    self.sutherlinRestrictionLevel = "Error"
                }
            }
        }.resume()
    }


    private func extractTime(from text: String, pattern: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators])
            if let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) {
                if match.numberOfRanges > 1, let range = Range(match.range(at: 1), in: text) {
                    let timeString = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    return timeString.hasSuffix(".") ? String(timeString.dropLast()) : timeString
                }
            }
        } catch {
            print("ERROR: Regex creation failed for pattern '\(pattern)': \(error)")
        }
        return nil
    }
}

// MARK: - Data Structures (Models)

struct FireDistrictPolygon {
    let name: String
    let type: String
    let coordinates: [[CLLocationCoordinate2D]]
}

struct FireDistrictContactInfo: Codable, Identifiable {
    let id: UUID
    let DistrictName: String?
    let BurnLinePhone: String?
    let MainPhone: String?
    let Website: String?
    let OFCDistrict: String?

    enum CodingKeys: String, CodingKey {
        case DistrictName
        case BurnLinePhone
        case MainPhone
        case Website
        case OFCDistrict
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.DistrictName = try container.decodeIfPresent(String.self, forKey: .DistrictName)
        self.BurnLinePhone = try container.decodeIfPresent(String.self, forKey: .BurnLinePhone)
        self.MainPhone = try container.decodeIfPresent(String.self, forKey: .MainPhone)
        self.Website = try container.decodeIfPresent(String.self, forKey: .Website)
        self.OFCDistrict = try container.decodeIfPresent(String.self, forKey: .OFCDistrict)

        self.id = UUID()
    }
}
