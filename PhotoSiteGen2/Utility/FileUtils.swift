//
//  FileUtils.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 11/19/23.
//

import Foundation

typealias Renamer = (URL) -> String
typealias FilterFinder = (String) -> FileFilter?

func copyDirectory(from source: URL,
                   to dest: URL,
                   logger: ErrorHandler,
                   context: String,
                   renamer: Renamer? = nil,
                   filterFinder: FilterFinder? = nil) async throws {
    try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
    let urls = try FileManager.default.contentsOfDirectory(
        at: source,
        includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
        options: [.skipsHiddenFiles])

    var fileNameSet = Set<String>()
    for url in urls {
        if url.hasDirectoryPath {
            try await copyDirectory(from: url,
                                    to: dest.appending(component: url.lastPathComponent),
                                    logger: logger,
                                    context: context,
                                    renamer: renamer,
                                    filterFinder: filterFinder)
        } else {
            let filename = renamer?(url) ?? url.lastPathComponent
            let copyDest = dest.appending(component: filename)
            if fileNameSet.contains(filename) {
                async let _ = logger.handleError(context, GalleryGenerationError.DuplicateName(filename))
            }
            fileNameSet.insert(filename)

            try? FileManager.default.removeItem(at: copyDest)
            if let filter = filterFinder?(filename) {
                let fileString = try! String(contentsOf: url,encoding: .utf8)
                let filteredContent = try filter.filter(fileString)
                try! filteredContent.write(to: copyDest, atomically: true, encoding: .utf8)
            } else {
                _ = try FileManager.default.copyItem(at: url, to: copyDest)
            }
        }
    }
}

func deleteContentsOfFolder(from: URL) throws {
    let urls = try FileManager.default.contentsOfDirectory(
        at: from,
        includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
        options: [.skipsHiddenFiles])
    for url in urls {
        try FileManager.default.removeItem(at: url)
    }
}
