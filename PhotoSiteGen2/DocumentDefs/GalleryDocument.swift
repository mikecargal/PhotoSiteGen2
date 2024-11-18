//
//  CategoryDocument.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import Foundation
import SwiftUI

struct GalleryDocument: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var directory: String
    var titleImageName: String = ""
    var categories = [String]()
    var webSite: WebSiteDocument?

    init(
        title: String,
        directory: String,
        titleImageName: String = "",
        categories: [String] = [String](),
        webSite: WebSiteDocument?
    ) {
        self.title = title
        self.directory = directory
        self.titleImageName = titleImageName
        self.categories = categories
        self.webSite = webSite
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, directory, titleImageName, categories
    }

    var gallerySourceUrl: URL {
        URL(fileURLWithPath: directory, relativeTo: webSite?.sourceFolder)
    }

    var titleImageUrl: URL? {
        guard !titleImageName.isEmpty else { return nil }
        return gallerySourceUrl.appendingPathComponent(titleImageName)
    }

    mutating func setGallerySourceTo(url: URL) {
        guard let webSite else { return }
        guard let path = url.relativePath(from: webSite.sourceFolder) else {
            return
        }
        directory = path
    }
    
    static func == (lhs: GalleryDocument, rhs: GalleryDocument) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
            && lhs.directory == rhs.directory
            && lhs.titleImageName == rhs.titleImageName
            && lhs.categories == rhs.categories
    }
    
    static let mock = GalleryDocument(
        title: "Mock Gallery", directory: "mock", categories: ["tag1", "tag2"],
        webSite: WebSiteDocument.mock)
}
