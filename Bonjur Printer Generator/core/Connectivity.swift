import Foundation


import Network

public class Connectivity{
    private static let monitor = NWPathMonitor()
    
    static var type : ConnectivityType = .noConnection
    
    
    public static func startMonitoring(){
        
        monitor.pathUpdateHandler = { path in
            
            if path.status != .satisfied {
                Connectivity.type = .noConnection
            }
            else if path.usesInterfaceType(.cellular) {
                Connectivity.type = .cellular
            }
            else if path.usesInterfaceType(.wifi) {
                Connectivity.type = .wifi
            }
            else if path.usesInterfaceType(.wiredEthernet) {
                Connectivity.type = .ethernet
            }
            print("[CONNECTIVITY]: type: \(Connectivity.type.rawValue)")
        }
        
        monitor.start(queue: DispatchQueue.global(qos: .background))
        
    }
    
    
}

enum ConnectivityType: String{
    case noConnection = "No connection"
    case cellular = "Cellular"
    case wifi = "WiFi"
    case ethernet = "Ethernet"
}
