//
//  PreLoad.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 12/7/24.
//

import Foundation
import SwiftHtml

enum PreloadType: String {
    case image, fetch, script, style, track, font
}

struct PreLoad {
    let src: String
    let srcset: String?
    let asType: PreloadType

    init(src: String, srcset: String? = nil, asType: PreloadType = .image) {
        self.src = src
        self.srcset = srcset
        self.asType = asType
    }
    
    func link(generationID:TSID) -> Tag {
        Link(rel: .preload).href("\(src)?tsid=\(generationID)")
            .attribute("imagesrcset", srcset)
            .attribute("imagesizes",  srcset != nil ? "100vw" : nil)
            .attribute("as", asType.rawValue)
    }
}
