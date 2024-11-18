//
//  ImageMetaData.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 11/24/23.
//

import CoreGraphics
import CoreImage
import Foundation

final class ImageMetaData: Sendable {
    let pixelHeight: Int64
    let pixelWidth: Int64

    let iptc: ImageIPTC?
    let exif: ImageExif?

    init(for imageSource: CGImageSource) {
        let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)! as NSDictionary
        pixelHeight = getInt64(key: kCGImagePropertyPixelHeight, from: imageProperties)!
        pixelWidth = getInt64(key: kCGImagePropertyPixelWidth, from: imageProperties)!

        iptc = ImageIPTC(iptcProperties: getDictionary(key: kCGImagePropertyIPTCDictionary, from: imageProperties))
        exif = ImageExif(exifProperties: getDictionary(key: kCGImagePropertyExifDictionary, from: imageProperties))
    }
}

final class ImageIPTC: Sendable {
    let caption: String?
    let starRating: Int64

    init(iptcProperties: NSDictionary?) {
        let iptcProperties = iptcProperties
        caption = getString(key: kCGImagePropertyIPTCCaptionAbstract, from: iptcProperties)
        starRating = getInt64(key: kCGImagePropertyIPTCStarRating, from: iptcProperties) ?? 0
    }
}

final class ImageExif: Sendable {
    let captureTime: String?

    init(exifProperties: NSDictionary?) {
        let exifProperties = exifProperties
        captureTime = getString(key: kCGImagePropertyExifDateTimeDigitized, from: exifProperties)
    }
}

func getString(key: CFString, from: NSDictionary?) -> String? {
    from?.value(forKey: key as String) as? String
}

func getInt64(key: CFString, from: NSDictionary?) -> Int64? {
    from?.value(forKey: key as String) as? Int64
}

func getDictionary(key: CFString, from: NSDictionary?) -> NSDictionary? {
    from?.value(forKey: key as String) as? NSDictionary
}
