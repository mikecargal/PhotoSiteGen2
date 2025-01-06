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
        func rotated(angle: Double, aroundOrigin: Point) -> RotRect {
            RotRect(corners: [
                CropRenderer.rotatePoint(
                    target: v1, aroundOrigin: aroundOrigin, byRadians: angle),
                CropRenderer.rotatePoint(
                    target: v2, aroundOrigin: aroundOrigin, byRadians: angle),
                CropRenderer.rotatePoint(
                    target: v3, aroundOrigin: aroundOrigin, byRadians: angle),
                CropRenderer.rotatePoint(
                    target: v4, aroundOrigin: aroundOrigin, byRadians: angle),
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

    var br: RotRect  // br == Big Rect (i.e. uncropped image representation)
    var img: ImageInfo
    func normalized(translater: Translate, scaler: Scale) -> CropRenderInfo {
        CropRenderInfo(
            br: br.normalized(translater: translater, scaler: scaler),
            img: img.normalized(translater: translater, scaler: scaler))
    }
}

struct CropRenderer {

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
        let radAngle = deg2rad(-angle)

        let (w, h) =
            switch orientation {
            case .orient0: (imageW, imageH)
            case .orient90: (imageH, imageW)
            case .orient180: (imageW, imageH)
            case .orient270: (imageH, imageW)
            }

        let uncroppedWH = uncroppedWH(
            imageW: imageW, imageH: imageH,
            cropTop: cropTop, cropBottom: cropBottom, cropLeft: cropLeft, cropRight: cropRight,
//            cropWPct: cropRight - cropLeft,
//            cropHPct: cropBottom - cropTop,
            radAngle: radAngle)

        var rotatedCorners = uncroppedWH.corners().map {
            Self.rotatePoint(
                target: $0, aroundOrigin: uncroppedWH.center(),
                byRadians: radAngle)
        }

        // get rotated coordinates of crop TL & BR
        let unrotatedCropTopLeft = Point(
            x: cropLeft * uncroppedWH.w, y: cropTop * uncroppedWH.h)
        let unrotatedCropBottomRight = Point(
            x: cropRight * uncroppedWH.w, y: cropBottom * uncroppedWH.h)
        var actualCropTopLeft = Self.rotatePoint(
            target: unrotatedCropTopLeft,
            aroundOrigin: uncroppedWH.center(), byRadians: radAngle)
        var actualCropBottomRight = Self.rotatePoint(
            target: unrotatedCropBottomRight,
            aroundOrigin: uncroppedWH.center(), byRadians: radAngle)
        
        switch orientation {
        case .orient90:
            let tr = Self.rotatePoint(
                target: actualCropTopLeft, aroundOrigin: uncroppedWH.center(),
                byRadians: deg2rad(90))
            let bl = Self.rotatePoint(
                target: actualCropBottomRight,
                aroundOrigin: uncroppedWH.center(), byRadians: deg2rad(90))
            actualCropTopLeft = Point(x: bl.x, y: tr.y)
            actualCropBottomRight = Point(x: tr.x, y: bl.y)
            rotatedCorners = rotatedCorners.map {
                Self.rotatePoint(
                    target: $0, aroundOrigin: uncroppedWH.center(),
                    byRadians: deg2rad(90))
            }
        case .orient180:
            actualCropBottomRight = Self.rotatePoint(
                target: actualCropTopLeft, aroundOrigin: uncroppedWH.center(),
                byRadians: deg2rad(180))
            actualCropTopLeft = Self.rotatePoint(
                target: actualCropBottomRight,
                aroundOrigin: uncroppedWH.center(), byRadians: deg2rad(180))
            rotatedCorners = rotatedCorners.map {
                Self.rotatePoint(
                    target: $0, aroundOrigin: uncroppedWH.center(),
                    byRadians: deg2rad(180))
            }
        case .orient270:
            let bl = Self.rotatePoint(
                target: actualCropTopLeft, aroundOrigin: uncroppedWH.center(),
                byRadians: deg2rad(270))
            let tr = Self.rotatePoint(
                target: actualCropBottomRight,
                aroundOrigin: uncroppedWH.center(), byRadians: deg2rad(270))
            actualCropTopLeft = Point(x: bl.x, y: tr.y)
            actualCropBottomRight = Point(x: tr.x, y: bl.y)
            rotatedCorners = rotatedCorners.map {
                Self.rotatePoint(
                    target: $0, aroundOrigin: uncroppedWH.center(),
                    byRadians: deg2rad(270))
            }
        default: break
        }
        
        let actualCropPosition = actualCropTopLeft
        let actualCropWH =  // WH(w: Double(imageW), h: Double(imageH))
            WH(  // should match input dimensions (approximately)
                w: actualCropBottomRight.x - actualCropTopLeft.x,
                h: actualCropBottomRight.y - actualCropTopLeft.y)

        let imageInfo = CropRenderInfo.ImageInfo(
            src: imageSrc, pos: actualCropPosition, wh: actualCropWH)
        let br = CropRenderInfo.RotRect(corners: rotatedCorners)

        // Determine final translate and scale
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
        return CropRenderInfo(br: br, img: imageInfo).normalized(
            translater: translater, scaler: scaler)
    }
    func uncroppedWH(
        imageW: Int,
        imageH: Int,
        cropTop: Double,
        cropBottom: Double,
        cropLeft: Double,
        cropRight: Double,
        radAngle: Double
    ) -> WH {
        let tl = Point(x: cropLeft, y: cropTop)
        let br = Point(x: cropRight, y: cropBottom)
        let center = Point(x: 0.5, y: 0.5)
        let rtl = Self.rotatePoint(
            target: tl, aroundOrigin: center, byRadians: radAngle)
        let rbr = Self.rotatePoint(
            target: br, aroundOrigin: center, byRadians: radAngle)
        // rtl and rbr should now be "square" o degrees and 90 degrees sides
        let rtr = Point(x: rbr.x, y: rtl.y)
        let rbl = Point(x: rtl.x, y: rbr.y)
        // r* points refeclt actual square size (as a percent)
        // rotate tr and bl back to relative positions
        let tr = Self.rotatePoint(
            target: rtr, aroundOrigin: center, byRadians: -radAngle)
        let bl = Self.rotatePoint(
            target: rbl, aroundOrigin: center, byRadians: -radAngle)
        
        let w_pct = abs(tr.x - tl.x)
        let h_pct = abs(tl.y - bl.y)
        return WH(w: sin(radAngle) * Double(imageW) / w_pct,
                  h: sin(radAngle) *  Double(imageH) / h_pct)
        //    let cosA = cos(-radAngle)
        //    let secA = 1 / cosA
        //    let tanA = tan(-radAngle)
    }

    func uncroppedWH_old(
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
    static func rotatePoint(
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
