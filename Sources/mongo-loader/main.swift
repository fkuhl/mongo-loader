import Foundation

public let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
}()

public let jsonDecoder: JSONDecoder = {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .formatted(dateFormatter)
    return d
}()

print("starting...")

guard let url = URL(string: "file:///Users/fkuhl/Desktop/members.json") else {
    NSLog("URL failed")
    exit(1)
}
do {
    let data = try Data(contentsOf: url)
    let dataSet = try jsonDecoder.decode(DataSet.self, from: data)
    NSLog("\(dataSet.members.count) mem, \(dataSet.households.count) households, \(dataSet.addresses.count) addrs")
} catch {
    NSLog("error: \(error)")
}



