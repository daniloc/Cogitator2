//
//  DateFormatting.swift
//  Cogitator2
//
//  Created by Danilo Campos on 11/1/23.
//

import Foundation

extension Date {
    
    static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var shortString: String {
        return Self.formatter.string(from: self)
    }
    
}
