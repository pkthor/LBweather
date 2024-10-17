//  ContentView.swift
//  HomeTemp Watch App

import SwiftUI

struct ContentView: View {
  @StateObject var weathersModel = WeathersModel()
  
  var body: some View {
    ZStack {
      Rectangle()
        .fill(RadialGradient(
          gradient: Gradient(colors: [.blue, .black]),
          center: .topTrailing,
          startRadius: 40,
          endRadius: 200))
        .frame(width: 200, height: 200)
        .ignoresSafeArea()
      
      VStack {
        HStack {
          Spacer()
          AsyncImage(
            url: URL(string: weathersModel.weatherIconURLtext),
            content: { image in
              image.resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 36, maxHeight: 36)
            },
            placeholder: {
              ProgressView()
            }
          )
        }
        
        HStack {
          Text("Lake Blaine")
            .foregroundColor(.yellow)
            .font(.system(.title2, design: .rounded))
        }
        
        VStack {
          Text("\(weathersModel.tempPKT)°")
            .font(.custom("SF Compact", size: 60))
          
          Text(weathersModel.written)
          Spacer()
        }
      }
      .task {
        await weathersModel.reload()
      }
      .refreshable {
        await weathersModel.reload()
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}

// MARK: - Weather Model
struct Weather: Decodable {
  let observations: [Observation]
}

struct Observation: Codable {
  let imperial: Imperial
}

struct Imperial: Codable {
  let temp: Int
}

struct Stuff: Codable {
  let current: Current
}

struct Current: Codable {
  let condition: Condition
}

struct Condition: Codable {
  let text: String
  let icon: String
}

// MARK: - WeathersModel
@MainActor
class WeathersModel: ObservableObject {
  @Published var tempPKT = 62
  @Published var weatherIconURLtext = ""
  @Published var written = ""
  
  func reload() async {
    let weatherURL = "https://api.weather.com/v2/pws/observations/current?stationId=KMTKALIS104&format=json&units=e&apiKey=ec368a2dd896485fb68a2dd896f85fd3"
    let stuffURL = "https://api.weatherapi.com/v1/current.json?key=cb010fb25a8749be8fa75919233112&q=Creston,%20Montana&aqi=no"
    
    guard let weatherRequestURL = URL(string: weatherURL),
          let stuffRequestURL = URL(string: stuffURL) else {
      print("Invalid URLs")
      return
    }
    
    do {
      let (weatherData, _) = try await URLSession.shared.data(from: weatherRequestURL)
      let (stuffData, _) = try await URLSession.shared.data(from: stuffRequestURL)
      
      let weatherResponse = try JSONDecoder().decode(Weather.self, from: weatherData)
      let stuffResponse = try JSONDecoder().decode(Stuff.self, from: stuffData)
      
      if let observation = weatherResponse.observations.first {
        self.tempPKT = observation.imperial.temp
      }
      
      self.written = stuffResponse.current.condition.text
      self.weatherIconURLtext = "https:\(stuffResponse.current.condition.icon)"
      
    } catch {
      print("Failed to load weather data: \(error)")
    }
  }
}
