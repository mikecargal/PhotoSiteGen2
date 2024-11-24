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
    var webSite: Binding<WebSiteDocument>?
    private var genNameOverride: String?

    init(
        title: String,
        directory: String,
        titleImageName: String = "",
        categories: [String] = [String](),
        webSite: Binding<WebSiteDocument>?
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
        URL(
            fileURLWithPath: directory,
            relativeTo: webSite?.wrappedValue.sourceFolder)
    }

    var titleImageUrl: URL? {
        guard !titleImageName.isEmpty else { return nil }
        return gallerySourceUrl.appendingPathComponent(titleImageName)
    }

    func getGalleryGenerationInfo(_ sequenceNumber: Int)
        -> GalleryGenerationInfo
    {
        return .init(
            sequenceNumber: sequenceNumber,
            titleImageFileName: Photo.filteredFileNameWithExtension(
                titleImageUrl),
            title: title,
            genName: genName,
            categories: categories)
    }

    var genName: String {
        get {
            genNameOverride
                ?? String(directory.split(separator: "/").last ?? "")
        }
        set(newValue) {
            genNameOverride = newValue
        }
    }

    var csCategories: String {
        get {
            categories.joined(separator: ", ")
        }
        set(newValue) {
            categories = newValue.components(
                separatedBy: CharacterSet(charactersIn: ", ")
            ).filter { !$0.isEmpty }
        }
    }

    mutating func setGallerySourceTo(url: URL?) {
        guard let webSite else { return }
        guard let sourceFolder = webSite.wrappedValue.sourceFolder else {
            return
        }
        guard let path = url?.relativePath(from: sourceFolder) else { return }
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
        webSite: .constant(WebSiteDocument.mock))
}
