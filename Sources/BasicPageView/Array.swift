//
//  Array.swift
//
//
//  Created by Darshan S on 11/02/24.
//

import Foundation

extension Array {
    subscript (safe index: Int) -> Element? {
        guard index >= 0 && index < self.count else {
            return nil
        }
        return self[index]
    }
}
