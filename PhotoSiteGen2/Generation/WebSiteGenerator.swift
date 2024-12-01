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

    let generationID: TSID
    let galleryGenerators: [GalleryGenerator]
    let generationStatus: WebsiteGenerationStatus

    init(
        sourceFolder: URL,
        staticSourceFolder: URL,
        destinationFolder: URL,
        galleryGenerators: [GalleryGenerator],
        generationStatus: WebsiteGenerationStatus,
        generationID: TSID = TSID()
    ) {
        self.sourceFolder = sourceFolder
        self.staticSourceFolder = staticSourceFolder
        self.destinationFolder = destinationFolder
        self.galleryGenerators = galleryGenerators
        self.generationID = generationID
        self.generationStatus = generationStatus
    }

    func generate(inlineWebComponentCSS: Bool, cleanBuild: Bool, minify: Bool)
        async
    {
        async let _ = generationStatus.startGeneration()
        do {
            if cleanBuild {
                try deleteContentsOfFolder(from: destinationFolder)
            }
            let generatedGalleries = try await generateGalleries(minify: minify)
            try await copyStaticContent(
                inlineWebComponentCSS: inlineWebComponentCSS)
            let thumbPcts = await generateIndexThumb(
                galleries: generatedGalleries)
            try getHTMLSource(
                GeneratedGalleries: generatedGalleries,
                thumbPcts: thumbPcts,
                minify: minify
            )
            .write(
                to: filename,
                atomically: true,
                encoding: String.Encoding.utf8)

        } catch {
            Task {
                async let _ = generationStatus.logError(
                    "Error generating Website: (\(error))")
            }
        }
        async let _ = generationStatus.completeGeneration()
    }

    private func generateGalleries(minify: Bool) async throws
        -> [GeneratedGallery]
    {
        try FileManager.default
            .createDirectory(
                at: destinationFolder.appendingPathComponent("thumbs"),
                withIntermediateDirectories: true)
        return try await withThrowingTaskGroup(of: GeneratedGallery.self) {
            group -> [GeneratedGallery] in
            var generatedGalleries = [GeneratedGallery]()

            for galleryGenerator in galleryGenerators {
                group.addTask {
                    try await galleryGenerator.generate(minify: minify)
                }
            }

            for try await gallery in group {
                generatedGalleries.append(gallery)
            }

            return generatedGalleries.sorted(by: {
                $0.sequenceNumber < $1.sequenceNumber
            })
        }
    }

    private func copyStaticContent(inlineWebComponentCSS: Bool) async throws {
        debugPrint("Copying static content to \(destinationFolder) inlineWebComponentCSS: \(inlineWebComponentCSS)")
        try await copyDirectory(
            from: staticSourceFolder,
            to: destinationFolder,
            logger: generationStatus,
            context: "Copying static content",
            filterFinder: {
                inlineWebComponentCSS && $0 == "webcomponents.js"
                    ? InlineStyleSheetFilter(staticFilesURL: self.staticSourceFolder)
                    : nil
            })
    }

    private func generateIndexThumb(galleries: [GeneratedGallery]) async
        -> [Double]
    {
        let favoritePhotos = galleries.map { $0.favoritePhoto }
        return await generateSpritesImage(
            thumbPhotos: favoritePhotos,
            width: THUMBNAIL_WIDTH,
            filename:
                destinationFolder
                .appendingPathComponent("thumbs")
                .appendingPathComponent("index.jpg"),
            errorHandler: generationStatus)
    }

    private func getHTMLSource(
        GeneratedGalleries: [GeneratedGallery], thumbPcts: [Double],
        minify: Bool
    ) -> String {
        let document = Document(.html) {
            Comment("generated: \(Date.now)")
            PSGPage(
                generationID: generationID,
                jsFiles: [
                    "js/webcomponents.js?tsid=\(generationID)",
                    "js/layout.js?tsid=\(generationID)",
                    "js/slides.js?tsid=\(generationID)",
                    "js/startup.js?tsid=\(generationID)",
                ]
            ) {
                Div {
                    for (index, gallery) in GeneratedGalleries.enumerated() {
                        gallery.galleryLink(index, thumbPct: thumbPcts[index])
                    }
                }
                .id("galleries")
                .class("wall")
                .attribute(
                    "data-thumbsrc",
                    "/thumbs/index.jpg?tsid=\(self.generationID)")
            }
        }
        return DocumentRenderer(minify: minify, indent: 2).render(document)
    }

    private var filename: URL {
        destinationFolder.appendingPathComponent("index.html")
    }

}
