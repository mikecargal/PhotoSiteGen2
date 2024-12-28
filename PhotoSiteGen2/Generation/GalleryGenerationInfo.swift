//
//  GalleryGenerationInfo.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/18/24.
//

import Foundation

struct GalleryGenerationInfo {
    var galleryUUID: UUID
    var sequenceNumber: Int
    var titleImageFileName: String?
    var title: String
    var genName: String
    var categories: [String]
    var photosCache: [URL: Photo]
}
