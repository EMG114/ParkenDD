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
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        guard let lastLocation = lastLocation else { self.lastLocation = currentLocation; return }

        let distance = currentLocation.distance(from: lastLocation)
        if distance > 100 {
            self.lastLocation = currentLocation
            didMove.forEach { $0(currentLocation) }
        }
    }
	
	func getLocationName(with location: CLLocation, completion: @escaping ((String?) -> Void )) {
		
		let geocoder = CLGeocoder()
		geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
			guard let place = placemarks?.first, error == nil else {
				completion(nil)
				return
			}
			
			var cityName = ""
			if let locality = place.locality {
				cityName += locality
			}
			completion(cityName)
		}
		
	}
	
}
