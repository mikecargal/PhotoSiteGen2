//
//  CropRenderInfo.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 1/2/25.
//
import Foundation

typealias Translate = (Point) -> (Point)
typealias Scale = (Double) -> Double

struct WH: Codable {
    var w, h: Double
    func center() -> Point {
        Point(x: w / 2, y: h / 2)
    }
    func corners() -> [Point] {
        [
            Point(x: 0, y: 0),
            Point(x: w, y: 0),
            Point(x: w, y: h),
            Point(x: 0, y: h),
        ]
    }
    func normalized(scaler: Scale) -> WH {
        WH(w: scaler(w), h: scaler(h))
    }
}

struct Point: Codable {
    var x, y: Double
    func scaled(scale: Scale) -> Point {
        Point(x: scale(x), y: scale(y))
    }

    func normalized(translate: Translate, scale: Scale) -> Point {
        translate(self).scaled(scale: scale)
    }
}

struct CropRenderInfo: Codable {
    struct RotRect: Codable {
        var v1, v2, v3, v4: Point
        init(corners: [Point]) {
            v1 = corners[0]
            v2 = corners[1]
            v3 = corners[2]
            v4 = corners[3]
        }
        func normalized(translater: Translate, scaler: Scale)
            -> RotRect
        {
            RotRect(corners: [
                v1.normalized(translate: translater, scale: scaler),
                v2.normalized(translate: translater, scale: scaler),
                v3.normalized(translate: translater, scale: scaler),
                v4.normalized(translate: translater, scale: scaler),
            ])

        }
    }
    struct ImageInfo: Codable {
        var src: String
        var pos: Point
        var wh: WH
        func normalized(translater: Translate, scaler: Scale)
            -> ImageInfo
        {
            ImageInfo(
                src: src,
                pos: pos.normalized(translate: translater, scale: scaler),
                wh: wh.normalized(scaler: scaler))
        }
    }

    var br: RotRect
    var img: ImageInfo
    func normalized(translater: Translate, scaler: Scale) -> CropRenderInfo {
        CropRenderInfo(
            br: br.normalized(translater: translater, scaler: scaler),
            img: img.normalized(translater: translater, scaler: scaler))
    }
}

struct CropRenderer {
    var imageW, imageH: Int
    var angle, cropTop, cropBottom, cropLeft, cropRight: Double
    var imageSrc: String
    func getCropInfo(maxWH: Double) -> CropRenderInfo {
        let radAngle = deg2rad(-angle)
        let uncroppedWH = uncroppedWH(
            imageW: imageW, imageH: imageH,
            cropWPct: cropRight - cropLeft,
            cropHPct: cropBottom - cropTop,
            radAngle: radAngle)

        let rotatedCorners = uncroppedWH.corners().map {
            rotatePoint(
                target: $0, aroundOrigin: uncroppedWH.center(),
                byRadians: radAngle)
        }
        let minX = rotatedCorners.reduce(Double(Int.max)) {
            Double.minimum($0, $1.x)
        }
        let maxX = rotatedCorners.reduce(Double(Int.min)) {
            Double.maximum($0, $1.x)
        }
        let minY = rotatedCorners.reduce(Double(Int.max)) {
            Double.minimum($0, $1.y)
        }
        let maxY = rotatedCorners.reduce(Double(Int.min)) {
            Double.maximum($0, $1.y)
        }

        let scaler: Scale = { value in
            let scale = maxWH / Double.maximum(maxX - minX, maxY - minY)
            return value * scale
        }
        let translater: Translate = { point in
            let maxMax = Double.maximum(maxX, maxY)
            // adjust to center vertically & horizontally
            let xAdjust = (maxMax - maxX) / 2
            let yAdjust = (maxMax - maxY) / 2
            return Point(
                x: xAdjust + point.x - minX,
                y: yAdjust + point.y - minY)
        }

        // get rotated coordinates of crop TL & BR
        let unrotatedCropTopLeft = Point(
            x: cropLeft * uncroppedWH.w, y: cropTop * uncroppedWH.h)
        let unrotatedCropBottomRight = Point(
            x: cropRight * uncroppedWH.w, y: cropBottom * uncroppedWH.h)
        let actualCropTopLeft = rotatePoint(
            target: unrotatedCropTopLeft,
            aroundOrigin: uncroppedWH.center(), byRadians: radAngle)
        let actualCropBottomRight = rotatePoint(
            target: unrotatedCropBottomRight,
            aroundOrigin: uncroppedWH.center(), byRadians: radAngle)

        let actualCropPosition = actualCropTopLeft
        let actualCropWH =  // WH(w: Double(imageW), h: Double(imageH))
            WH(  // should match input dimensions (approximately)
                w: actualCropBottomRight.x - actualCropTopLeft.x,
                h: actualCropBottomRight.y - actualCropTopLeft.y)

        let imageInfo = CropRenderInfo.ImageInfo(
            src: imageSrc, pos: actualCropPosition, wh: actualCropWH)
        let br = CropRenderInfo.RotRect(corners: rotatedCorners)
        return CropRenderInfo(br: br, img: imageInfo).normalized(
            translater: translater, scaler: scaler)
    }

    func uncroppedWH(
        imageW: Int,
        imageH: Int,
        cropWPct: Double,
        cropHPct: Double,
        radAngle: Double
    ) -> WH {
        // reference diagram for vertex labels
        // crop.svg (θ in diagram is -radAngle)
        let cosA = cos(-radAngle)
        let secA = 1 / cosA
        let tanA = tan(-radAngle)
        let fp = Double(imageW)
        let jp = Double(imageH)

        let rp = tanA * jp
        let fr = fp - rp
        let bc = cosA * fr
        let ab = bc / cropWPct

        let jr = secA * jp
        let gr = tanA * fr
        let gj = jr + gr
        let cn = gj / cropHPct

        return WH(w: ab, h: cn)
    }

    // https://stackoverflow.com/questions/35683376/rotating-a-cgpoint-around-another-cgpoint/35683523
    func rotatePoint(
        target: Point, aroundOrigin origin: Point, byRadians: Double
    ) -> Point {
        let dx = target.x - origin.x
        let dy = target.y - origin.y
        let radius = sqrt(dx * dx + dy * dy)
        let azimuth = atan2(dy, dx)  // in radians
        let newAzimuth = azimuth + byRadians
        let x = origin.x + radius * cos(newAzimuth)
        let y = origin.y + radius * sin(newAzimuth)
        return Point(x: x, y: y)
    }

    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }

}
