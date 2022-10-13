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
    
    func didTapRemove(_ server: BonjourServer) {
        if let index = servers.firstIndex(of: server) {
            server.stop()
            servers.remove(at: index)
        }
    }
    
    func didTapStartAll() {
        for server in servers {
            server.run()
        }
    }
    
    func didTapStopAll() {
        for server in servers {
            server.stop()
        }
    }
    
    func didTapClear() {
        didTapStopAll()
        servers.removeAll()
    }
    
}


