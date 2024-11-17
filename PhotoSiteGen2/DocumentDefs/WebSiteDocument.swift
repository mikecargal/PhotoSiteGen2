//
//  WebSiteDoc.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct WebSiteDocument: FileDocument, Codable {
    static var readableContentTypes = [
        UTType(exportedAs: "com.mikecargal.photositegen2.website")
    ]

    var sourceFolder: URL = FileManager.default.homeDirectoryForCurrentUser
    var staticSiteFolder: URL = FileManager.default.homeDirectoryForCurrentUser
    var destinationFolder: URL = FileManager.default.homeDirectoryForCurrentUser
    var categories = [String]()
    var galleries = [GalleryDocument]()

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self = try JSONDecoder().decode(WebSiteDocument.self, from: data)
        }
    }

    init() {}

    mutating func adoptGalleries() {
        for (idx, _) in galleries.enumerated() {
            galleries[idx].webSite = self
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(self)
        return FileWrapper(regularFileWithContents: data)
    }

    mutating func ensureGalleryAt(directory: URL) {
        let relativeDirectory = directory.relativePath(from: sourceFolder)!
        guard !galleries.contains(where: { $0.directory == relativeDirectory })
        else {
            return
        }

        galleries.insert(
            GalleryDocument(
                title: relativeDirectory,
                directory: relativeDirectory,
                webSite: self), at: 0)

    }

    static let mock: WebSiteDocument = {
        var doc = WebSiteDocument()
        doc.sourceFolder = .init(fileURLWithPath: "Source")
        doc.staticSiteFolder = .init(fileURLWithPath: "StaticSite")
        doc.destinationFolder = .init(fileURLWithPath: "Destination")
        doc.galleries.append(GalleryDocument.mock)
        for i in 1...10 {
            doc.galleries.append(
                .init(title: "Gallery \(i)", directory: "\(i)", webSite: doc))
        }
        return doc
    }()
}
