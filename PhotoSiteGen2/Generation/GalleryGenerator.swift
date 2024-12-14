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
    let generationStatus: GalleryGenerationStatus

    init(
        generationID: TSID,
        wsSource: URL,
        wsDestination: URL,
        generationStatus: GalleryGenerationStatus,
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

        self.generationStatus = generationStatus
        destinationFolder = wsDestination.appendingPathComponent(genName)
    }

    func generate(minify: Bool) async throws -> GeneratedGallery {
        async let _ = generationStatus.startGeneration()
        //        if Bool.random() {
        //            await gs
        //            await generationStatus.logError("Dummy Error")
        //        }
        try await copyToDestination()
        let title = title
        let photos = getPhotos()

        let renderer = DocumentRenderer(minify: minify, indent: 2)
        try generateInfoHtmlFiles(photos: photos, renderer: renderer)

        let thumbImageName = "/thumbs/\(genName).jpg"

        let thumbPcts = await generateSpritesImage(
            thumbPhotos: photos, width: THUMBNAIL_WIDTH,
            filename:
                wsDestination
                .appendingPathComponent("thumbs")
                .appendingPathComponent("\(genName).jpg"),
            errorHandler: generationStatus)
        var preloads = [PreLoad(src: thumbImageName)]
        preloads.append(
            photos.prefix(1).map {
                PreLoad(
                    src: "/\(genName)/\($0.filteredFileNameWithExtension())",
                    srcset: $0.srcset(genName: genName))
            }.first!)

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
                preloads: preloads
            ) { [self] in
                SwiftHtml.Text(title)
                Br()
                getHTML(
                    thumbImageName: thumbImageName, photos: photos,
                    thumbPcts: thumbPcts)
            }
        }
        _ = try renderer.render(document).write(
            to:
                wsDestination.appendingPathComponent("\(genName).html"),
            atomically: true,
            encoding: String.Encoding.utf8)

        let generatedGallery = GeneratedGallery(
            favoritePhoto: try getFavoritePhoto(photos: photos),
            categories: categories,
            title: title,
            name: genName,
            sequenceNumber: sequenceNumber)

        async let _ = generationStatus.completeGeneration()
        return generatedGallery
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
            logger: generationStatus,
            context: "Copying images for gallery; \(genName)",
            renamer: Photo.filteredFileNameWithExtension(_:),
            directoryNameFilter: filterSubDirName
        )
    }

    private func filterSubDirName(url: URL) -> URL {
        var pathComponents = url.pathComponents
        for (index, component) in pathComponents.enumerated() {
            if component.wholeMatch(of: /W\d+/) != nil {
                pathComponents[index] = component.lowercased()
            }
        }
        return NSURL.fileURL(withPathComponents: pathComponents)!
    }

    private func getPhotos() -> [Photo] {
        do {
            return try FileManager.default.contentsOfDirectory(
                at: wsDestination.appendingPathComponent(genName),
                includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                options: [.skipsHiddenFiles]
            )
            .filter {
                !$0.hasDirectoryPath && $0.pathExtension.lowercased() == "jpg"
            }
            .map { try Photo(url: $0) }
            .sorted { (p0: Photo, p1: Photo) in
                if p0.filteredFileNameWithExtension() == titleImageFileName {
                    return true
                }
                if p1.filteredFileNameWithExtension() == titleImageFileName {
                    return false
                }
                return p0 < p1
            }

        } catch {
            let nm = genName
            Task {
                async let _ = generationStatus.logError(
                    "Error generating Photos for \(nm)")
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
            Task {
                await generationStatus.logError(
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
            .attribute("caption", md.caption, md.caption != nil)
            .attribute("ar", String(photo.aspectRatio))
            .attribute("top", String((index / 3) * 200))
            .attribute("left", String((index % 3) * 200))
            .attribute("thumbPct", "\(thumbPct)%")
            .attribute("stars", String(photo.metadata.starRating))
            .attribute("tm", photo.metadata.captureTime)
            .class("brick")
    }

    private func generateInfoHtmlFiles(
        photos: [Photo],
        renderer: DocumentRenderer
    ) throws {
        for photo in photos {
            try generateInfoHtmlFile(
                photo: photo,
                imageSrc:
                    "\(genName)/w0512/\(photo.filteredFileNameWithExtension())",
                renderer: renderer)
        }
    }

    private func generateInfoHtmlFile(
        photo: Photo,
        imageSrc: String,
        renderer: DocumentRenderer
    ) throws {
        struct CropData {
            var imageSrc: String
            var top: Int
            var bottom: Int
            var left: Int
            var right: Int
            var angle: Float
            var canvasWidth: Int
            var canvasHeight: Int

            init(md: ImageMetaData, imageSrc: String) {
                var w: Double
                var h: Double
                let pw = Double(md.pixelWidth)
                let ph = Double(md.pixelHeight)
                if md.pixelWidth > md.pixelHeight {
                    w = 200.0
                    h = w * ph / pw

                } else {
                    h = 200.0
                    w = h * pw / ph
                }
                top = Int(h * md.cropTop!)
                bottom = Int(h * md.cropBottom!)
                left = Int(w * md.cropLeft!)
                right = Int(w * md.cropRight!)
                angle = Float(md.cropAngle!)
                canvasWidth = Int(w)
                canvasHeight = Int(h)
                self.imageSrc = imageSrc
            }
        }
        let md = photo.metadata

        let cropData =
            md.hasCrop ? CropData(md: md, imageSrc: imageSrc) : nil

        let html = Document(.unspecified) {
            Div {
                if let caption = md.caption {
                    Div {
                        Text(caption)
                    }.class("caption")
                }
                if let captureTime = md.captureTime {
                    Div {
                        Text(captureTime)
                    }.class("creationDate")
                }
                if let copyright = md.copyright {
                    Div {
                        Text(copyright)
                    }.class("copyright")
                }

                Div {
                    switch md.starRating {
                    case 0: Text("&star;&star;&star;&star;&star;")
                    case 1: Text("&starf;&star;&star;&star;&star;")
                    case 2: Text("&starf;&starf;&star;&star;&star;")
                    case 3: Text("&starf;&starf;&starf;&star;&star;")
                    case 4: Text("&starf;&starf;&starf;&starf;&star;")
                    case 5: Text("&starf;&starf;&starf;&starf;&starf;")
                    default: Text("")
                    }
                }.class("rating")

                if let camera = md.camera {
                    Div {
                        Text(camera)
                    }.class("camera")
                }
                if let lens = md.lens {
                    Div {
                        Text(lens)
                    }.class("lens")
                }
                if let focalLength = md.focalLength {
                    Div {
                        Text("\(focalLength)mm")
                    }.class("focalLength")
                }
                if let subjectDistance = md.subjectDistance {
                    Div {
                        Text(  // TODO: have decimal count adjust for distance ranges
                            "\(String(format: "%.1f" ,subjectDistance*3.28084)) ft (\(String(format: "%.1f" ,subjectDistance)) m)"
                        )
                    }.class("focalDistance")
                }
                if let iso = md.iso {
                    Div {
                        Text("ISO \(iso)")
                    }.class("iso")
                }
                if let fstop = md.aperture {
                    Div {
                        Text("&fnof;\(fstop)")
                    }.class("fstop")
                }
                if let exposureTime = md.exposureTime {
                    Div {
                        if exposureTime < 1 {
                            let fraction = 1.0 / exposureTime
                            Text("1/\(String(format: "%.0f" ,fraction)) sec")
                        } else {
                            Text("\(exposureTime) sec")
                        }
                    }.class("exposure")
                }
                if !md.keywords.isEmpty {
                    Div {
                        for keyword in md.keywords {
                            Div {
                                Text(keyword)
                            }
                        }
                    }.class("keywords")
                }
                if let cropData {
                    Div {
                        Text("Crop:")
                        Canvas().id("cropCanvas")
                            .attribute("height", String(cropData.canvasHeight))
                            .attribute("height", String(cropData.canvasWidth))
                            .attribute("data-cropTop", String(cropData.top))
                            .attribute("data-cropLeft", String(cropData.left))
                            .attribute("data-bottom", String(cropData.bottom))
                            .attribute("data-right", String(cropData.right))
                            .attribute("data-angle ", String(cropData.angle))
                            .attribute("data-imageSrc", imageSrc)
                    }.class("crop")
                }
                if let preserveFileName = md.preservedFileName {
                    Div {
                        Text("Source: \(preserveFileName)")
                    }.class("source")
                }
            }
            .class("info","hide")
        }
        try renderer.render(html).write(
            to:
                wsDestination.appendingPathComponent(
                    "\(genName)/\(photo.filteredFileName()).html"),
            atomically: true,
            encoding: String.Encoding.utf8)
    }
}
