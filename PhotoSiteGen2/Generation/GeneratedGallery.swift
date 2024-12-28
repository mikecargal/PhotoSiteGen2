//
//  Gallery.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 11/13/23.
//

import SwiftHtml
import Foundation

struct GeneratedGallery: Sendable, Codable {
    let favoritePhoto: Photo
    let categories: [String]?
    let title: String
    let name: String
    let sequenceNumber: Int
    let galleryID: UUID
    let photos: [Photo]
    
    var photoCache: [URL:Photo] {
        var cache: [URL:Photo] = [:]
        photos.forEach { cache[$0.url] = $0 }
        return cache
    }

    var imageNames: [String] {
        photos.map { $0.filteredFileNameWithExtension() }
    }
    
    func galleryLink(_ index: Int, thumbPct: Double) -> Tag {
        return GalleryLink()
            .attribute("linkTxt", String(title))
            .attribute("gallery", name)
            .attribute("categories", categories?.joined(separator: "|") ?? "")
            .attribute("imagesrc", favoritePhoto.filteredFileNameWithExtension())
            .attribute("ar", String(Float(favoritePhoto.aspectRatio)))
            .attribute("top", String((index / 3) * 200))
            .attribute("left", String((index % 3) * 200))
            .attribute("thumbPct", String("\(Float(thumbPct))%"))
            .class("brick")
    }
}
