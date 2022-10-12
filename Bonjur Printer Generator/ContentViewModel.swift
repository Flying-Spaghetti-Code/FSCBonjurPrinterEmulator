//
//  ContentViewModel.swift
//  Bonjur Printer Generator
//
//  Created by Giovanni Trovato on 11/10/22.
//

import Foundation



class ContentViewModel: ObservableObject {
    @Published var servers: [BonjourServer] = []
    @Published var name: String = ""
    @Published var manufacturer: String = ""
    @Published var model: String = ""
    
    var addingDisabled : Bool {
        name.isEmpty || manufacturer.isEmpty || model.isEmpty
    }
    
    func didTapAdd() {
        let server = BonjourServer(name: name, manifacturer: manufacturer, model: model)
        servers.append(server)
    }
    
    func didTapRemove() {
        
    }
    
    func didTapStart() {
        let port = findFreePort()
        
    }
    
    func didTapStop() {
        
    }
    
    
    private func findFreePort() -> UInt16 {
        var port: UInt16 = 8000;

        let socketFD = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
        if socketFD == -1 {
          //print("Error creating socket: \(errno)")
          return port;
        }

        var hints = addrinfo(
          ai_flags: AI_PASSIVE,
          ai_family: AF_INET,
          ai_socktype: SOCK_STREAM,
          ai_protocol: 0,
          ai_addrlen: 0,
          ai_canonname: nil,
          ai_addr: nil,
          ai_next: nil
        );

        var addressInfo: UnsafeMutablePointer<addrinfo>? = nil;
        var result = getaddrinfo(nil, "0", &hints, &addressInfo);
        if result != 0 {
          //print("Error getting address info: \(errno)")
          close(socketFD);

          return port;
        }

        result = Darwin.bind(socketFD, addressInfo!.pointee.ai_addr, socklen_t(addressInfo!.pointee.ai_addrlen));
        if result == -1 {
          //print("Error binding socket to an address: \(errno)")
          close(socketFD);

          return port;
        }

        result = Darwin.listen(socketFD, 1);
        if result == -1 {
          //print("Error setting socket to listen: \(errno)")
          close(socketFD);

          return port;
        }

        var addr_in = sockaddr_in();
        addr_in.sin_len = UInt8(MemoryLayout.size(ofValue: addr_in));
        addr_in.sin_family = sa_family_t(AF_INET);

        var len = socklen_t(addr_in.sin_len);
        result = withUnsafeMutablePointer(to: &addr_in, {
          $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            return Darwin.getsockname(socketFD, $0, &len);
          }
        });

        if result == 0 {
          port = addr_in.sin_port;
        }

        Darwin.shutdown(socketFD, SHUT_RDWR);
        close(socketFD);

        return port;
    }

}


