//
//  TSID.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 7/15/24.
//

import Foundation

struct TSID: Codable, Hashable, Sendable, CustomStringConvertible {
    var description: String

    init() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        description = formatter.string(from:  Date())
    }
}
