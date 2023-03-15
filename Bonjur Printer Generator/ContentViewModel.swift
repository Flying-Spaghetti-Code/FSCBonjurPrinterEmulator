//
//  ContentViewModel.swift
//  Bonjur Printer Generator
//
//  Created by Giovanni Trovato on 11/10/22.
//

import Foundation
import AppKit


class ContentViewModel: ObservableObject {
    @Published var servers: [BonjourServer] = []
    @Published var name: String = ""
    @Published var manufacturer: String = ""
    @Published var model: String = ""
    
    var addingDisabled : Bool {
        name.isEmpty 
    }
    
    func didTapAdd() {
        let printer = Printer(name: name, manufacturer: manufacturer, model: model)
        let server = BonjourServer(printer)
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
    
    func didTapLoad(_ url: URL) {
        do {
            let list = try [Printer](from: url)
            servers = list.map{ BonjourServer($0)}
        } catch let error {
            print("error on loading from file \(error.localizedDescription)")
        }
    }
    
    func didTapSave(_ url: URL) {
        let printers = servers.map { $0.printer }
        do {
            try printers.save(to: url)
        }catch let error {
            print("error on saving \(error.localizedDescription)")
        }
    }
    
    func didTapClear() {
        didTapStopAll()
        servers.removeAll()
    }
    
    func showSavePanel() -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.json]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowsOtherFileTypes = false
        savePanel.title = "Save the printer list"
        savePanel.message = "Choose a folder and a name to store the list"
        savePanel.nameFieldLabel = "File name:"
        let response = savePanel.runModal()
        return response == .OK ? savePanel.url : nil
    }
    
    
    func showOpenPanel() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        let response = openPanel.runModal()
        return response == .OK ? openPanel.url : nil
    }
    
}


