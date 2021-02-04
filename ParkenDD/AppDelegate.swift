//
//  AppDelegate.swift
//  ParkenDD
//
//  Created by Kilian Koeltzsch on 18/01/15.
//  Copyright (c) 2015 Kilian Koeltzsch. All rights reserved.
//

import UIKit
import ParkKit

let park = ParkKit()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

	var inBackground = false

	var supportedCities: [String]?
	var citiesList = [City]() {
		didSet {
            supportedCities = citiesList.map{ $0.name }.sorted()
		}
	}

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Location.manager.requestWhenInUseAuthorization()

        UserDefaults.register(Default.default())

		supportedCities = UserDefaults.standard.array(forKey: Defaults.supportedCities) as? [String]

		// apply custom font to UIBarButtonItems (mainly the back button) as well
		let font = UIFont(name: "AvenirNext-Medium", size: 18.0)
		var attrsDict = [NSAttributedStringKey: Any]()
		attrsDict[NSAttributedStringKey.font] = font
		UIBarButtonItem.appearance().setTitleTextAttributes(attrsDict, for: UIControlState())

		return true
	}

}
