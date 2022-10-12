import Foundation

public protocol PrinterFinder: NSObject, NetServiceBrowserDelegate, NetServiceDelegate{
    func search(callback: @escaping ([NearbyPrinter])->())
    func stop()
}

public class NearbyPrinter {
    public var name: String
    public var driver: Driver?
    public var wifiSSID: String?
    public var wifiBSSID: String?
    
    init(with name: String) {
        self.name = name
    }
}

public class Driver: Codable {
    var model: String?
    var driver: String?
}

public class NetPrinterFinder: NSObject, PrinterFinder{
    
    private var discovered: (([NearbyPrinter]) -> ())?
    private var browser: NetServiceBrowser
    private var services = [NetService]()
    
    public override init() {
        browser = NetServiceBrowser()
        super.init()
        browser.delegate = self
    }
    
    public func search(callback: @escaping ([NearbyPrinter]) -> ()) {
        startDiscovery()
        discovered = callback
    }
    
    public func stop() {
        browser.stop()
    }
    
    private func addService(_ service: NetService){
        let printer = NearbyPrinter(with: service.name)
        discovered?([printer])
        services.append(service)
    }
    
    private func startDiscovery() {
        // Make sure to reset the last known service if we want to run this a few times
        services = []
        
        // Start the discovery
        browser.stop()
        browser.searchForServices(ofType: "_pdl-datastream._tcp.", inDomain: "")
    }
    
    // MARK: Service discovery
    
    public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
        print("Search about to begin")
    }
    
    public func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        print("Resolve error:", sender, errorDict)
    }
    
    public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        print("Search stopped")
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind svc: NetService, moreComing: Bool) {
        
        addService(svc)
        svc.delegate = self
        svc.resolve(withTimeout: 5)
        
        guard moreComing else {
            print("No more printers")
            browser.stop()
            return
        }
    }
    
    public func netServiceDidResolveAddress(_ sender: NetService) {
        print("Resolved service")
        
        if let serviceIp = resolveIPv4(addresses: sender.addresses!) {
            print("Found IPV4:", serviceIp)
        } else {
            print("Did not find IPV4 address")
        }
        
        if let data = sender.txtRecordData() {
            let dict = NetService.dictionary(fromTXTRecord: data)
            for element in dict{
                print("\(element.key): \(String(decoding: element.value, as: UTF8.self))")
            }
        }
    }
    
    private func resolveIPv4(addresses: [Data]) -> String? {
        var result: String?
        
        for addr in addresses {
            let data = addr as NSData
            var storage = sockaddr_storage()
            data.getBytes(&storage, length: MemoryLayout<sockaddr_storage>.size)
            
            if Int32(storage.ss_family) == AF_INET {
                let addr4 = withUnsafePointer(to: &storage) {
                    $0.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
                        $0.pointee
                    }
                }
                
                if let ip = String(cString: inet_ntoa(addr4.sin_addr), encoding: .ascii) {
                    result = ip
                    break
                }
            }
        }
        
        return result
    }
}
