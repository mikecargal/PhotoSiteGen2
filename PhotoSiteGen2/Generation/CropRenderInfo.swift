//
//  CropRenderInfo.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 1/2/25.
//
import Foundation
import OSLog
import SwiftSvg

struct CropRepresentation: Codable {
    struct Point: Codable {
        var x, y: Double

        func scaled(xScale: Double, yScale: Double) -> Point {
            Point(x: x * xScale, y: y * yScale)
        }

        func translated(xTranslation: Double, yTranslation: Double) -> Point {
            Point(x: x + xTranslation, y: y + yTranslation)
        }

        // https://stackoverflow.com/questions/35683376/rotating-a-cgpoint-around-another-cgpoint/35683523
        func rotated(aroundOrigin origin: Point, byRadians: Double) -> Point {
            let dx = self.x - origin.x
            let dy = self.y - origin.y
            let radius = sqrt(dx * dx + dy * dy)
            let azimuth = atan2(dy, dx)  // in radians
            let newAzimuth = azimuth + byRadians
            let x = origin.x + radius * cos(newAzimuth)
            let y = origin.y + radius * sin(newAzimuth)
            return Point(x: x, y: y)
        }
    }

    struct Rect: Codable {
        var v1, v2, v3, v4: Point
        var center: Point {
            Point(
                x: (v1.x + v2.x + v3.x + v4.x) / 4,
                y: (v1.y + v2.y + v3.y + v4.y) / 4)
        }

        init(v1: Point, v2: Point, v3: Point, v4: Point) {
            self.v1 = v1
            self.v2 = v2
            self.v3 = v3
            self.v4 = v4
        }

        init(tl: Point, br: Point) {
            self.v1 = tl
            self.v2 = Point(x: br.x, y: tl.y)
            self.v3 = br
            self.v4 = Point(x: tl.x, y: br.y)
        }

        var tl: Point { v1 }
        var br: Point { v3 }
        var width: Double { v3.x - v1.x }
        var height: Double { v3.y - v1.y }
        var minX: Double {
            [v1, v2, v3, v4].reduce(Double(Int.max)) {
                Double.minimum($0, $1.x)
            }
        }
        var maxX: Double {
            [v1, v2, v3, v4].reduce(Double(Int.min)) {
                Double.maximum($0, $1.x)
            }
        }
        var minY: Double {
            [v1, v2, v3, v4].reduce(Double(Int.max)) {
                Double.minimum($0, $1.y)
            }
        }
        var maxY: Double {
            [v1, v2, v3, v4].reduce(Double(Int.min)) {
                Double.maximum($0, $1.y)
            }
        }

        var rWidth: Double { maxX - minX }
        var rHeight: Double { maxY - minY }

        func scaled(xScale: Double, yScale: Double) -> Rect {
            Rect(
                v1: v1.scaled(xScale: xScale, yScale: yScale),
                v2: v2.scaled(xScale: xScale, yScale: yScale),
                v3: v3.scaled(xScale: xScale, yScale: yScale),
                v4: v4.scaled(xScale: xScale, yScale: yScale))
        }

        func translated(xTranslation: Double, yTranslation: Double) -> Rect {
            Rect(
                v1: v1.translated(
                    xTranslation: xTranslation, yTranslation: yTranslation),
                v2: v2.translated(
                    xTranslation: xTranslation, yTranslation: yTranslation),
                v3: v3.translated(
                    xTranslation: xTranslation, yTranslation: yTranslation),
                v4: v4.translated(
                    xTranslation: xTranslation, yTranslation: yTranslation))
        }

        // https://stackoverflow.com/questions/35683376/rotating-a-cgpoint-around-another-cgpoint/35683523
        func rotated(aroundOrigin origin: Point, byRadians: Double) -> Rect {
            Rect(
                v1: v1.rotated(aroundOrigin: origin, byRadians: byRadians),
                v2: v2.rotated(aroundOrigin: origin, byRadians: byRadians),
                v3: v3.rotated(aroundOrigin: origin, byRadians: byRadians),
                v4: v4.rotated(aroundOrigin: origin, byRadians: byRadians))
        }
    }

    var originalRect: Rect
    var croppedRect: Rect
    let src: String
    func scaled(scale: Double) -> CropRepresentation {
        CropRepresentation(
            originalRect: originalRect.scaled(xScale: scale, yScale: scale),
            croppedRect: croppedRect.scaled(xScale: scale, yScale: scale),
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
    // https://stackoverflow.com/questions/35683376/rotating-a-cgpoint-around-another-cgpoint/35683523
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
                    originalRect.v1.x, originalRect.v1.y,
                    originalRect.v2.x, originalRect.v2.y,
                    originalRect.v3.x, originalRect.v3.y,
                    originalRect.v4.x, originalRect.v4.y,
                ])
                Polygon([
                    croppedRect.v1.x, croppedRect.v1.y,
                    croppedRect.v2.x, croppedRect.v2.y,
                    croppedRect.v3.x, croppedRect.v3.y,
                    croppedRect.v4.x, croppedRect.v4.y,
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
        // TODO:
        self.original = cr.originalRect
        self.img = .init(
            src: cr.src,
            pos: cr.croppedRect.tl,
            wh: .init(
                w: cr.croppedRect.width,
                h: cr.croppedRect.height))
    }
}

struct CropRenderer {
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
                tl: Point(x: 0, y: 0), br: Point(x: unCroppedW, y: unCroppedH)),
            croppedRect: Rect(
                tl: Point(x: left * unCroppedW, y: top * unCroppedH),
                br: Point(x: right * unCroppedW, y: bottom * unCroppedH)
            ),
            src: imageSrc)
        Self.logger.debug("\(croppedRepresentation.getSVG())")

        // rotate the crop representation
        croppedRepresentation = croppedRepresentation.rotated(
            aroundOrigin: croppedRepresentation.originalRect.center,
            byRadians: -radAngle)
        Self.logger.debug("\(croppedRepresentation.getSVG())")

        // with crop level, rebuild crop using top-left and bottom-right
        let croppedRect: CropRepresentation.Rect =
            Rect(
                tl: croppedRepresentation.croppedRect.tl,
                br: croppedRepresentation.croppedRect.br)
        croppedRepresentation.croppedRect = croppedRect
        Self.logger.debug("\(croppedRepresentation.getSVG())")

        var origRect = croppedRepresentation.originalRect

        // translate to minX = minY = 0
        let tx = -origRect.minX
        let ty = -origRect.minY
        croppedRepresentation =
            croppedRepresentation
            .translated(xOffset: tx, yOffset: ty)
        Self.logger.debug("\(croppedRepresentation.getSVG())")

        // scale to fit in 200 x 200 canvas
        let scaleTo200 =
            origRect.rWidth > origRect.rHeight
            ? maxWH / origRect.rWidth : maxWH / origRect.rHeight
        Self.logger.debug(
            "origRect.rWidth: \(origRect.rWidth), origRect.rHeight: \(origRect.rHeight), scaleTo200: \(scaleTo200)"
        )

        croppedRepresentation =
            croppedRepresentation
            .scaled(scale: scaleTo200)
        Self.logger.debug("\(croppedRepresentation.getSVG())")
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
        Self.logger.debug("\(croppedRepresentation.getSVG())")
        return CropRenderInfo(croppedRepresentation: croppedRepresentation)
    }

    func getUncroppedWH(
        top: Double, bottom: Double, left: Double, right: Double
    ) -> (w: Double, h: Double) {
        let rect = Rect(
            tl: Point(x: 0, y: 0),
            br: Point(x: Double(imageW), y: Double(imageH))
        )
        .rotated(aroundOrigin: Point(x: 0, y: 0), byRadians: deg2rad(angle))
        let rw = rect.br.x - rect.tl.x
        let rh = rect.br.y - rect.tl.y
        let w_pct = right - left
        let h_pct = bottom - top
        let w = rw / w_pct
        let h = rh / h_pct
        return (w: w, h: h)
    }

    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
}
