import Foundation
import SwiftUI

public var usedPorts : [Int32] = []
public var basePort: Int32 = 9100

public enum ServerStatus{
    case running(port: Int32)
    case stopped
    case error(description: String)
    
    var description: String {
        switch self {
            case .running(let port): return "running, port: \(port)"
            case .stopped: return "stopped"
            case .error(let description): return "error (\(description))"
        }
    }
    
    var color: Color {
        switch self {
            case .running: return .green
            case .stopped: return .red
            case .error: return .orange
        }
    }
}

public class BonjourServer: NSObject, NetServiceDelegate, ObservableObject{
    
    var netService: NetService?
    
    var name: String
    var manifacturer: String
    var model: String
    var port: Int32 = basePort
    var isRunning = false {
        didSet {
            isRunning ? run() : teardown()
        }
    }
    
    @Published var status: ServerStatus
    
    public  init( name: String, manifacturer: String, model: String) {
        self.name = name
        self.manifacturer = manifacturer
        self.model = model
        self.status = .stopped
        super.init()
    }
    
    public func netServiceDidPublish(_ sender: NetService) {
        self.netService = sender
    }
    public func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        print("\(errorDict.description) port:\(port)")
        DispatchQueue.main.async{
            self.status = .error(description: errorDict.description)
        }
    }
    
    func setupServer(_ port: Int32,_ name: String,_ manifacturer: String,_ model: String) throws {
        
        if self.netService != nil {
            // Calling run() more than once should be a NOP.
            return
        } else {
            
            self.netService = NetService(domain: "local", type: "_pdl-datastream._tcp.", name: name, port: port )
            let dict = ["usb_MFG":manifacturer.data(using: .utf8)!,"usb_MDL":model.data(using: .utf8)!]
            let txtData = NetService.data(fromTXTRecord: dict)
            netService?.setTXTRecord(txtData)
            
            guard self.netService != nil else {
                self.teardown()
                throw NSError(domain: "BonjourServerErrorDomain", code: 4, userInfo: nil)
            }
            self.netService?.delegate = self
            
        }
    }
    
    public func run() {
        findFreePort()
        do {
            try self.setupServer(port, name, manifacturer, model)
            status = .running(port: port)
        } catch let thisError as NSError {
            status = .error(description: thisError.localizedDescription)
        }
        
        print(status.description)
        self.netService!.publish(options: .listenForConnections)
    }
    
    private func findFreePort(){
        // stupid algorithm at the moment please improve it
        
        port = basePort
        
        while usedPorts.contains(port) {
            port += 1
        }
        
        usedPorts.append(port)
    }
    
    public func stop() {
        isRunning = false
    }
    
    private func teardown() {
        
        usedPorts = usedPorts.filter {$0 != port}
        
        if self.netService != nil {
            self.netService!.stop()
            self.netService = nil
            self.status = .stopped
            print(status.description)
        }
    }
    
    deinit {
        self.teardown()
    }
    
}
