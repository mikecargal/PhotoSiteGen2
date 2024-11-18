//
//  Extensions.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 7/15/24.
//

import Foundation


extension Sequence {
    func asyncMap<T>(
        _ transform: (Element) async throws -> T
    ) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
}

