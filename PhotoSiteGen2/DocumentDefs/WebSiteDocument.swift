//
//  WebSiteDoc.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI
import UniformTypeIdentifiers

struct WebSiteDocument: FileDocument, Codable {
    static var readableContentTypes = [UTType(exportedAs: "com.mikecargal.photositegen2.website")]
    
    var sourceFolder: URL?
    var staticSiteFolder: URL?
    var destinationFolder: URL?
    var categories = [String]()
    var galleries = [GalleryDocument]()
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self = try JSONDecoder().decode(WebSiteDocument.self, from: data)
        }
    }
    
    init() {}
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(self)
        return FileWrapper(regularFileWithContents: data)
    }
    
    static let mock: WebSiteDocument = {
        var doc = WebSiteDocument()
        doc.sourceFolder = .init(fileURLWithPath: "Source")
        doc.staticSiteFolder = .init(fileURLWithPath: "StaticSite")
        doc.destinationFolder = .init(fileURLWithPath: "Destination")
        doc.galleries.append(GalleryDocument.mock)
        doc.galleries.append(GalleryDocument(title: "Gallery 2", directory: "dir2"))
        doc.galleries.append(GalleryDocument(title: "Gallery 3", directory: "dir3"))
        doc.galleries.append(GalleryDocument(title: "Gallery 4", directory: "dir4"))
        doc.galleries.append(GalleryDocument(title: "Gallery 5", directory: "dir5"))
        return doc
    }()
}

