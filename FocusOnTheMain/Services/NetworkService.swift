import Foundation
import UIKit

class NetworkService {
    static let shared = NetworkService()
    
    private init() {}
    
    func fetchServerData(completion: @escaping (String?, String?) -> Void) {
        let osVersion = UIDevice.current.systemVersion
        let locale = Locale.preferredLanguages.first ?? "en-US"
        let languageCode = locale.components(separatedBy: "-").first ?? "en"
        let regionCode = locale.components(separatedBy: "-").last ?? "US"
        let deviceModel = getDeviceModel()
        
        let baseAddress = "https://wallen-eatery.space/ios-vdm-11/server.php"
        let parameters = "?p=Bs2675kDjkb5Ga&os=\(osVersion)&lng=\(languageCode)&devicemodel=\(deviceModel)&country=\(regionCode)"
        let fullAddress = baseAddress + parameters
        
        guard let endpoint = URL(string: fullAddress) else {
            completion(nil, nil)
            return
        }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil, nil)
                return
            }
            
            if let responseString = String(data: data, encoding: .utf8) {
                if responseString.contains("#") {
                    let components = responseString.components(separatedBy: "#")
                    let token = components[0]
                    let link = components.count > 1 ? components[1] : ""
                    completion(token, link)
                } else {
                    completion(nil, nil)
                }
            } else {
                completion(nil, nil)
            }
        }.resume()
    }
    
    private func getDeviceModel() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}

