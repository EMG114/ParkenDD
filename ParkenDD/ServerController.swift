//
//  ServerController.swift
//  ParkenDD
//
//  Created by Kilian Költzsch on 20/02/15.
//  Copyright (c) 2015 Kilian Koeltzsch. All rights reserved.
//

import UIKit
import Alamofire
import ObjectMapper

class ServerController {

	enum SCError {
		case server
		case request
		case incompatibleAPI
		case notFound
		case noData
		case unknown
	}

	struct SCOptions {
		static let supportedAPIVersion = "1.0"
		static let supportedForecastAPIVersion = "1.0"
		static let useStagingAPI = false
	}

	struct URL {
		static let apiBaseURL = "http://api.parkendd.de/"
		static let apiBaseURLStaging = "https://staging-park-api.higgsboson.tk/"
		static let nominatimURL = "https://nominatim.openstreetmap.org/"
	}

	/**
	GET the metadata (API version and list of supported cities) from server

	- parameter completion: handler that is provided with a list of supported cities or an error wrapped in an SCResult
	*/
	static func sendMetadataRequest(_ completion: @escaping (Metadata?, SCError?) -> Void) {
		let metadataURL = SCOptions.useStagingAPI ? URL.apiBaseURLStaging : URL.apiBaseURL
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		Alamofire.request(.GET, metadataURL).responseJSON { (_, response, result) -> Void in
			UIApplication.sharedApplication().networkActivityIndicatorVisible = false
			guard let response = response else { completion(nil, .Request); return }
			guard response.statusCode == 200 else { completion(nil, .Server); return }
			guard let data = result.value else { completion(nil, .Server); return }
			
			let metadata = Mapper<Metadata>().map(data)
			
			// TODO: I have a feeling that this will die mapping the data before being able to check the version if something substantial changes...
			guard metadata?.apiVersion == SCOptions.supportedAPIVersion else {
				NSLog("Error: Found API Version \(metadata!.apiVersion). This version of ParkenDD can however only understand \(SCOptions.supportedAPIVersion)")
				completion(nil, .IncompatibleAPI)
				return
			}
			
			completion(metadata, nil)
		}
	}

	/**
	Get the current data for all parkinglots

	- parameter completion: handler that is provided with a list of parkinglots or an error wrapped in an SCResult
	*/
	static func sendParkinglotDataRequest(_ city: String, completion: @escaping (ParkinglotData?, SCError?) -> Void) {
		let parkinglotURL = SCOptions.useStagingAPI ? URL.apiBaseURLStaging + city : URL.apiBaseURL + city
		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		Alamofire.request(.GET, parkinglotURL).responseJSON { (_, response, result) -> Void in
			UIApplication.sharedApplication().networkActivityIndicatorVisible = false
			guard let response = response else { completion(nil, .Request); return }
			if response.statusCode == 404 { completion(nil, .NotFound); return }
			guard response.statusCode == 200 else { completion(nil, .Server); return }
			guard let data = result.value else { completion(nil, .Server); return }
			
			let parkinglotData = Mapper<ParkinglotData>().map(data)
			completion(parkinglotData, nil)
		}
	}
	
	static func updateDataForSavedCity(_ completion: @escaping (APIResult?, SCError?) -> Void) {
		sendMetadataRequest { (metaData, metaError) -> Void in
			if let metaError = metaError {
				completion(nil, metaError)
				return
			}
			
			let currentCity = UserDefaults.standard.string(forKey: Defaults.selectedCity)!
			sendParkinglotDataRequest(currentCity, completion: { (parkinglotData, parkinglotError) -> Void in
				if let parkinglotError = parkinglotError {
					completion(nil, parkinglotError)
					return
				}
				
				let apiResult = APIResult(metadata: metaData!, parkinglotData: parkinglotData!)
				completion(apiResult, nil)
			})
		}
	}

	/**
	Get forecast data for a specified parkinglot and date

	- parameter lotID:      id of a parkinglot
	- parameter fromDate:   date object when the data should start
	- parameter toDate:     date object when the data should end
	- parameter completion: handler
	*/
	static func sendForecastRequest(_ lotID: String, fromDate: Date, toDate: Date, completion: @escaping (ForecastData?, SCError?) -> Void) {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
		let fromDateString = dateFormatter.string(from: fromDate)
		let toDateString = dateFormatter.string(from: toDate)

		let parameters = [
			"from": fromDateString,
			"to": toDateString
		]

		UIApplication.shared.isNetworkActivityIndicatorVisible = true
		let forecastURL = SCOptions.useStagingAPI ? URL.apiBaseURLStaging + "/Dresden/\(lotID)/timespan" : URL.apiBaseURL + "/Dresden/\(lotID)/timespan"
		Alamofire.request(.GET, forecastURL, parameters: parameters).responseJSON { (_, response, result) -> Void in
			UIApplication.sharedApplication().networkActivityIndicatorVisible = false
			guard let response = response else { completion(nil, .Request); return }
			if response.statusCode == 404 { completion(nil, .NotFound); return }
			guard response.statusCode == 200 else { completion(nil, .Server); return }
			guard let data = result.value else { completion(nil, .Server); return }
			
			let forecastData = Mapper<ForecastData>().map(data)
			
			guard let fData = forecastData?.data else { completion(nil, .Server); return }
			
			if fData.isEmpty {
				completion(nil, .NoData)
				return
			}
			
			completion(forecastData, nil)
		}
	}
	
	/**
	Get forecast data for a specified parkinglot and one week from a starting date
	
	- parameter lotID:      id of a parkinglot
	- parameter fromDate:   date object when the data should start
	- parameter completion: handler
	*/
	static func forecastWeek(_ lotID: String, fromDate: Date, completion: @escaping (ForecastData?, SCError?) -> Void) {
		let toDate = fromDate.addingTimeInterval(3600*24*7)
		sendForecastRequest(lotID, fromDate: fromDate, toDate: toDate) { (forecastData, error) -> Void in
			completion(forecastData, error)
		}
	}
	
	static func forecastDay(_ lotID: String, fromDate: Date, completion: @escaping (ForecastData?, SCError?) -> Void) {
		let startOfDay = Calendar.current.startOfDay(for: fromDate)
		let endOfDay = startOfDay.addingTimeInterval(3600*24)
		sendForecastRequest(lotID, fromDate: startOfDay, toDate: endOfDay) { (forecastData, error) -> Void in
			completion(forecastData, error)
		}
	}
}
