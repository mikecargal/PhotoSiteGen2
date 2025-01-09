//
//  CropRenderInfo.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 1/2/25.
//
import Foundation
import OSLog
import SwiftSvg

struct CropRenderer {
    static let DEBUGGING = false
    private static let logger = Logger(
        subsystem: "com.mikecargal.photositegen2", category: "CropRenderer")

    enum Orientation: Int {
        case orient0 = 0
        case orient90 = 90
        case orient180 = 180
        case orient270 = 270
    }

    var imageW, imageH: Int
    var angle, cropTop, cropBottom, cropLeft, cropRight: Double
    var imageSrc: String
    var orientation: Orientation

    func getCropInfo(maxWH: Double) -> CropRenderInfo {

        let radAngle = deg2rad(angle)

        //  get the top, righ, bottom, and left appropriate
        //    to the rotation directive in the image tags
        //    "#rotate(0,90,180,270)" (or none = rotate 0 degrees)
        let (top, right, bottom, left) =
            switch orientation {
            case .orient0: (cropTop, cropRight, cropBottom, cropLeft)
            case .orient90: (cropRight, cropTop, cropLeft, cropBottom)
            case .orient180: (cropBottom, cropRight, cropTop, cropLeft)
            case .orient270: (cropLeft, cropBottom, cropRight, cropTop)
            }

        // calculate the original (uncropped) width and height
        let (unCroppedW, unCroppedH) = getUncroppedWH(
            top: top, bottom: bottom, left: left, right: right)

        // build representation prior to rotation
        var croppedRepresentation = CropRepresentation(
            originalRect: Rect(
                tl: Point(x: 0, y: 0), br: Point(x: 1, y: 1)),
            croppedRect: Rect(
                tl: Point(x: left, y: top),
                br: Point(x: right, y: bottom)
            ),
            src: imageSrc
        )
        .scaled(xScale: unCroppedW, yScale: unCroppedH)

        if Self.DEBUGGING {
            Self.logger.debug("\(croppedRepresentation.getSVG())")
        }

        // create a version of the cropped rect and rotate it the
        //  opposite direction of the eventual rotation
        //  (This "unrotates" (levels) the cropped Rect)
        croppedRepresentation = croppedRepresentation.rotated(
            aroundOrigin: croppedRepresentation.originalRect.center,
            byRadians: -radAngle)
        if Self.DEBUGGING {
            Self.logger.debug("\(croppedRepresentation.getSVG())")
        }

        // with crop level we can recalutate the tr, and bl
        //   using top-left and bottom-right
        let croppedRect: CropRepresentation.Rect =
            Rect(
                tl: croppedRepresentation.croppedRect.tl,
                br: croppedRepresentation.croppedRect.br)
        // update the croppedRect with the version with correct tr, and bl
        croppedRepresentation.croppedRect = croppedRect
        if Self.DEBUGGING {
            Self.logger.debug("\(croppedRepresentation.getSVG())")
        }

        var origRect = croppedRepresentation.originalRect

        // translate to minX = minY = 0
        //  (no points have a negative x or y)
        let tx = -origRect.minX
        let ty = -origRect.minY
        croppedRepresentation =
            croppedRepresentation
            .translated(xOffset: tx, yOffset: ty)
        if Self.DEBUGGING {
            Self.logger.debug("\(croppedRepresentation.getSVG())")
        }

        // scale to fit in maxWH x maxWH canvas
        let scaleToMaxWH =
            origRect.rWidth > origRect.rHeight
            ? maxWH / origRect.rWidth : maxWH / origRect.rHeight
        croppedRepresentation =
            croppedRepresentation
            .scaled(scale: scaleToMaxWH)
        if Self.DEBUGGING {
            Self.logger.debug(
                "origRect.rWidth: \(origRect.rWidth), origRect.rHeight: \(origRect.rHeight), scaleToMaxWH: \(scaleToMaxWH)"
            )
            Self.logger.debug("\(croppedRepresentation.getSVG())")
        }

        // translate to center vertically and horizontally
        origRect = croppedRepresentation.originalRect
        if origRect.rWidth > origRect.rHeight {
            croppedRepresentation =
                croppedRepresentation
                .translated(
                    xOffset: 0,
                    yOffset: (maxWH - origRect.rHeight) / 2)
        } else {
            croppedRepresentation =
                croppedRepresentation
                .translated(
                    xOffset: (maxWH - origRect.rWidth) / 2,
                    yOffset: 0)
        }
        if Self.DEBUGGING {
            Self.logger.debug("\(croppedRepresentation.getSVG())")
        }
        return CropRenderInfo(croppedRepresentation: croppedRepresentation)
    }

    func getUncroppedWH(
        top: Double,  // location of top as a percentage of the original height
        bottom: Double,  // location of bottom as a percentage of the original height
        left: Double,  // location of left side as a percentage of the original width
        right: Double  // location of right side as a percentage of the original width
    ) -> (w: Double, h: Double) {
        // create a full size version of the cropped Rect
        // and rotate it to "cropAngle"
        let rect = Rect(
            tl: Point(x: 0, y: 0),
            br: Point(x: Double(imageW), y: Double(imageH))
        )
        .rotated(aroundOrigin: Point(x: 0, y: 0), byRadians: deg2rad(angle))

        // NOTE: the top, and left are used to position the top-left vertex
        // and the bottom and right are used to locate the bottom-right vertex
        // depending upon the rotation, the y of top-left could actually be
        // lower than the y of the bottom-right location of these vertices
        // relative to the unrotated original image.  (And these values are plotted
        // against the unrotated original image)
        // This mean that either (or both) of the rotatedCropWidth and rotatedCropHeight
        // may actually be negative.  When this occurs the croppedHeightAsPercentageOfOriginal
        // (or the height), will also be negative (having something be a negative percentage
        // of the whole, seems odd, but once we divide the negative cropWidth by the negative
        // percentage, we get the correct, positive, width of the whole.
        let rotatedCropWidth = rect.br.x - rect.tl.x
        let rotatedCropHeight = rect.br.y - rect.tl.y

        let croppedWidthAsPercentageOfOriginal = right - left
        let croppedHeightAsPercentageOfOriginal = bottom - top

        return (
            w: rotatedCropWidth / croppedWidthAsPercentageOfOriginal,
            h: rotatedCropHeight / croppedHeightAsPercentageOfOriginal
        )
    }

    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
}

struct CropRepresentation: Codable {
    var originalRect: Rect
    var croppedRect: Rect
    let src: String

    func scaled(scale: Double) -> CropRepresentation {
        CropRepresentation(
            originalRect: originalRect.scaled(xScale: scale, yScale: scale),
            croppedRect: croppedRect.scaled(xScale: scale, yScale: scale),
            src: src)
    }

    func scaled(xScale: Double, yScale: Double) -> CropRepresentation {
        CropRepresentation(
            originalRect: originalRect.scaled(xScale: xScale, yScale: yScale),
            croppedRect: croppedRect.scaled(xScale: xScale, yScale: yScale),
            src: src)
    }

    func translated(xOffset: Double, yOffset: Double) -> CropRepresentation {
        CropRepresentation(
            originalRect: originalRect.translated(
                xTranslation: xOffset, yTranslation: yOffset),
            croppedRect: croppedRect.translated(
                xTranslation: xOffset, yTranslation: yOffset),
            src: src)
    }

    func rotated(aroundOrigin origin: Point, byRadians: Double)
        -> CropRepresentation
    {
        CropRepresentation(
            originalRect: originalRect.rotated(
                aroundOrigin: origin, byRadians: byRadians),
            croppedRect: croppedRect.rotated(
                aroundOrigin: origin, byRadians: byRadians),
            src: src)
    }

    func getSVG() -> String {
        func int(_ dbl: Double) -> Int {
            Int(ceil(dbl))
        }
        let doc = Document {
            Svg {
                Polygon([
                    originalRect.tl.x, originalRect.tl.y,
                    originalRect.tr.x, originalRect.tr.y,
                    originalRect.br.x, originalRect.br.y,
                    originalRect.bl.x, originalRect.bl.y,
                ])
                Polygon([
                    croppedRect.tl.x, croppedRect.tl.y,
                    croppedRect.tr.x, croppedRect.tr.y,
                    croppedRect.br.x, croppedRect.br.y,
                    croppedRect.bl.x, croppedRect.bl.y,
                ])
            }.width(int(originalRect.rWidth))
                .height(int(originalRect.rHeight))
                .viewBox(
                    minX: int(originalRect.minX), minY: int(originalRect.minY),
                    width: int(originalRect.rWidth),
                    height: int(originalRect.rHeight)
                )
                .fill("none")
                .stroke("black")
                .strokeWidth(1)
        }
        let renderer = DocumentRenderer(minify: false, indent: 4)

        return renderer.render(doc)
    }

    struct Point: Codable {
        var x, y: Double

        func scaled(xScale: Double, yScale: Double) -> Point {
            Point(x: x * xScale, y: y * yScale)
        }

        func translated(xTranslation: Double, yTranslation: Double) -> Point {
            Point(x: x + xTranslation, y: y + yTranslation)
        }

        func rotated(aroundOrigin origin: Point, byRadians: Double) -> Point {
            // https://stackoverflow.com/questions/35683376/rotating-a-cgpoint-around-another-cgpoint/35683523
            let dx = self.x - origin.x
            let dy = self.y - origin.y
            let radius = sqrt(dx * dx + dy * dy)
            let azimuth = atan2(dy, dx)
            let newAzimuth = azimuth + byRadians
            let x = origin.x + radius * cos(newAzimuth)
            let y = origin.y + radius * sin(newAzimuth)
            return Point(x: x, y: y)
        }
    }

    struct Rect: Codable {
        static let minDoubleValue: Double = -Double.infinity
        static let maxDoubleValue: Double = Double.infinity
        var tl, tr, br, bl: Point

        var center: Point {
            Point(
                x: (tl.x + tr.x + br.x + bl.x) / 4,
                y: (tl.y + tr.y + br.y + bl.y) / 4)
        }

        init(tl: Point, tr: Point, br: Point, bl: Point) {
            self.tl = tl
            self.tr = tr
            self.br = br
            self.bl = bl
        }

        init(tl: Point, br: Point) {
            self.tl = tl
            self.tr = Point(x: br.x, y: tl.y)
            self.br = br
            self.bl = Point(x: tl.x, y: br.y)
        }

        var width: Double { br.x - tl.x }
        var height: Double { br.y - tl.y }
        var minX: Double {
            [tl, tr, br, bl]
                .map(\.x)
                .reduce(Self.maxDoubleValue, Double.minimum)
        }
        var maxX: Double {
            [tl, tr, br, bl]
                .map(\.x)
                .reduce(Self.minDoubleValue, Double.maximum)
        }
        var minY: Double {
            [tl, tr, br, bl]
                .map(\.y)
                .reduce(Self.maxDoubleValue, Double.minimum)
        }
        var maxY: Double {
            [tl, tr, br, bl]
                .map(\.y)
                .reduce(Self.minDoubleValue, Double.maximum)
        }

        var rWidth: Double { maxX - minX }
        var rHeight: Double { maxY - minY }

        func scaled(xScale: Double, yScale: Double) -> Rect {
            Rect(
                tl: tl.scaled(xScale: xScale, yScale: yScale),
                tr: tr.scaled(xScale: xScale, yScale: yScale),
                br: br.scaled(xScale: xScale, yScale: yScale),
                bl: bl.scaled(xScale: xScale, yScale: yScale))
        }

        func translated(xTranslation: Double, yTranslation: Double) -> Rect {
            Rect(
                tl: tl.translated(
                    xTranslation: xTranslation, yTranslation: yTranslation),
                tr: tr.translated(
                    xTranslation: xTranslation, yTranslation: yTranslation),
                br: br.translated(
                    xTranslation: xTranslation, yTranslation: yTranslation),
                bl: bl.translated(
                    xTranslation: xTranslation, yTranslation: yTranslation))
        }

        func rotated(aroundOrigin origin: Point, byRadians: Double) -> Rect {
            Rect(
                tl: tl.rotated(aroundOrigin: origin, byRadians: byRadians),
                tr: tr.rotated(aroundOrigin: origin, byRadians: byRadians),
                br: br.rotated(aroundOrigin: origin, byRadians: byRadians),
                bl: bl.rotated(aroundOrigin: origin, byRadians: byRadians))
        }
    }

}

typealias Rect = CropRepresentation.Rect
typealias Point = CropRepresentation.Point

struct CropRenderInfo: Codable {

    struct WH: Codable {
        var w: Double
        var h: Double
    }

    struct ImageInfo: Codable {
        var src: String
        var pos: CropRepresentation.Point
        var wh: WH
    }

    var original: CropRepresentation.Rect
    var img: ImageInfo
}

extension CropRenderInfo {
    init(croppedRepresentation cr: CropRepresentation) {
        self.original = cr.originalRect
        self.img = .init(
            src: cr.src,
            pos: cr.croppedRect.tl,
            wh: .init(
                w: cr.croppedRect.width,
                h: cr.croppedRect.height))
    }
}
