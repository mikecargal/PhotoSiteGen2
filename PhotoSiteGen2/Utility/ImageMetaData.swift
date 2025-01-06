//
//  ImageMetaData.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 11/24/23.
//

import CoreGraphics
import CoreImage
import Foundation
import OSLog
import RegexBuilder

typealias Resolution = (w: Int, h: Int)

struct ImageMetaData: Sendable, Codable {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: String(describing: Self.self)
    )
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
    let directives: [String]
    let hasCrop: Bool
    let preservedFileName: String?
    let rawFileName: String?
    let copyright: String?
    let exposureComp: String?
    let cropRenderInfo: CropRenderInfo?

    init(url: URL, imgSrc: String) {
        var subjectDistance: Double?
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
        let kw =
            Self.getStringArray(
                key: kCGImagePropertyIPTCKeywords,
                from: iptcProperties) ?? []

        directives = kw.filter { $0.starts(with: "#") }
        keywords = kw.filter { !$0.starts(with: "#") }
        //            Self.getStringArray(
        //                key: kCGImagePropertyIPTCKeywords,
        //                from: iptcProperties) ?? []
        exposureComp = Self.getString(
            key: kCGImagePropertyExifExposureBiasValue,
            from: exifProperties)

        let xmpFields = XMPFields(
            data: data, dump: false)  // url.lastPathComponent.contains("9777"))

        preservedFileName = Self.cleanUpFilename(
            filename: xmpFields.preservedFileName)
        rawFileName = Self.cleanUpFilename(filename: xmpFields.rawFileName)
        if subjectDistance == nil {
            subjectDistance = xmpFields.subjectDistance
        }
        self.subjectDistance = subjectDistance

        hasCrop = xmpFields.hasCrop
        let cropTop = xmpFields.cropTop
        let cropLeft = xmpFields.cropLeft
        let cropBottom = xmpFields.cropBottom
        let cropRight = xmpFields.cropRight
        let cropAngle = xmpFields.cropAngle
        if let cropAngle, let cropTop, let cropBottom, let cropLeft,
            let cropRight
        {
            //            var top: Double
            //            var bottom: Double
            //            var left: Double
            //            var right: Double
            //
            //            if directives.contains("#rotate90") {
            //                (top, bottom, left, right) = (
            //                    cropLeft, cropRight, cropTop, cropBottom
            //                )
            //            } else {
            //                (top, bottom, left, right) = (
            //                    cropTop, cropBottom, cropLeft, cropRight
            //                )
            //            }
            var orientation: CropRenderer.Orientation =
                switch true {
                case directives.contains("#rotate90"): .orient90
                case directives.contains("#rotate180"): .orient180
                case directives.contains("#rotate270"): .orient270
                default: .orient0
                }
            if imgSrc.contains("IMG_0088") {
//                orientation = .orient270
            }
            cropRenderInfo =
                CropRenderer(
                    imageW: pixelWidth,
                    imageH: pixelHeight,
                    angle: cropAngle,
                    cropTop: cropTop,
                    cropBottom: cropBottom,
                    cropLeft: cropLeft,
                    cropRight: cropRight,
                    imageSrc: imgSrc,
                    orientation: orientation
                )
                .getCropInfo(maxWH: 200)
            //        }
        } else {
            cropRenderInfo = nil
        }
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
        if res.isEmpty {
            logger.error(
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
