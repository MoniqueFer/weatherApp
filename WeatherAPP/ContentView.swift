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
	
	@StateObject var viewModel = TestViewModel()


	
	
	var body: some View {
		
		ZStack{
			
			LinearGradient(colors: [Color(#colorLiteral(red: 0, green: 0.3975753784, blue: 0.6990576386, alpha: 1)), Color(#colorLiteral(red: 0, green: 0.5309305787, blue: 0.7453615069, alpha: 1)), Color.white], startPoint: .top, endPoint: .bottom)
				.ignoresSafeArea()
			
			VStack{
				
				if let weatherData = viewModel.weatherData {
					let speed = weatherData.wind.speed
					let convertedSpeed = (speed * 3600) / 1000
					let temp = weatherData.main.temp
					let tempMin = weatherData.main.tempMin
					let tempMax = weatherData.main.tempMax
					let humidity = weatherData.main.humidity
					let sunrise = Date(timeIntervalSince1970: weatherData.sys.sunrise)
					let sunset = Date(timeIntervalSince1970: weatherData.sys.sunset)
					let description = weatherData.weather[0].description
					let name = weatherData.name
					let weatherId = weatherData.weather[0].id
					
					SearchBar(locationService: LocationService(), viewModel: viewModel)
					
					CityPlusResume(description: description, name: name)
					
					ActualClimateCard(temp: temp, weatherId: weatherId)
					
					HStack{
						
						CardTemp(tempMin: tempMin, tempMax: tempMax)
						
						HumidityCard(humidity : humidity)
						
						
					}
					
					HStack {
						
						SunriseAndSunset(sunrise: sunrise, sunset: sunset)
						
						WindCard(convertedSpeed : convertedSpeed)
						
					}
					
					.padding(.vertical)
					
					
				} else {
					
					Text("Getting Data")
						.font(.largeTitle)
						.foregroundStyle(.gray)
				}
				
				Spacer()
				
				//monospacedigit for numbers
				
					.onAppear{
						viewModel.callAPI(lat: -23.5489, lon: -46.6388)

							
							

					}
				
			}
			
		}
		
		
	}
	
	
	
	
	
}

//#Preview {
//	ContentView()
//}

struct ActualClimateCard: View {
	
	var temp : Double
	var weatherId: Int
	
	
	var body: some View {
		VStack{
			
			
			HStack {
				
				Spacer()
				
				
				IconWeather().getIcon(weatherIconID: weatherId)
					.font(.system(size: 80))
					.padding()
				
				Spacer()
				
				Text("\(temp, specifier: "%.f")°C").monospacedDigit()
					.font(.system(size: 50))
					.foregroundStyle(.white)
					.shadow(radius: 5)
				
				Spacer()
				
				
			} 	.background(.thinMaterial, in:
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
	
	
	@ObservedObject var viewModel: TestViewModel
	
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
									
									TestViewModel().getCoordinates(for: selectedCity) { coordinate in
										if let coordinate = coordinate {
											print("Coordinate for \(selectedCity): \(coordinate.latitude), \(coordinate.longitude)")
											
											viewModel.callAPI(lat: coordinate.latitude, lon: coordinate.longitude)

											
										} else { print("Could not get coordinates for \(selectedCity).")
											
										}
										
										
									}
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
	

	
}

struct CityPlusResume: View {
	
	var description: String
	var name : String
	
	var body: some View {
		VStack {
			Text(name)
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
		.frame(height: 100)
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 20)
				.fill(.thinMaterial))
		.padding(.horizontal)
	}
}

struct SunriseAndSunset: View {
	
	var sunrise : Date
	var sunset : Date
	
	var body: some View {
		
		VStack{
			
			
			HStack{
				Image(systemName: "sunrise")
					.symbolRenderingMode(.palette)
					.foregroundStyle(.yellow, .orange)
					.font(.system(size: 33))
				
				
				Text(sunrise, format: Date.FormatStyle().hour().minute())
					.monospacedDigit()
				
			} .padding(.bottom)
			
			HStack{
				Image(systemName: "sunset")
					.symbolRenderingMode(.palette)
					.foregroundStyle(.yellow, .orange)
					.font(.system(size: 33))
				
				Text(sunset, format: Date.FormatStyle().hour().minute())
					.monospacedDigit()
			}
			
		}
		.frame(height: 100)
		.font(.system(size: 20))
		.padding()
		.padding(.horizontal)
		.background(
			RoundedRectangle(cornerRadius: 20)
				.fill(.thinMaterial)
			
		) .padding(.trailing)
		
	}
}

struct CardTemp: View {
	
	var tempMin: Double
	var tempMax: Double
	
	var body: some View {
		VStack{
			HStack {
				Image(systemName: "thermometer.low")
					.symbolRenderingMode(.multicolor)
				
				
				Text("\(tempMin, specifier: "%.f")°C").monospacedDigit()
			}
			
			HStack {
				Image(systemName: "thermometer.high")
					.symbolRenderingMode(.multicolor)
				
				Text("\(tempMax, specifier: "%.f")°C").monospacedDigit()
				
			}
		}
		
		.font(.system(size: 33))
		.frame(height: 100)
		
		.padding()
		.background(
			RoundedRectangle(cornerRadius: 20)
				.fill(.thinMaterial))
		.padding(.leading)
		
	}
}

struct WindCard: View {
	
	var convertedSpeed : Double
	
	var body: some View {
		VStack {
			HStack{
				Image(systemName: "wind")
					.foregroundStyle(.blue)
				
				Text(" \(convertedSpeed, specifier: "%.f") km/h")
			}
			.font(.system(size: 33))
			.frame(height: 100)
			.padding()
			
		}
		
		.background(
			RoundedRectangle(cornerRadius: 20)
				.fill(.thinMaterial))
		
	}
}

struct IconWeather {
	
	func getIcon(weatherIconID: Int) -> AnyView {
		var iconImage: any View
		if weatherIconID >= 801 || weatherIconID <= 804 {
			iconImage = Image(systemName: "cloud.fill")
				.foregroundStyle(.white)
		} else if weatherIconID >= 500 || weatherIconID <= 531 {
			iconImage = Image(systemName: "cloud.rain.fill")
				.symbolRenderingMode(.multicolor)
				.foregroundStyle(.white)
		} else if weatherIconID >= 701 || weatherIconID <= 799 {
			iconImage = Image(systemName: "aqi.medium")
				.foregroundStyle(.white)
		} else if weatherIconID >= 600 || weatherIconID <= 622 {
			iconImage = Image(systemName: "snowflake")
				.foregroundStyle(.white)
		} else if weatherIconID >= 300 || weatherIconID <= 321 {
			iconImage = Image(systemName: "cloud.drizzle.fill")
				.symbolRenderingMode(.multicolor)
				.foregroundStyle(.white)
		} else if weatherIconID >= 200 || weatherIconID <= 232 {
			iconImage = Image(systemName: "cloud.bolt.rain.fill")
				.symbolRenderingMode(.multicolor)
				.foregroundStyle(.white)
		} else {
			iconImage = Image(systemName: "sun.max.fill")
				.foregroundStyle(.yellow)
		}
		return AnyView(iconImage)
	}
	
	
	// sol pleno = sun.max.fill (800) ook
	// só nuvem = cloud.fill (801 a 804) ook
	// chuva = cloud.rain.fill (500 a 531) ook
	// nevoa = aqi.medium (701 a 799) ook
	// snow = snowflake (600 a 622) ook
	//garoa = cloud.drizzle.fill (300 a 321) ook
	// trovoada cloud.bolt.rain.fill (200 a 232)
	
}


public class TestViewModel: ObservableObject {
	
	
	@Published var weatherData: WeatherData?
	let geocoder = CLGeocoder()

	var currentCoordinate: CLLocationCoordinate2D?

	
	
		
	func callAPISearchBar() {
	   
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
			   let coordinate = location.coordinate
			   
			   completion(coordinate)
		   } else {
			   completion(nil)
		   }
	   }
   }
		
	func callAPI(lat: CLLocationDegrees, lon: CLLocationDegrees) {
		
		var components = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather?")!
		
//		https://api.openweathermap.org/data/2.5/weather?lat=-23.550520&lon=-46.633308&appid=32a4b19cf3a447e6ed4ffb5c9a56dc77"
	
		
		components.queryItems = [
			URLQueryItem(name: "lat", value: "\(lat)"),
			URLQueryItem(name: "lon", value: "\(lon)"),
			URLQueryItem(name: "appid", value: "32a4b19cf3a447e6ed4ffb5c9a56dc77"),
			URLQueryItem(name: "units", value: "metric"),
			URLQueryItem(name: "lang", value: "pt_br")
			
		]
		
		guard let url = components.url else {
			return
		}
		
		
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
				print("Status code should be 2xx, but is \(response.statusCode) \(url)")
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


