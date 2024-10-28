//
//  DataModel.swift
//  WeatherAPP
//
//  Created by Monique Ferrarini on 27/09/24.
//

import Foundation
import Combine
import MapKit
import SwiftUI

//searchbar stuff

class LocationService: NSObject, ObservableObject {

	enum LocationStatus: Equatable {
		case idle
		case noResults
		case isSearching
		case error(String)
		case result
	}

	@Published var queryFragment: String = ""
	@Published private(set) var status: LocationStatus = .idle
	@Published private(set) var searchResults: [MKLocalSearchCompletion] = []

	private var queryCancellable: AnyCancellable?
	private let searchCompleter: MKLocalSearchCompleter!

	init(searchCompleter: MKLocalSearchCompleter = MKLocalSearchCompleter()) {
		self.searchCompleter = searchCompleter
		super.init()
		self.searchCompleter.delegate = self

		queryCancellable = $queryFragment
			.receive(on: DispatchQueue.main)
			// we're debouncing the search, because the search completer is rate limited.
			// feel free to play with the proper value here
			.debounce(for: .milliseconds(250), scheduler: RunLoop.main, options: nil)
			.sink(receiveValue: { fragment in
				self.status = .isSearching
				if !fragment.isEmpty {
					self.searchCompleter.queryFragment = fragment
				} else {
					self.status = .idle
					self.searchResults = []
				}
		})
	}
}

extension LocationService: MKLocalSearchCompleterDelegate {
	func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
		self.searchResults = completer.results
		self.status = completer.results.isEmpty ? .noResults : .result
	}

	func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
		self.status = .error(error.localizedDescription)
	}
}


//end searchbar stuff


//datamodel

struct WeatherData : Codable {
	let weather: [Weather]
	let main: Main
	let wind: Wind
	let sys : Sys
	let name: String
	
	init(weather: [Weather], main: Main, wind: Wind, sys: Sys, name: String) {
		self.weather = weather
		self.main = main
		self.wind = wind
		self.sys = sys
		self.name = name
	}
	
	init(from decoder: any Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.weather = try container.decode([Weather].self, forKey: .weather)
		self.main = try container.decode(Main.self, forKey: .main)
		self.wind = try container.decode(Wind.self, forKey: .wind)
		self.sys = try container.decode(Sys.self, forKey: .sys)
		self.name = try container.decode(String.self, forKey: .name)
	}
	
	
}
	

struct Weather: Codable {
	let main: String
	let description: String
	let id: Int
	
}

struct Main : Codable { // the code on the api is Main
	let temp: Double
	let tempMin: Double //the code on the api is temp_min
	let tempMax : Double //the code on the api is temp_max
	let humidity: Double

	
	//Coding Keys
	enum CodingKeys: String, CodingKey {
			case temp
			case tempMin = "temp_min"
			case tempMax = "temp_max"
			case  humidity
		}

}

struct Wind : Codable {
	let speed: Double
	
}

struct Sys : Codable {
	let sunrise: TimeInterval
	let sunset: TimeInterval
	
}




