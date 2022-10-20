//
//  StorageHelper.swift
//  Bonjur Printer Generator
//
//  Created by Giovanni Trovato on 18/10/22.
//

import Foundation

extension Decodable {
    init(from url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        self = try decoder.decode(Self.self, from: data)
    }
}

extension Encodable {
    func save(to url: URL) throws {
        guard let jsonStr else {
            throw StorageError.unableToSave("cannot convert object to string")
        }
        
        try jsonStr.write(to: url, atomically: true, encoding: .utf8)
    }
    
    private var jsonStr: String? {
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        
        guard
            let jsonData = try? jsonEncoder.encode(self),
            let jsonString = String(data: jsonData, encoding: .utf8)
        else {
            return nil
        }
        
        return jsonString
    }
}
