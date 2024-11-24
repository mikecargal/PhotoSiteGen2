//
//  GalleryGenerator.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 2/18/24.
//

import Foundation
import SwiftHtml

enum GalleryGenerationError: Error {
    case NoPhotos
    case DuplicateName(String)
}

struct GalleryGenerator {
    let THUMBNAIL_WIDTH = 20
    let generationID: TSID
    let wsDestination: URL
    let wsSource: URL

    let genName: String
    let sequenceNumber: Int
    let titleImageFileName: String?
    let title: String
    let categories: [String]
    let destinationFolder: URL
    let logger: Logger

    init(
        generationID: TSID,
        wsSource: URL,
        wsDestination: URL,
        logger: Logger,
        galleryInfo: GalleryGenerationInfo
    ) {
        self.generationID = generationID
        self.wsSource = wsSource
        self.wsDestination = wsDestination

        genName = galleryInfo.genName
        sequenceNumber = galleryInfo.sequenceNumber
        titleImageFileName = galleryInfo.titleImageFileName
        title = galleryInfo.title
        categories = galleryInfo.categories

        self.logger = logger
        destinationFolder = wsDestination.appendingPathComponent(genName)
    }

    func generate(minify: Bool) async throws -> GeneratedGallery {
        try await copyToDestination()
        let title = title
        let photos = getPhotos()

        let thumbImageName = "/thumbs/\(genName).jpg"

        let thumbPcts = await generateSpritesImage(
            thumbPhotos: photos, width: THUMBNAIL_WIDTH,
            filename:
                wsDestination
                .appendingPathComponent("thumbs")
                .appendingPathComponent("\(genName).jpg"),
            errorHandler: logger)
        let document = Document(.html) {
            Comment("generated: \(Date.now)")
            PSGPage(
                generationID: generationID,
                jsFiles: [
                    "js/webcomponents.js?tsid=\(generationID)",
                    "js/layout.js?tsid=\(generationID)",
                    "js/slides.js?tsid=\(generationID)",
                    "js/startup.js?tsid=\(generationID)",
                ],
                preload: thumbImageName
            ) { [self] in
                SwiftHtml.Text(title)
                Br()
                getHTML(
                    thumbImageName: thumbImageName, photos: photos,
                    thumbPcts: thumbPcts)
            }
        }
        let renderer = DocumentRenderer(minify: minify, indent: 2).render(
            document)
        _ = try renderer.write(
            to:
                wsDestination.appendingPathComponent("\(genName).html"),
            atomically: true,
            encoding: String.Encoding.utf8)

        return GeneratedGallery(
            favoritePhoto: try getFavoritePhoto(photos: photos),
            categories: categories,
            title: title,
            name: genName,
            sequenceNumber: sequenceNumber)
    }

    private func copyToDestination() async throws {
        try await copyDirectory(
            from:
                wsSource
                .appending(component: "galleries")
                .appending(component: genName),
            to:
                wsDestination
                .appending(component: genName),
            logger: logger,
            context: "Copying images for gallery; \(genName)",
            renamer: Photo.filteredFileNameWithExtension(_:))
    }

    private func getPhotos() -> [Photo] {
        do {
            return try FileManager.default.contentsOfDirectory(
                at: wsDestination.appendingPathComponent(genName),
                includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                options: [.skipsHiddenFiles]
            )
            .filter { !$0.hasDirectoryPath }
            .map { try Photo(url: $0) }
            .sorted()

        } catch {
            let eh = logger
            let nm = genName
            Task {
                await eh.handleError("gathering photos for \(nm)", error)
            }
            return []
        }
    }

    private func getFavoritePhoto(photos: [Photo]) throws -> Photo {
        guard photos.count > 0 else {
            throw GalleryGenerationError.NoPhotos
        }

        guard let titleImageFileName = titleImageFileName else {
            return photos.first!
        }
        
        if !photos.contains(where: {
            $0.filteredFileNameWithExtension() == titleImageFileName
        }) {
            let eh = logger
            Task {
                await eh.logMessage(
                    "could not find titleImage (\(titleImageFileName))... using default (first)"
                )
            }
        }
        return photos[
            photos.firstIndex {
                $0.filteredFileNameWithExtension() == titleImageFileName
            } ?? 0]
    }

    private func getHTML(
        thumbImageName: String, photos: [Photo], thumbPcts: [Double]
    ) -> Tag {
        GroupTag {
            Div {
                FadeInImage().id("current")
                    .attribute("explicitSizing", "true")
                    .attribute(
                        "thumbsrc", "\(thumbImageName)?tsid=\(generationID)")
                Div {
                    Button { Text("X") }.onClick("window.slideShow.hide()")
                    Div { Div().id("prevIcon") }.id("gotoPrev")
                    Div { Div().id("nextIcon") }.id("gotoNext")
                }.class("ssControls")
                Img(src: "", alt: "prev").id("prev")
                Img(src: "", alt: "next").id("next")
            }
            .id("slideShow")
            .class("slideShowHidden")
            Div {
                for (index, photo) in photos.enumerated() {
                    galleryImage(
                        photo: photo, index: index, thumbPct: thumbPcts[index])
                }
            }
            .id("gallery")
            .class("wall")
            .attribute("data-gallery-name", genName)
            .attribute("thumbsrc", "\(thumbImageName)?tsid=\(generationID)")
        }
    }

    private func galleryImage(photo: Photo, index: Int, thumbPct: Double) -> Tag
    {
        let md = photo.metadata
        return GalleryImage()
            .attribute("imagesrc", photo.filteredFileNameWithExtension())
            .attribute("caption", md.iptc?.caption, md.iptc?.caption != nil)
            .attribute("ar", String(photo.aspectRatio))
            .attribute("top", String((index / 3) * 200))
            .attribute("left", String((index % 3) * 200))
            .attribute("thumbPct", "\(thumbPct)%")
            .attribute("stars", String(photo.metadata.iptc?.starRating ?? 0))
            .attribute("tm", photo.metadata.exif?.captureTime)
            .class("brick")
    }

}
