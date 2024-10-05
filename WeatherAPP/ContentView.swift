//
//  ContentView.swift
//  WeatherAPP
//
//  Created by Monique Ferrarini on 24/09/24.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
	
	@State var query: String = ""
//	@State var humidity: Double = 80
	
	@State var sunriseEpochTime = TimeInterval(1727427028)
	@State var sunsetEpochTime = TimeInterval(1727471050)
	
	@State var weatherData: WeatherData?

		
	var body: some View {
		
		
// como vou mudar o nome da cidade?
		//como mudar o icone?
		
		
		ZStack{
			
			LinearGradient(colors: [Color(#colorLiteral(red: 0, green: 0.3975753784, blue: 0.6990576386, alpha: 1)), Color(#colorLiteral(red: 0, green: 0.5309305787, blue: 0.7453615069, alpha: 1)), Color.white], startPoint: .top, endPoint: .bottom)
				.ignoresSafeArea()
			
			VStack{
				
				if let weatherData = weatherData {
					let speed = weatherData.wind.speed
					let temp = weatherData.main.temp
					let tempMin = weatherData.main.tempMin
					let tempMax = weatherData.main.tempMax
					let humidity = weatherData.main.humidity
					let sunrise = Date(timeIntervalSince1970: weatherData.sys.sunrise)
					let sunset = Date(timeIntervalSince1970: weatherData.sys.sunset)
					let description = weatherData.weather[0].description
					
					SearchBar(locationService: LocationService())
					
					
					Text(" \(speed, specifier: "%.2f") m/s")
					Text("\(tempMin, specifier: "%.f")°")
					Text(sunrise, format: Date.FormatStyle().hour().minute())
					
					
					
					CityPlusResume(description: description)
					
					
					ActualClimateCard(tempMin: tempMin, tempMax: tempMax)
					
				
				
				HStack{
					
					HumidityCard(humidity : humidity)
					
					
					SunriseAndSunset(sunriseEpochTime: sunriseEpochTime, sunsetEpochTime: sunsetEpochTime)
					
					
					
				}
					
				} else {
					
					Text("Getting Data")
						.font(.largeTitle)
						.foregroundStyle(.gray)
				}
				
				
				Spacer()
				
				//monospacedigit for numbers
				// umidade e velocidade dos ventos
				
					.onAppear{
						callAPI()
					}
				
			}
			
		}
		
		
	}
	
	func callAPI() {
		
		guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=-23.550520&lon=-46.633308&appid=32a4b19cf3a447e6ed4ffb5c9a56dc77&units=metric") else { return }
		
		URLSession.shared.dataTask(with: url) { data, response, error in
			guard let data = data else {
				print("no data")
				return
			}
			
			guard error == nil else {
				print("error: \(String(describing: error?.localizedDescription))")
				return
			}
			
			guard let response = response as? HTTPURLResponse else {
				print("invalid response")
				return
			}
			
			guard response.statusCode >= 200 && response.statusCode < 300 else {
				print("Status code should be 2xx, but is \(response.statusCode) ")
				return
			}
			
			print("Sucessfully donwloaded data!")
			print(data)
			
			guard let weatherData = try? JSONDecoder().decode(WeatherData.self, from: data) else { return }
			print("Decoded WeatherData: \(weatherData)")
			DispatchQueue.main.async {
				self.weatherData = weatherData
			}
			
		}.resume()
		
	}
	
		
}

#Preview {
	ContentView()
}

struct ActualClimateCard: View {
	var tempMin: Double
	var tempMax: Double
	
	var body: some View {
		VStack{
			
			
			HStack {
				
				Spacer()
				
				Image(systemName: "sun.max.fill")
					.foregroundStyle(.yellow)
					.font(.system(size: 80))
					.padding()
				
				Spacer()
				
				VStack{
					HStack {
						Image(systemName: "thermometer.low")
							.font(.system(size: 30))
							.symbolRenderingMode(.multicolor)
						
						Text("Mín:")
						
						Text("\(tempMin, specifier: "%.f")°").monospacedDigit()
					}
					
					HStack {
						Image(systemName: "thermometer.high")
							.font(.system(size: 30))
							.symbolRenderingMode(.multicolor)
						
						Text("Max:")
						Text("\(tempMax, specifier: "%.f")°").monospacedDigit()
						
					}
				}
				.padding()
				Spacer()
				
				
			} 	.background(.ultraThinMaterial, in:
								RoundedRectangle(cornerRadius: 20)
				)
				.padding(.horizontal)
			
		}
	}
}

struct SearchBar: View {
	@ObservedObject var locationService: LocationService
	@FocusState private var searchFieldIsFocused: Bool
	@State var selectedCity: String = ""
	let geocoder = CLGeocoder()
	
	@State var weatherData: WeatherData?

	
	var body: some View {
		VStack {
			TextField("Search", text: $locationService.queryFragment)
				.focused($searchFieldIsFocused)
				.padding()
				.background(
					RoundedRectangle(cornerRadius: 15)
						.fill(.white)
				)
				.padding()
				.onChange(of: locationService.queryFragment) { newValue in
					withAnimation {
						searchFieldIsFocused = !newValue.isEmpty
					}
				}
		}
		.overlay {
			if  !locationService.queryFragment.isEmpty || searchFieldIsFocused {
				
				
				List {
					if locationService.status == .noResults {
						Text("No Results")
							.foregroundColor(Color.gray)
					} else if case .error(let description) = locationService.status {
						Text("Error: \(description)")
							.foregroundColor(Color.red)
					} else {
						ForEach(locationService.searchResults, id: \.self) { completionResult in
							Text(completionResult.title)
								.onTapGesture {
									selectedCity = completionResult.title
									print("Selected location: \(selectedCity)")
									searchFieldIsFocused = false
									locationService.queryFragment = ""
									
									getCoordinates(for: selectedCity) { coordinate in
										if let coordinate = coordinate {
											print("Coordinate for \(selectedCity): \(coordinate.latitude), \(coordinate.longitude)")
										} else {
											print("Could not get coordinates for \(selectedCity).")
										}
									}
									
									callAPI()
									
								}
							

						}
					}
					
				}
				.scrollContentBackground(.hidden)
				.frame(height: 300)
				.offset(y: 180)
				
				
				
			}
		} .zIndex(1)
	}
	
	func callAPI() {
		
		guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=-23.550520&lon=-46.633308&appid=32a4b19cf3a447e6ed4ffb5c9a56dc77") else { return }
		
		URLSession.shared.dataTask(with: url) { data, response, error in
			guard let data = data else {
				print("no data")
				return
			}
			
			guard error == nil else {
				print("error: \(String(describing: error?.localizedDescription))")
				return
			}
			
			guard let response = response as? HTTPURLResponse else {
				print("invalid response")
				return
			}
			
			guard response.statusCode >= 200 && response.statusCode < 300 else {
				print("Status code should be 2xx, but is \(response.statusCode) ")
				return
			}
			
			print("Sucessfully donwloaded data!")
			print(data)
			
			guard let weatherData = try? JSONDecoder().decode(WeatherData.self, from: data) else { return }
			print("Decoded WeatherData: \(weatherData)")
			DispatchQueue.main.async {
				self.weatherData = weatherData
			}
			
		}.resume()
		
	}
	
	func getCoordinates(for address: String, completion: @escaping (CLLocationCoordinate2D?) -> Void) {
		geocoder.geocodeAddressString(address) { placemarks, error in
			if let error = error {
				print("Geocoding error: \(error.localizedDescription)")
				completion(nil)
				return
			}

			if let location = placemarks?.first?.location {
				completion(location.coordinate)
			} else {
				completion(nil)
			}
		}
	}
	
}

struct CityPlusResume: View {
	
	var description: String
	
	var body: some View {
		VStack {
			Text("Sao paulo")
				.font(.custom("SFCompactRounded", size: 30))
				.foregroundStyle(.white)
			
			Text("\(description)")
				.italic()
				.padding(.bottom)
				.foregroundStyle(.white)
			
		}
		.frame(maxWidth: .infinity)
		.padding(.vertical)
		.zIndex(0)
	}
}

struct HumidityCard: View {
	
	var humidity: Double
	
	var body: some View {
		
		VStack{
			Text("Umidade do ar:")
				.font(.headline)
			
			Text("\(humidity, specifier: "%.f")%")
				.monospacedDigit()
				.font(.largeTitle)
			
			ProgressView(value: humidity, total: 100)

				.tint(Color.blue)
				.padding(.horizontal)
		}
		
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 20)
				.fill(.ultraThinMaterial)
		) .padding()
	}
}

struct SunriseAndSunset: View {
	
	@State var sunriseEpochTime : TimeInterval
	@State var sunsetEpochTime : TimeInterval
	
	var body: some View {
		
		let sunriseDate = Date(timeIntervalSince1970: sunriseEpochTime)
		let sunsetDate = Date(timeIntervalSince1970: sunsetEpochTime)
		
		VStack{
			
			
			HStack{
				Image(systemName: "sunrise")
					.font(.largeTitle)
					.symbolRenderingMode(.palette)
					.foregroundStyle(.yellow, .orange)
				
				Text(sunriseDate, format: Date.FormatStyle().hour().minute())
					.monospacedDigit()
				
			} .padding(.bottom)
			
			HStack{
				Image(systemName: "sunset")
					.font(.largeTitle)
					.symbolRenderingMode(.palette)
					.foregroundStyle(.yellow, .orange)
				
				Text(sunsetDate, format: Date.FormatStyle().hour().minute())
					.monospacedDigit()
			}
			
		} .padding()
			.padding(.horizontal)
			.background(
				RoundedRectangle(cornerRadius: 20)
					.fill(.ultraThinMaterial)
				
			) .padding(.trailing)
	}
}

