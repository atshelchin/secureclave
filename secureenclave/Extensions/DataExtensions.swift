//
//  DataExtensions.swift
//  secureenclave
//
//  Created by Assistant on 2025/9/5.
//

import Foundation

extension Data {
    /// Converts Data to hexadecimal string
    var hexString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
    
    /// Creates Data from hexadecimal string
    init?(hexString: String) {
        let hex = hexString.replacingOccurrences(of: " ", with: "")
        guard hex.count % 2 == 0 else { return nil }
        
        var data = Data()
        var index = hex.startIndex
        
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2)
            guard let byte = UInt8(hex[index..<nextIndex], radix: 16) else { return nil }
            data.append(byte)
            index = nextIndex
        }
        
        self = data
    }
}