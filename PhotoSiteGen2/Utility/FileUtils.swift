//
//  FileUtils.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 11/19/23.
//

import Foundation

typealias Renamer = (URL) -> String
typealias FilterFinder = (String) -> FileFilter?
typealias DirectoryNameFilter = (URL) -> URL
typealias ProgressClosure = @MainActor (String?) async -> Void

func copyDirectory(
    from source: URL,
    to dest: URL,
    logger: ErrorHandler,
    context: String,
    renamer: Renamer? = nil,
    filterFinder: FilterFinder? = nil,
    directoryNameFilter: DirectoryNameFilter? = nil,
    progressClosure: ProgressClosure? = nil
) async throws {
    try FileManager.default.createDirectory(
        at: directoryNameFilter?(dest) ?? dest,
        withIntermediateDirectories: true)
    let urls = try FileManager.default.contentsOfDirectory(
        at: source,
        includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
        options: [.skipsHiddenFiles])

    var fileNameSet = Set<String>()
    for url in urls {
        try Task.checkCancellation()
        if url.hasDirectoryPath {
            try await copyDirectory(
                from: url,
                to: dest.appending(component: url.lastPathComponent),
                logger: logger,
                context: context,
                renamer: renamer,
                filterFinder: filterFinder,
                directoryNameFilter: directoryNameFilter)
        } else {
            let filename = renamer?(url) ?? url.lastPathComponent
            let copyDest = dest.appending(component: filename)
            if fileNameSet.contains(filename) {
                async let _ = logger.handleError(
                    context, GalleryGenerationError.DuplicateName(filename))
            }
            fileNameSet.insert(filename)

            try? FileManager.default.removeItem(at: copyDest)
            if let filter = filterFinder?(filename) {
                let fileString = try! String(contentsOf: url, encoding: .utf8)
                let filteredContent = try filter.filter(fileString)
                try! filteredContent.write(
                    to: copyDest, atomically: true, encoding: .utf8)
            } else {
                _ = try FileManager.default.copyItem(at: url, to: copyDest)
                async let _ = progressClosure?(filename)
            }
        }
    }
}

func folderFileCount(at url: URL) throws -> Int {
    let urls = try FileManager.default.contentsOfDirectory(
        at: url,
        includingPropertiesForKeys: [.isDirectoryKey,.isHiddenKey],
        options: [.skipsHiddenFiles,.skipsSubdirectoryDescendants])
    return urls.filter {!$0.hasDirectoryPath}.count
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
