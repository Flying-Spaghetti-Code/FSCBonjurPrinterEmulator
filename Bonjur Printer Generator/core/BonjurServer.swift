import Foundation

public var usedPorts : [Int] = []


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




public class BonjourServer: NSObject, BonjourServerRequestDelegate, NetServiceDelegate, ObservableObject{
    var connectionBag: Set<BonjourServerRequest> = []
    var netService: NetService?
    
    var name: String
    var manifacturer: String
    var model: String
    var port: Int32 = 9100
    
    
    
    public  init( name: String, manifacturer: String, model: String) {
        self.name = name
        self.manifacturer = manifacturer
        self.model = model
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
    
    public func run(port: Int32 = 9100) {
        do {
            try self.setupServer(port, name, manifacturer, model)
        } catch let thisError as NSError {
            fatalError(thisError.localizedDescription)
        }
        
        print(#function)
        self.netService!.publish(options: .listenForConnections)
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
        if self.netService != nil {
            self.netService!.stop()
            self.netService = nil
        }
    }
    
    deinit {
        self.teardown()
    }
    
}
