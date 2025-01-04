//
//  GenerationCache.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 12/27/24.
//

import Foundation

struct GenerationCache: Codable {
    let galleryPhotosCache: [UUID: [URL: Photo]]

    func photos(for galleryId: UUID) -> [URL: Photo]? {
        galleryPhotosCache[galleryId]
    }
}
