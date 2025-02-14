//
//  ContentView.swift
//  HomeTemp Watch App
//
//  Created by P. Kurt Thorderson on 12/29/23.
//

import SwiftUI

struct ContentView: View {
  @StateObject var weathersModel = WeathersModel()
  
  var body: some View {
    ZStack {
      Rectangle()
        .fill(
          RadialGradient(gradient: Gradient(colors: [.blue, .black]), center: .topTrailing, startRadius: 40, endRadius: 200)
        )
        .ignoresSafeArea()
      
      VStack {
        AsyncImage(url: URL(string: weathersModel.weatherIconURLtext)) { image in
          image.resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: 36, maxHeight: 36)
        } placeholder: {
          if weathersModel.isLoading {
            ProgressView()
          }
        }
        
        Text("Lake Blaine")
          .foregroundStyle(.yellow)
          .font(.system(.title2, design: .rounded))
        
        VStack {
          Text("\(weathersModel.tempPKT)°")
            .font(.custom("SF Compact", size: 40))
            .minimumScaleFactor(0.5)
          
          Text(weathersModel.written)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
          
          HStack(alignment: .top) {
            Spacer()
            VStack {
              Text("Today Hi:")
                .font(.custom("SF Compact", size: 12))
                .foregroundColor(.yellow)
              Text("\(weathersModel.todayHi)°")
                .font(.custom("SF Compact", size: 16))
                .foregroundColor(.white)
              Text("Today Lo:")
                .font(.custom("SF Compact", size: 12))
                .foregroundColor(.yellow)
              Text("\(weathersModel.todayLow)°")
                .font(.custom("SF Compact", size: 16))
                .foregroundColor(.white)
            }
            Spacer()
            VStack(alignment: .leading) {
              Text("Tomorrow:")
                .font(.custom("SF Compact", size: 12))
                .foregroundColor(.yellow)
              Text(weathersModel.tomorrowForecast)
                .font(.custom("SF Compact", size: 10))
                .foregroundColor(.white)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
          }.padding()
        }
      }
    }
    .task { await weathersModel.fetchForecast() }
    .refreshable { await weathersModel.fetchForecast() }
  }
}

// MARK: - WeathersModel
@MainActor
class WeathersModel: ObservableObject {
  @Published var tempPKT = 62
  @Published var weatherIconURLtext = ""
  @Published var written = ""
  @Published var tomorrowForecast = ""
  @Published var todayHi = 0
  @Published var todayLow = 0
  @Published var errorMessage: String? = nil
  @Published var isLoading: Bool = false
  
  let lakeBlaineIslandWeatherURLstring = "https://api.weather.com/v2/pws/observations/current?stationId=KMTKALIS104&format=json&units=e&apiKey=ec368a2dd896485fb68a2dd896f85fd3"
  let fiveDayForecastURLstring = "https://api.weather.com/v3/wx/forecast/daily/5day?postalKey=59901:US&units=e&language=en-US&format=json&apiKey=ec368a2dd896485fb68a2dd896f85fd3"
  let crestonWeatherURLstring = "https://api.weatherapi.com/v1/current.json?key=cb010fb25a8749be8fa75919233112&q=Creston,%20Montana&aqi=no)"
  
  func fetchForecast() async {
    isLoading = true
    defer { isLoading = false }
    guard let url = URL(string: lakeBlaineIslandWeatherURLstring),
          let forecastURL = URL(string: fiveDayForecastURLstring) else {
      errorMessage = "Invalid URL"
      return
    }
    
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      let (forecastData, _) = try await URLSession.shared.data(from: forecastURL)
      
      let myWeather = try JSONDecoder().decode(Weather.self, from: data)
      let forecast = try JSONDecoder().decode(Forecast.self, from: forecastData)
      
      if let firstObservation = myWeather.observations.first {
        self.tempPKT = firstObservation.imperial.temp
        
        
      }
      if let firstDaypart = forecast.daypart.first {


        // Extract tomorrow's forecast
        if let narratives = firstDaypart.narrative, narratives.count > 1, let validNarrative = narratives[1] {
              self.tomorrowForecast = validNarrative
          } else {
              self.tomorrowForecast = "No forecast available"
          }
          
          // Extract today's high and low temperature
        if let maxTemp = forecast.temperatureMax.first,
           let minTemp = forecast.temperatureMin.first {
          
              DispatchQueue.main.async {
                  self.todayHi = maxTemp
                  self.todayLow = minTemp
              }
          } else {
              print("Temperature data not available or incorrect format.")
              self.todayHi = 0
              self.todayLow = 0
          }
          
      }
    } catch {
      errorMessage = "Error loading data: \(error.localizedDescription)"
    }
  }
}

// MARK: - Models
struct Weather: Decodable {
  let observations: [Observation]
}

struct Observation: Decodable {
  let imperial: Imperial
}

struct Imperial: Decodable {
  let temp: Int
}

struct Forecast: Decodable {
  let daypart: [Daypart]
  let temperatureMax: [Int]
  let temperatureMin: [Int]
}

struct Daypart: Decodable {
  let narrative: [String?]?
  let calendarDayTemperatureMax: [Int?]?
  let calendarDayTemperatureMin: [Int?]?
}




//let lakeBlaineIslandWeatherURLstring = "https://api.weather.com/v2/pws/observations/current?stationId=KMTKALIS104&format=json&units=e&apiKey=ec368a2dd896485fb68a2dd896f85fd3"
//let fiveDayForecastURLstring = "https://api.weather.com/v3/wx/forecast/daily/5day?postalKey=59901:US&units=e&language=en-US&format=json&apiKey=ec368a2dd896485fb68a2dd896f85fd3"
//let crestonWeatherURLstring = "https://api.weatherapi.com/v1/current.json?key=cb010fb25a8749be8fa75919233112&q=Creston,%20Montana&aqi=no)"
