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
                .frame(width: 200, height: 200)
                .ignoresSafeArea(.all)
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
                HStack{
                    Text("Lake Blaine")
                        .foregroundStyle(.yellow)
//                        .font(.headline)
                        .font(.system(.title2, design: .rounded))
//                    Image(systemName: "house")
//                        .imageScale(.large)
//                        .foregroundColor(.yellow)
                }
                VStack{
                    Text("\(weathersModel.tempPKT)°") //temperature value
                        .font(.custom(
                            "SF Compact",
                            size: 60))
                    Text(weathersModel.written) //description of weather condition
                    Spacer()
                }
            }
//            .padding()
            .task {
                await self.weathersModel.reload()
            }
            .refreshable {
                await self.weathersModel.reload()
            }
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
// MARK: - Weather
struct Weather:Decodable {
    let observations: [Observation]
}
// MARK: - Observation
struct Observation: Codable{
    let stationID: String
    let obsTimeUtc: String
    let obsTimeLocal: String
    let neighborhood: String
    let softwareType: String?
    let country: String
    let solarRadiation: Int?
    let lon: Double
    let realtimeFrequency: Int?
    let epoch: Int
    let lat: Double
    let uv: Int?
    let winddir: Int
    let humidity: Int
    let qcStatus: Int
    let imperial: Imperial
}
// MARK: - Observation
struct Imperial:Codable {
    let temp: Int
    let heatIndex: Int
    let dewpt: Int
    let windChill: Int
    let windSpeed: Int
    let windGust: Int
    let pressure: Double
    let precipRate: Double
    let precipTotal: Double
    let elev: Int
}
// MARK: - Stuff
struct Stuff: Codable {
    let location: Location
    let current: Current
}
// MARK: - Current
struct Current: Codable {
    let last_updated_epoch: Int
    let last_updated: String
    let temp_c, temp_f: Double
    let is_day: Int
    let condition: Condition
    let wind_mph, wind_kph: Double
    let wind_degree: Double
    let wind_dir: String
    let pressure_mb: Double
    let pressure_in, precip_mm, precip_in: Double
    let humidity, cloud: Double
    let feelslike_c: Double
    let feelslike_f: Double
    let vis_km, vis_miles, uv: Double
    let gust_mph: Double
    let gust_kph: Double
}

// MARK: - Condition
struct Condition: Codable {
    let text: String
    let icon: String
    let code: Int
}
// MARK: - Location
struct Location: Codable {
    let name: String
    let region: String
    let country: String
    let lat, lon: Double
    let tz_id: String
    let localtime_epoch: Int
    let localtime: String
}

@MainActor
class WeathersModel: ObservableObject {
    @Published var tempPKT = 62
    @Published var weatherIconURLtext = ""
    @Published var written = ""
    func reload() async {
        let url = URL(string: "https://api.weather.com/v2/pws/observations/current?stationId=KMTKALIS104&format=json&units=e&apiKey=ec368a2dd896485fb68a2dd896f85fd3")!
        let urlSession = URLSession.shared
        let url2 = URL(string: "https://api.weatherapi.com/v1/current.json?key=cb010fb25a8749be8fa75919233112&q=Creston,%20Montana&aqi=no)")!
        
        let urlSession2 = URLSession.shared
        do {
            let (data, _) = try await urlSession.data(from: url)
            let (data2, _) = try await urlSession2.data(from: url2)
            
            let myWeather = try JSONDecoder().decode(Weather.self, from: data)
            let myStuff = try JSONDecoder().decode(Stuff.self, from: data2)
            let dude = myWeather.observations
            let dude2 = myStuff.current.condition.text
            let dude3 = myStuff.current.condition.icon
            for item in dude {
                let homeTemp = item.imperial.temp
                self.tempPKT = homeTemp
            }
            self.written = dude2
            let dude4 = String("https:\(dude3)")
            self.weatherIconURLtext = dude4
        }
        catch {
            debugPrint("Error loading \(url2): \(String(describing: error))")
        }
    }
}


