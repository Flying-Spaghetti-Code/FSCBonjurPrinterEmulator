import Foundation
import SwiftUI

public var usedPorts : [Int32] = []
public var basePort: Int32 = 9100

protocol BonjourServerRequestDelegate {
    func bonjourServerRequestDidFinish(_ request: BonjourServerRequest)
    func bonjourServerRequestDidReceiveError(_ request: BonjourServerRequest)
}

public class BonjourServerRequest: NSObject, StreamDelegate {
    
    var istr: InputStream
    var ostr: OutputStream
    var peerName: String
    var delegate: BonjourServerRequestDelegate?
    
    init(inputStream readStream: InputStream,
         outputStream writeStream: OutputStream,
         peer peerAddress: String,
         delegate anObject: BonjourServerRequestDelegate)
    {
        self.istr = readStream
        self.ostr = writeStream
        self.peerName = peerAddress
        self.delegate = anObject
    }
    
    func runProtocol() {
        
        self.istr.delegate = self
        self.istr.schedule(in: .current, forMode: .common)
        self.istr.open()
        self.ostr.delegate = self
        self.ostr.schedule(in: .current, forMode: .common)
        self.ostr.open()
    }
    
    public func stream(_ stream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasSpaceAvailable:
            if stream === self.ostr {
                if (stream as! OutputStream).hasSpaceAvailable {
                    // Send a simple no header response
                    self.sendResponse()
                }
            }
        case .hasBytesAvailable:
            if stream === self.istr {
                if let input = stream as? InputStream{
                    let data = Data(reading: input)
                    print(String(data: data, encoding: .utf8) ?? "no readable data")
                }
                self.istr.close()
            }
        case Stream.Event.errorOccurred:
            NSLog("stream: %@", stream)
            delegate?.bonjourServerRequestDidReceiveError(self)
        default:
            break
        }
    }
    
    func sendResponse() {
        let body = "I'm running"
        //### Seems the latest mobile Safari accepts only valid HTTP response...
        let header = "HTTP/1.1 200 OK\r\n" +
            "Content-Type: text/plain;\r\n" +
            "Content-Length: \(body.utf8.count)\r\n" +
        "\r\n"
        let response = (header+body).data(using: .utf8)!
        response.withUnsafeBytes {responseBytes in
            _ = self.ostr.write(responseBytes.bindMemory(to: UInt8.self).baseAddress!, maxLength: response.count)
        }
        self.ostr.close()
    }
    
    deinit {
        istr.remove(from: .current, forMode: .common)
        
        ostr.remove(from: .current, forMode: .common)
        
        
    }
    
}


extension Data {
    /**
     Consumes the specified input stream, creating a new Data object
     with its content.
     - Parameter reading: The input stream to read data from.
     - Note: Closes the specified stream.
     */
    init(reading input: InputStream) {
        self.init()
        input.open()
        
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        while input.hasBytesAvailable {
            let read = input.read(buffer, maxLength: bufferSize)
            self.append(buffer, count: read)
        }
        buffer.deallocate()
        
        input.close()
    }
    
    /**
        Consumes the specified input stream for up to `byteCount` bytes,
        creating a new Data object with its content.
        - Parameter reading: The input stream to read data from.
        - Parameter byteCount: The maximum number of bytes to read from `reading`.
        - Note: Does _not_ close the specified stream.
    */
    init(reading input: InputStream, for byteCount: Int) {
        self.init()
        input.open()

        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: byteCount)
        let read = input.read(buffer, maxLength: byteCount)
        self.append(buffer, count: read)
        buffer.deallocate()
    }
}

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

public class BonjourServer: NSObject, BonjourServerRequestDelegate, NetServiceDelegate, ObservableObject{
    var connectionBag: Set<BonjourServerRequest> = []
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
    
    
    public func netServiceWillPublish(_ sender: NetService) {
        print(#function)
    }
    public func netServiceDidPublish(_ sender: NetService) {
        print(#function, sender)
        self.netService = sender
    }
    public func netService(_ sender: NetService, didNotPublish errorDict: [String: NSNumber]) {
        print(errorDict.description)
        DispatchQueue.main.async{
            self.status = .error(description: errorDict.description)
        }
    }
    
    public func netService(_ sender: NetService, didAcceptConnectionWith readStream: InputStream, outputStream writeStream: OutputStream) {
        OperationQueue.main.addOperation {
            //### We cannot get client peer info here?
            let peer: String? = "Generic Peer"
            
            CFReadStreamSetProperty(readStream, CFStreamPropertyKey(kCFStreamPropertyShouldCloseNativeSocket), kCFBooleanTrue)
            CFWriteStreamSetProperty(writeStream, CFStreamPropertyKey(kCFStreamPropertyShouldCloseNativeSocket), kCFBooleanTrue)
            self.handleConnection(peer, inputStream: readStream, outputStream: writeStream)
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
        
        print(#function)
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
    
    func handleConnection(_ peerName: String?, inputStream readStream: InputStream, outputStream writeStream: OutputStream) {
        
        guard let peer = peerName else {
            fatalError("No peer name given for client.")
        }
        print("peer=",peer)
        let newPeer = BonjourServerRequest(inputStream: readStream,
            outputStream: writeStream,
            peer: peer,
            delegate: self)
        
        newPeer.runProtocol()
        self.connectionBag.insert(newPeer)
    }
    
    func bonjourServerRequestDidFinish(_ request: BonjourServerRequest) {
        self.connectionBag.remove(request)
    }
    
    func bonjourServerRequestDidReceiveError(_ request: BonjourServerRequest) {
        self.connectionBag.remove(request)
    }
    
    public func teardown() {
        
        usedPorts = usedPorts.filter {$0 != port}
        
        if self.netService != nil {
            self.netService!.stop()
            self.netService = nil
            self.status = .stopped
        }
    }
    
    deinit {
        self.teardown()
    }
    
}
