//
//  Gallery.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 11/13/23.
//

import SwiftHtml

struct GeneratedGallery: Sendable {
    let favoritePhoto: Photo
    let categories: [String]?
    let title: String
    let name: String
    let sequenceNumber: Int
    
    func galleryLink(_ index: Int, thumbPct: Double) -> Tag {
        return GalleryLink()
            .attribute("linkTxt", String(title))
            .attribute("gallery", name)
            .attribute("categories", categories?.joined(separator: "|") ?? "")
            .attribute("imagesrc", favoritePhoto.filteredFileNameWithExtension())
            .attribute("ar", String(favoritePhoto.aspectRatio))
            .attribute("top", String((index / 3) * 200))
            .attribute("left", String((index % 3) * 200))
            .attribute("thumbPct", String("\(thumbPct)%"))
            .class("brick")
    }
}
