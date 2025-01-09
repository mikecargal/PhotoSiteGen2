//
//  CropRenderInfo.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 1/2/25.
//
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
