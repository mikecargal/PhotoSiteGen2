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
    let copyright: String?

    init(url: URL) {
        let data = try! Data(contentsOf: url)
        let imageSource = CGImageSourceCreateWithData(data as CFData, nil)!
        let imageProperties =
            CGImageSourceCopyPropertiesAtIndex(
                imageSource, 0, nil)! as NSDictionary
        let iptcProperties =
            getDictionary(
                key: kCGImagePropertyIPTCDictionary,
                from: imageProperties) as NSDictionary?
        let exifProperties =
            getDictionary(
                key: kCGImagePropertyExifDictionary,
                from: imageProperties) as NSDictionary?
        let tiffProperties =
            getDictionary(
                key: kCGImagePropertyTIFFDictionary,
                from: imageProperties) as NSDictionary?

        pixelHeight = getInt(
            key: kCGImagePropertyPixelHeight,
            from: imageProperties)!
        pixelWidth = getInt(
            key: kCGImagePropertyPixelWidth,
            from: imageProperties)!
        caption = getString(
            key: kCGImagePropertyIPTCCaptionAbstract,
            from: iptcProperties)
        copyright = getString(
            key: kCGImagePropertyIPTCCopyrightNotice,
            from: iptcProperties)
        starRating =
            getInt(
                key: kCGImagePropertyIPTCStarRating,
                from: iptcProperties)
            ?? 0
        captureTime = getString(
            key: kCGImagePropertyExifDateTimeDigitized,
            from: exifProperties)
        camera = getString(
            key: kCGImagePropertyTIFFModel,
            from: tiffProperties)
        lens = getString(
            key: kCGImagePropertyExifLensModel,
            from: exifProperties)
        focalLength =
            getNumber(
                key: kCGImagePropertyExifFocalLength,
                from: exifProperties)?.intValue
        subjectDistance = getDouble(
            key: kCGImagePropertyExifSubjectDistance,
            from: exifProperties)
        iso =
            getIntArray(
                key: kCGImagePropertyExifISOSpeedRatings,
                from: exifProperties)?[0].intValue
        exposureTime = getDouble(
            key: kCGImagePropertyExifExposureTime,
            from: exifProperties)
        aperture =
            getNumber(
                key: kCGImagePropertyExifFNumber,
                from: exifProperties)?.stringValue
        keywords =
            getStringArray(
                key: kCGImagePropertyIPTCKeywords,
                from: iptcProperties) ?? []
        let xmpFields = getXMPFields(data: data, dump: false)
        hasCrop = xmpFields.hasCrop
        cropTop = xmpFields.cropTop
        cropLeft = xmpFields.cropLeft
        cropBottom = xmpFields.cropBottom
        cropRight = xmpFields.cropRight
        cropAngle = xmpFields.cropAngle
        preservedFileName = xmpFields.preservedFileName
    }

    func getHtml() {

    }
}

func getString(key: CFString, from: NSDictionary?) -> String? {
    from?.value(forKey: key as String) as? String
}

func getInt(key: CFString, from: NSDictionary?) -> Int? {
    from?.value(forKey: key as String) as? Int
}

func getDictionary(key: CFString, from: NSDictionary?) -> NSDictionary? {
    from?.value(forKey: key as String) as? NSDictionary
}

func getDouble(key: CFString, from: NSDictionary?) -> Double? {
    from?.value(forKey: key as String) as? Double
}

func getNumber(key: CFString, from: NSDictionary?) -> NSNumber? {
    from?.value(forKey: key as String) as? NSNumber
}

func getIntArray(key: CFString, from: NSDictionary?) -> [NSNumber]? {
    from?.value(forKey: key as String) as? [NSNumber]
}

func getStringArray(key: CFString, from: NSDictionary?) -> [String]? {
    from?.value(forKey: key as String) as? [String]
}

struct XMPFields {
    var cropTop: Double? = nil
    var cropLeft: Double? = nil
    var cropBottom: Double? = nil
    var cropRight: Double? = nil
    var cropAngle: Double? = nil
    var hasCrop: Bool = false
    var preservedFileName: String? = nil
}

func getXMPFields(data: Data, dump: Bool) -> XMPFields {
    let dataString = String(decoding: data, as: UTF8.self)
    let beginRange = dataString.range(of: "<?xpacket begin")
    let endRange = dataString.range(
        of: "<?xpacket end.*?>", options: .regularExpression)
    if beginRange == nil || endRange == nil {
        print("parseXmpMetaData: did not find tags\n")
        return XMPFields()
    }
    let startIndex = beginRange!.lowerBound
    let endIndex = endRange!.upperBound
    let xmlString = String(dataString[startIndex..<endIndex])
    if dump {
        print("XML doc length is \(xmlString.count)")
        print("XML String to parse is \(xmlString)")
    }
    let xmlParser = XMLParser(data: Data(xmlString.utf8))
    let mpd = XmpParserDelegate()
    mpd.dump = dump
    xmlParser.delegate = mpd
    xmlParser.shouldProcessNamespaces = true
    xmlParser.parse()
    return mpd.xmpFields
}

enum XMPFieldEnum {
    case none, hasCrop, cropTop, cropLeft, cropBottom, cropRight, cropAngle
}

class XmpParserDelegate: NSObject, XMLParserDelegate {
    let RDF_NS = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    var xmpFields = XMPFields()
    private var currentElement: XMPFieldEnum = .none

    var dump: Bool = false

    func parser(
        _ parser: XMLParser, didStartElement elementName: String,
        namespaceURI: String?, qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if elementName == "Description",
            namespaceURI == RDF_NS,
            (attributeDict["crs:HasCrop"]) != nil
        {
            xmpFields.hasCrop =
                attributeDict["crs:HasCrop"]?.lowercased() == "true"
            if xmpFields.hasCrop {
                xmpFields.cropTop = Double(attributeDict["crs:CropTop"] ?? "-1")
                xmpFields.cropLeft = Double(
                    attributeDict["crs:CropLeft"] ?? "-1")
                xmpFields.cropBottom = Double(
                    attributeDict["crs:CropBottom"] ?? "-1")
                xmpFields.cropRight = Double(
                    attributeDict["crs:CropRight"] ?? "-1")
                xmpFields.cropAngle = Double(
                    attributeDict["crs:CropAngle"] ?? "-1")
            }
            xmpFields.preservedFileName =
                attributeDict["xmpMM:PreservedFileName"]
        }
    }
}
