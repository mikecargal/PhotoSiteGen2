//
//  WebSite.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 11/9/23.
//

import Foundation
import SwiftHtml
import SwiftUI

enum SiteGenerationError: Error {
    case noLogger
}

final class WebSiteGenerator: Sendable {
    private let THUMBNAIL_WIDTH = 16

    let sourceFolder: URL
    let staticSourceFolder: URL
    let destinationFolder: URL

    private let logger: Logger
    let generationID: TSID
    let galleryGenerators : [GalleryGenerator]

    init(sourceFolder: URL,
         staticSourceFolder: URL,
         destinationFolder: URL,
         galleryGenerators : [GalleryGenerator],
         logger: Logger,
         generationID: TSID = TSID()) {
        self.sourceFolder = sourceFolder
        self.staticSourceFolder = staticSourceFolder
        self.destinationFolder = destinationFolder
        self.galleryGenerators = galleryGenerators
        self.logger = logger
        self.generationID = generationID
    }

    func generate(inlineWebComponentCSS: Bool, cleanBuild: Bool, minify: Bool) async {
        do {
            if cleanBuild {
                try deleteContentsOfFolder(from: destinationFolder)
            }
            let generatedGalleries = try await generateGalleries(minify: minify)
            try await copyStaticContent(inlineWebComponentCSS: inlineWebComponentCSS)
            let thumbPcts = await generateIndexThumb(galleries: generatedGalleries)
            try getHTMLSource(GeneratedGalleries: generatedGalleries,
                              thumbPcts: thumbPcts,
                              minify: minify)
                .write(to: filename,
                       atomically: true,
                       encoding: String.Encoding.utf8)

        } catch {
            let logger = logger
            Task {
                await logger.handleError("generating website", error)
            }
        }
        logCompletion()
    }

    private func generateGalleries(minify: Bool) async throws -> [GeneratedGallery] {
        try FileManager.default
            .createDirectory(at: destinationFolder.appendingPathComponent("thumbs"),
                             withIntermediateDirectories: true)
        return try await withThrowingTaskGroup(of: GeneratedGallery.self) { group -> [GeneratedGallery] in
            var generatedGalleries = [GeneratedGallery]()

            for galleryGenerator in galleryGenerators {
                await logger.logMessage("generating Gallery \(galleryGenerator.genName)")
                group.addTask {
                    try await galleryGenerator.generate(minify: minify)
                }
            }

            for try await gallery in group {
                generatedGalleries.append(gallery)
                await logger.logMessage("\(gallery.title) generated")
            }

            return generatedGalleries.sorted(by: { $0.sequenceNumber < $1.sequenceNumber })
        }
    }

    private func copyStaticContent(inlineWebComponentCSS: Bool) async throws {
        try await copyDirectory(from: staticSourceFolder,
                                to: destinationFolder,
                                logger: logger,
                                context: "Copying static content",
                                filterFinder: {
                                    inlineWebComponentCSS && $0 == "webcomponents.js"
                                        ? InlineStyleSheetFilter(staticFilesURL: self.staticSourceFolder)
                                        : nil
                                })
    }

    private func generateIndexThumb(galleries: [GeneratedGallery]) async -> [Double] {
        let favoritePhotos = galleries.map { $0.favoritePhoto }
        return await generateSpritesImage(thumbPhotos: favoritePhotos,
                                          width: THUMBNAIL_WIDTH,
                                          filename: destinationFolder
                                              .appendingPathComponent("thumbs")
                                              .appendingPathComponent("index.jpg"),
                                          errorHandler: logger)
    }

    private func logCompletion() {
        let logger = logger
        Task {
            if await logger.errorLevel == .NO_ERROR {
                await logger.logMessage("Completed without error")
            }
        }
    }

    private func getHTMLSource(GeneratedGalleries: [GeneratedGallery], thumbPcts: [Double], minify: Bool) -> String {
        let document = Document(.html) {
            Comment("generated: \(Date.now)")
            PSGPage(generationID: generationID,
                    jsFiles: ["js/webcomponents.js?tsid=\(generationID)",
                              "js/layout.js?tsid=\(generationID)",
                              "js/slides.js?tsid=\(generationID)",
                              "js/startup.js?tsid=\(generationID)"]) {
                Div {
                    for (index, gallery) in GeneratedGalleries.enumerated() {
                        gallery.galleryLink(index, thumbPct: thumbPcts[index])
                    }
                }
                .id("galleries")
                .class("wall")
                .attribute("data-thumbsrc", "/thumbs/index.jpg?tsid=\(self.generationID)")
            }
        }
        return DocumentRenderer(minify: minify, indent: 2).render(document)
    }

//    private var metadata: SiteMetadata? {
//        let mdFile = sourceFolder.appendingPathComponent("metadata.json")
//        do {
//            return try SiteMetadata.create(from: Data(contentsOf: mdFile))
//        } catch {
//            let logger = logger
//            Task {
//                await logger.handleError("Reading WebSite Metadata \(mdFile.absoluteString)", error)
//            }
//            return nil
//        }
//    }

    private var filename: URL {
        destinationFolder.appendingPathComponent("index.html")
    }

//    private func getGalleryGenerators(webSite:WebSite) -> [GalleryGenerator] {
////        do {
////            let galleryDirs = try FileManager.default.contentsOfDirectory(
////                at: sourceFolder.appendingPathComponent("galleries"),
////                includingPropertiesForKeys: nil,
////                options: [.skipsHiddenFiles])
////            return try galleryDirs.map {
////                let galleryName = $0.lastPathComponent
////                return try GalleryGenerator(generationID: generationID,
////                                            wsSource: sourceFolder,
////                                            wsDestination: destinationFolder,
////                                            galleryName: galleryName,
////                                            metadata: metadata?.sites[galleryName],
////                                            logger: logger)
////            }
////        } catch {
////            let logger = logger
////            Task {
////                await logger.handleError("Creating Gallery", error)
////            }
////            return []
////        }
//        webSite.galleries.map {
//            GalleryGenerator(
//        }
//    }
}
