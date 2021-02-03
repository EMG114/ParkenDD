//
//  Location.swift
//  ParkenDD
//
//  Created by Kilian Költzsch on 12/01/2017.
//  Copyright © 2017 Kilian Koeltzsch. All rights reserved.
//

import Foundation
import CoreLocation

class Location: NSObject {
    private override init() {
        super.init()
        Location.manager.delegate = self
		Location.manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    static let shared = Location()
    static let manager = CLLocationManager()
    static var authState: CLAuthorizationStatus {
        return CLLocationManager.authorizationStatus()
    }

    var lastLocation: CLLocation?

    // This is really weird o.O
    var didMove = [(CLLocation) -> Void]()
    func onMove(_ block: @escaping (CLLocation) -> Void) {
        didMove.append(block)
    }
}

extension Location: CLLocationManagerDelegate {
	
	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		
		switch status {
		case .notDetermined:
			Location.manager.requestAlwaysAuthorization()
			return
		case .authorizedWhenInUse, .authorizedAlways:
			
			guard let currentLocation = manager.location else { return }
			
			lastLocation = currentLocation
			park.fetchCities { (result) in
				switch result {
				case .success(let fetchedResponse):
					let sortedCities = fetchedResponse.cities.sorted { (city1, city2) -> Bool in
						let first = CLLocation(latitude: city1.coordinate.latitude, longitude: city1.coordinate.longitude)
						
						let second = CLLocation(latitude: city2.coordinate.latitude, longitude: city2.coordinate.longitude)
						let firstDistance = self.lastLocation!.distance(from: first)
						let secondDistance = self.lastLocation!.distance(from: second)
						
						return firstDistance < secondDistance
					}
					
					let closestCityName = sortedCities[0].name
					UserDefaults.standard.set(closestCityName, forKey: Defaults.selectedCity)
					UserDefaults.standard.set(closestCityName, forKey: Defaults.selectedCityName)
					
					DispatchQueue.main.async {
						NotificationCenter.default.post(name: NSNotification.Name("UserDidAuthorizeLocationTracking"),
														object: self.lastLocation)
					}
				case .failure( _):
					print("error")
					break
				}
			}
			
		case .restricted:
			// restricted by e.g. parental controls. User can't enable Location Services
			break
		case .denied:
			// user denied your app access to Location Services, but can grant access from Settings.app
			break
		}
	}
		
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        guard let lastLocation = lastLocation else { self.lastLocation = currentLocation; return }

        let distance = currentLocation.distance(from: lastLocation)
        if distance > 100 {
            self.lastLocation = currentLocation
            didMove.forEach { $0(currentLocation) }
        }
    }
	
}
