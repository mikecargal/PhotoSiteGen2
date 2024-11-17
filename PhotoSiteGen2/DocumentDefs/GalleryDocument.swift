//
//  CategoryDocument.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import Foundation

struct GalleryDocument: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var directory: String
    var titleImageName: String = ""
    var categories = [String]()

    func gallerySourceUrl(webSiteDocument: WebSiteDocument) -> URL {
        URL(fileURLWithPath: directory, relativeTo: webSiteDocument.sourceFolder)
//        webSiteDocument.sourceFolder!
//            .appendingPathComponent("galleries")
//            .appendingPathComponent(directory)
    }

    func titleImageUrl(webSiteDocument: WebSiteDocument) -> URL? {
        guard !titleImageName.isEmpty else { return nil }
        return gallerySourceUrl(webSiteDocument: webSiteDocument)
            .appendingPathComponent(titleImageName)
    }

    static let mock = GalleryDocument(
        title: "Mock Gallery", directory: "mock", categories: ["tag1", "tag2"])
}
