//
//  ImageMetaData.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 11/24/23.
//

import CoreGraphics
import CoreImage
import Foundation
import RegexBuilder

final class ImageMetaData: Sendable {

    let pixelHeight: Int
    let pixelWidth: Int
    let caption: String?
    let starRating: Int
    let captureTime: String?
    let lens: String?
    let camera: String?
    let focalLength: Int?
    let subjectDistance: Double?
    let iso: Int?
    let exposureTime: Double?
    let aperture: String?
    let keywords: [String]
    let hasCrop: Bool
    let cropTop: Double?
    let cropLeft: Double?
    let cropBottom: Double?
    let cropRight: Double?
    let cropAngle: Double?
    let preservedFileName: String?
    let rawFileName: String?
    let copyright: String?
    let exposureComp: String?

    init(url: URL) {
        let data = try! Data(contentsOf: url)
        let imageSource = CGImageSourceCreateWithData(data as CFData, nil)!
        let imageProperties =
            CGImageSourceCopyPropertiesAtIndex(
                imageSource, 0, nil)! as NSDictionary
        let iptcProperties =
            Self.getDictionary(
                key: kCGImagePropertyIPTCDictionary,
                from: imageProperties) as NSDictionary?
        let exifProperties =
            Self.getDictionary(
                key: kCGImagePropertyExifDictionary,
                from: imageProperties) as NSDictionary?
        let tiffProperties =
            Self.getDictionary(
                key: kCGImagePropertyTIFFDictionary,
                from: imageProperties) as NSDictionary?

        pixelHeight = Self.getInt(
            key: kCGImagePropertyPixelHeight,
            from: imageProperties)!
        pixelWidth = Self.getInt(
            key: kCGImagePropertyPixelWidth,
            from: imageProperties)!
        caption = Self.getString(
            key: kCGImagePropertyIPTCCaptionAbstract,
            from: iptcProperties)
        copyright = Self.getString(
            key: kCGImagePropertyIPTCCopyrightNotice,
            from: iptcProperties)
        starRating =
            Self.getInt(
                key: kCGImagePropertyIPTCStarRating,
                from: iptcProperties)
            ?? 0
        captureTime = Self.getString(
            key: kCGImagePropertyExifDateTimeDigitized,
            from: exifProperties)
        camera = Self.getString(
            key: kCGImagePropertyTIFFModel,
            from: tiffProperties)
        lens = Self.getString(
            key: kCGImagePropertyExifLensModel,
            from: exifProperties)
        focalLength =
            Self.getNumber(
                key: kCGImagePropertyExifFocalLength,
                from: exifProperties)?.intValue
        subjectDistance = Self.getDouble(
            key: kCGImagePropertyExifSubjectDistance,
            from: exifProperties)
        iso =
            Self.getIntArray(
                key: kCGImagePropertyExifISOSpeedRatings,
                from: exifProperties)?[0].intValue
        exposureTime = Self.getDouble(
            key: kCGImagePropertyExifExposureTime,
            from: exifProperties)
        aperture =
            Self.getNumber(
                key: kCGImagePropertyExifFNumber,
                from: exifProperties)?.stringValue
        keywords =
            Self.getStringArray(
                key: kCGImagePropertyIPTCKeywords,
                from: iptcProperties) ?? []
        exposureComp = Self.getString(
            key: kCGImagePropertyExifExposureBiasValue,
            from: exifProperties)

        let xmpFields = XMPFields(
            data: data, dump: false)  // url.lastPathComponent.contains("9777"))
        hasCrop = xmpFields.hasCrop
        cropTop = xmpFields.cropTop
        cropLeft = xmpFields.cropLeft
        cropBottom = xmpFields.cropBottom
        cropRight = xmpFields.cropRight
        cropAngle = xmpFields.cropAngle
        preservedFileName = Self.cleanUpFilename(
            filename: xmpFields.preservedFileName)
        rawFileName = Self.cleanUpFilename(filename: xmpFields.rawFileName)
    }

    static private let REM_REGEX =
        #"[\-_](DxO|CR(2|3)[\._-]|Enhanced|NR[\._-]|\d{8}|\-?[Ee]dit).*?\.(jpg|dng|CR2|CR3|tif|tiff|psd)$"#
    static private let SUFFIX_REGEX = #"\.(jpg|JPG|dng|CR2|CR3|tif|tiff|psd)$"#
    static func cleanUpFilename(filename: String?) -> String? {
        guard let filename else { return nil }
        let res =
            filename
            .replacingOccurrences(
                of: REM_REGEX, with: "", options: .regularExpression
            )
            .replacingOccurrences(
                of: Self.SUFFIX_REGEX, with: "", options: .regularExpression
            )
//        debugPrint("cleanUpFilename:  \(res)      -> \(filename)")
        if res.isEmpty {
            debugPrint(
                "============= uh oh =============\n\\(filename)\n=================="
            )
        }
        return res
    }

    static func getString(key: CFString, from: NSDictionary?) -> String? {
        from?.value(forKey: key as String) as? String
    }

    static func getInt(key: CFString, from: NSDictionary?) -> Int? {
        from?.value(forKey: key as String) as? Int
    }

    static func getDictionary(key: CFString, from: NSDictionary?)
        -> NSDictionary?
    {
        from?.value(forKey: key as String) as? NSDictionary
    }

    static func getDouble(key: CFString, from: NSDictionary?) -> Double? {
        from?.value(forKey: key as String) as? Double
    }

    static func getNumber(key: CFString, from: NSDictionary?) -> NSNumber? {
        from?.value(forKey: key as String) as? NSNumber
    }

    static func getIntArray(key: CFString, from: NSDictionary?) -> [NSNumber]? {
        from?.value(forKey: key as String) as? [NSNumber]
    }

    static func getStringArray(key: CFString, from: NSDictionary?) -> [String]?
    {
        from?.value(forKey: key as String) as? [String]
    }
}
