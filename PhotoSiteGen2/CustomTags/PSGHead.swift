//
//  PSGHead.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 12/11/23.
//

import Foundation
import SwiftHtml

class PSGHead: GroupTag {
    public init(preloads: [PreLoad] = [], generationID: TSID) {
        let children = [
            Head {
                Title("Mike Cargal's Photography Site")
                Meta().charset("utf-8")
                Meta().name(.viewport).content("width=device-width, initial-scale=1")
                Link(rel: .stylesheet).href("css/styles.css?tsid=\(generationID)")
                Link(rel: .icon).href("/images/favicon.svg?tsid=\(generationID)").type("image/svg+xml")
                Link(rel: .manifest).href("/manifest.webmanifest?tsid=\(generationID)")
                for preload in preloads {
                    Link(rel: .preload).href("\(preload.src)?tsid=\(generationID)") 
                        .attribute("imagesrcset", preload.srcset)
                        .attribute("imagesizes",  preload.srcset != nil ? "100vw" : nil)
                        .attribute("as", preload.asType.rawValue)
                }
            },
        ]
        super.init(children)
    }
}
