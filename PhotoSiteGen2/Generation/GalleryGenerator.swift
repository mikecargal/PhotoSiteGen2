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
    let galleryID: UUID

    let genName: String
    let sequenceNumber: Int
    let titleImageFileName: String?
    let title: String
    let categories: [String]
    let destinationFolder: URL
    let generationStatus: GalleryGenerationStatus
    let photoCache: [URL: Photo]?

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
        self.galleryID = galleryInfo.galleryUUID
        self.photoCache = galleryInfo.photosCache

        genName = galleryInfo.genName
        sequenceNumber = galleryInfo.sequenceNumber
        titleImageFileName = galleryInfo.titleImageFileName
        title = galleryInfo.title
        categories = galleryInfo.categories

        self.generationStatus = generationStatus
        destinationFolder = wsDestination.appendingPathComponent(genName)
    }

    func generate(minify: Bool) async throws -> GeneratedGallery {
        do {
            async let _ = generationStatus.startGeneration()
            let imageCount = try folderFileCount(at: sourceDirectory)
            async let _ = generationStatus.setItemCount(imageCount)

            try await copyToDestination()
            let title = title
            let photos = try await getPhotos()

            try Task.checkCancellation()

            let renderer = DocumentRenderer(minify: minify, indent: 2)
            try generateInfoHtmlFiles(photos: photos, renderer: renderer)

            let thumbImageName = "/thumbs/\(genName).jpg"

            let thumbPcts = await generateSpritesImage(
                thumbPhotos: photos, width: THUMBNAIL_WIDTH,
                filename:
                    wsDestination
                    .appendingPathComponent("thumbs")
                    .appendingPathComponent("\(genName).jpg"),
                errorHandler: generationStatus,
                generationStatus: generationStatus)

            let document = Document(.html) {
                Comment("generated: \(Date.now)")
                PSGPage(
                    generationID: generationID,
                    jsFiles: [
                        "js/webcomponents.js",
                        "js/layout.js",
                        "js/slides.js",
                        "js/startup.js",
                    ]
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
                sequenceNumber: sequenceNumber,
                galleryID: galleryID,
                photos: photos
            )

            async let _ = generationStatus.completeGeneration()
            return generatedGallery
        } catch let error as CancellationError {
            async let _ = generationStatus.cancelledGeneration()
            throw error
        } catch {
            throw error
        }
    }

    var sourceDirectory: URL {
        wsSource
            .appending(component: "galleries")
            .appending(component: genName)
    }

    private func copyToDestination() async throws {
        try await copyDirectory(
            from: sourceDirectory,
            to:
                wsDestination
                .appending(component: genName),
            logger: generationStatus,
            context: "Copying images for gallery; \(genName)",
            renamer: Photo.filteredFileNameWithExtension(_:),
            directoryNameFilter: filterSubDirName,
            progressClosure: { _ in
                async let _ = generationStatus.progressTick()
            }
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

    private func getPhotos() async throws -> [Photo] {
        do {
            let urls = try FileManager.default.contentsOfDirectory(
                at: wsDestination.appendingPathComponent(genName),
                includingPropertiesForKeys: [
                    .isDirectoryKey, .nameKey, .contentModificationDateKey,
                ],
                options: [.skipsHiddenFiles]
            )
            .filter {
                !$0.hasDirectoryPath && $0.pathExtension.lowercased() == "jpg"
            }

            let photos = try await withThrowingTaskGroup(of: Photo.self) {
                group -> [Photo] in
                var photos = [Photo]()
                for url in urls {
                    try Task.checkCancellation()
                    if let cachedPhoto = cachedPhotoFor(url: url) {
                        group.addTask {
                            async let _ = generationStatus.progressTick()
                            return cachedPhoto
                        }
                    } else {
                        group.addTask {
                            let photo = try Photo(url: url)
                            async let _ = generationStatus.progressTick()
                            return photo
                        }
                    }
                }
                try Task.checkCancellation()
                for try await photo in group {
                    photos.append(photo)
                }
                return photos
            }

            return photos.sorted { (p0: Photo, p1: Photo) in
                if p0.filteredFileNameWithExtension() == titleImageFileName {
                    return true
                }
                if p1.filteredFileNameWithExtension() == titleImageFileName {
                    return false
                }
                return p0 < p1
            }
        } catch is CancellationError {
            Task {
                async let _ = generationStatus.cancelledGeneration()
            }
            return []
        } catch {
            let nm = genName
            Task {
                async let _ = generationStatus.logError(
                    "Error generating Photos for \(nm)")
            }
            return []
        }
    }

    private func cachedPhotoFor(url: URL) -> Photo? {
        if let cachedPhoto = photoCache?[url] {
            if let modDate =
                try? url
                .resourceValues(forKeys: [.contentModificationDateKey])
                .contentModificationDate
            {
                if cachedPhoto.modDate == modDate {
                    return cachedPhoto
                }
            }
        }
        return nil
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

    fileprivate func slideShowDiv(
        thumbImageName: String, photos: [Photo], thumbPcts: [Double]
    ) -> Tag {
        Div {
            FadeInImage().id("current")
                .attribute("explicitSizing", "true")
                .attribute(
                    "thumbsrc", "\(thumbImageName)?tsid=\(generationID)"
                )
                .attribute(
                    "imagesrc",
                    photos.first?.filteredFileNameWithExtension()
                )
                .attribute("thumbPct", "\(Float(thumbPcts.first!))%")
                .attribute(
                    "ar", String(Float(photos.first!.aspectRatio)))
            Div().id("infoContainer")
            Div {
                Button { Text("X") }
                    .onClick("window.slideShow.hide()")
                    .id("hideSS")
                Div { Div().id("prevIcon") }.id("gotoPrev")
                Div { Div().id("nextIcon") }.id("gotoNext")
                Button {
                    Img(
                        src: "images/info-circle.svg",
                        alt: "show picture info"
                    )
                }
                .onClick("window.slideShow.toggleInfo()")
                .id("showInfo")
            }.class("ssControls")
            Img(src: "", alt: "prev").id("prev")
            Img(src: "", alt: "prev").id("prevSmall")
            Img(src: "", alt: "next").id("next")
            Img(src: "", alt: "next").id("nextSmall")
        }.class("ssContainer")
    }

    private func getHTML(
        thumbImageName: String, photos: [Photo], thumbPcts: [Double]
    ) -> Tag {
        GroupTag {
            Div {
                slideShowDiv(
                    thumbImageName: thumbImageName,
                    photos: photos,
                    thumbPcts: thumbPcts)
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
            .attribute("ar", String(Float(photo.aspectRatio)))
            .attribute("top", String((index / 3) * 200))
            .attribute("left", String((index % 3) * 200))
            .attribute("thumbPct", "\(Float(thumbPct))%")
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

    let FT_PER_METER = 3.28084

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
                let originalWidth = pw / (md.cropRight! - md.cropLeft!)
                let originalHeight = ph / (md.cropBottom! - md.cropTop!)
                if originalWidth > originalHeight {
                    w = 200.0
                    h = 200 * originalHeight / originalWidth
                } else {
                    h = 200.0
                    w = 200 * originalWidth / originalHeight
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
            Comment(" tsID=\(generationID) ")
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
                if let subjectDistance = md.subjectDistance, subjectDistance > 0
                {
                    Div {
                        Text(  // TODO: have decimal count adjust for distance ranges
                            "\(String(format: "%.1f" ,subjectDistance*FT_PER_METER)) ft (\(String(format: "%.1f" ,subjectDistance)) m)"
                        )
                    }.class("focalDistance")
                }
                if let iso = md.iso {
                    Div {
                        Text(String(iso))
                    }.class("iso")
                }
                if let fstop = md.aperture {
                    Div {
                        Text(fstop)
                    }.class("fstop")
                }
                if let exposureTime = md.exposureTime {
                    Div {
                        if exposureTime < 1 {
                            let fraction = 1.0 / exposureTime
                            Text("1/\(String(format: "%.0f" ,fraction))")
                        } else {
                            Text(String(format: "%.0f", exposureTime))
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
                if let exposureComp = md.exposureComp {
                    Div {
                        Text(exposureComp)
                    }.class("exposureComp")
                }
                if let cropData {
                    Div {
                        Canvas().id("cropCanvas")
                            .attribute("height", String(cropData.canvasHeight))
                            .attribute("width", String(cropData.canvasWidth))
                            .attribute(
                                "data-height", String(cropData.canvasHeight)
                            )
                            .attribute(
                                "data-width", String(cropData.canvasWidth)
                            )
                            .attribute("data-cropTop", String(cropData.top))
                            .attribute("data-cropLeft", String(cropData.left))
                            .attribute(
                                "data-cropbottom", String(cropData.bottom)
                            )
                            .attribute("data-cropright", String(cropData.right))
                            .attribute(
                                "data-cropangle ", String(cropData.angle)
                            )
                            .attribute("data-imageSrc", imageSrc)
                    }.class("crop")
                }
                if md.preservedFileName != nil || md.rawFileName != nil {
                    Div {
                        Text(md.preservedFileName ?? md.rawFileName!)
                    }.class("source")
                }
            }
            .id("info")
        }
        try renderer.render(html).write(
            to:
                wsDestination.appendingPathComponent(
                    "\(genName)/\(photo.filteredFileName()).html"),
            atomically: true,
            encoding: String.Encoding.utf8)
    }
}
