//
//  FileFilters.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 1/17/24.
//

import Foundation
import RegexBuilder

protocol FileFilter {
    func filter(_: String) throws -> String
}

struct InlineStyleSheetFilter: FileFilter {
    let staticFilesURL: URL
    func filter(_ input: String) throws -> String {
        let lines = input.components(separatedBy: .newlines)

        var ra = [String]()
        ra.reserveCapacity(lines.count)

        let cssLocationReference = Reference(URL.self)
        let linkRegex = Regex { // ex: <link rel=stylesheet href="css/siteLogo.css">
            Anchor.startOfLine
            Optionally {
                OneOrMore(.whitespace)
            }
            "<link"
            Optionally {
                OneOrMore(.whitespace)
            }
            "rel=stylesheet"
            Optionally {
                OneOrMore(.whitespace)
            }
            "href=\""
            Capture(as: cssLocationReference) {
                OneOrMore(.any,.reluctant)
            } transform: { text in
                staticFilesURL.appending(path: text)
            }
            "\">"
            Optionally {
                OneOrMore(.whitespace)
            }
            Anchor.endOfLine
        }

        for line in lines {
            if let matches = try? linkRegex.wholeMatch(in: line) {
                ra.append("<!-- \(line) -->")
                ra.append("<style>")
                ra.append(try String(contentsOf: matches[cssLocationReference], encoding: .utf8))
                ra.append("</style>")
            } else {
                ra.append(line)
            }
        }

        return ra.joined(separator: "\n")
    }
}
