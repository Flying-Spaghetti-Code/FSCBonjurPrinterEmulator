//
//  Printer.swift
//  Bonjur Printer Generator
//
//  Created by Giovanni Trovato on 18/10/22.
//

import Foundation

enum StorageError: Error {
    case unableToSave(String)
    case unableToLoad(String)
}

public struct Printer: Codable {
    
    var name: String = ""
    var manufacturer: String?
    var model: String?
    
    var manufacturerText: String {
        guard let manufacturer , !manufacturer.isEmpty else { return "[Empty!]" }
        return manufacturer
    }
    
    var modelText: String {
        guard let model , !model.isEmpty else { return "[Empty!]" }
        return model
    }
    
}
