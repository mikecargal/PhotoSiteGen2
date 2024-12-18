//
//  XMPFields.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 12/16/24.
//

import Foundation
import RegexBuilder

class XMPFields: NSObject, XMLParserDelegate {
    static let xmpMatcher = Regex {
        "<x:xmpmeta"
        OneOrMore {
            NegativeLookahead { "</x:xmpmeta>" }
            CharacterClass.any
        }
        "</x:xmpmeta>"
    }
    var cropTop: Double? = nil
    var cropLeft: Double? = nil
    var cropBottom: Double? = nil
    var cropRight: Double? = nil
    var cropAngle: Double? = nil
    var hasCrop: Bool = false
    var preservedFileName: String? = nil
    var rawFileName: String? = nil

    let RDF_NS = "http://www.w3.org/1999/02/22-rdf-syntax-ns#"

    init(data: Data, dump: Bool) {
        super.init()
        let dataString = String(decoding: data, as: UTF8.self)
        let matches = getXMPMatches(dataString: dataString)

        for match in matches {
            let startIndex = match.lowerBound
            let endIndex = match.upperBound
            let xmlString = dataString[startIndex..<endIndex]
            if dump {
                print("===============\n\(xmlString)\n===============")
            }
            let xmlParser = XMLParser(data: Data(xmlString.utf8))
            xmlParser.delegate = self
            xmlParser.shouldProcessNamespaces = true
            xmlParser.parse()
        }
    }

    func getXMPMatches(dataString: String) -> [Range<String.Index>] {
        zip(
            dataString.ranges(of: "<x:xmpmeta"),
            dataString.ranges(of: "</x:xmpmeta>")
        )
        .map { $0.lowerBound..<$1.upperBound }
    }

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if elementName == "Description",
            namespaceURI == RDF_NS,
            (attributeDict["crs:HasCrop"]) != nil
        {
            hasCrop =
                attributeDict["crs:HasCrop"]?.lowercased() == "true"
            if hasCrop {
                cropTop = Double(attributeDict["crs:CropTop"] ?? "-1")
                cropLeft = Double(
                    attributeDict["crs:CropLeft"] ?? "-1")
                cropBottom = Double(
                    attributeDict["crs:CropBottom"] ?? "-1")
                cropRight = Double(
                    attributeDict["crs:CropRight"] ?? "-1")
                cropAngle = Double(
                    attributeDict["crs:CropAngle"] ?? "-1")
            }
            preservedFileName =
                preservedFileName ?? attributeDict["xmpMM:PreservedFileName"]
            rawFileName = rawFileName ?? attributeDict["crs:RawFileName"]
        }
    }
}
