//
//  PSGHead.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 12/11/23.
//

import Foundation
import SwiftHtml

class PSGHead: GroupTag {
    public init(preload: String? = nil, generationID: TSID) {
        let children = [
            Head {
                Title("Mike Cargal's Photography Site")
                Meta().charset("utf-8")
                Meta().name(.viewport).content("width=device-width, initial-scale=1")
                Link(rel: .stylesheet).href("css/styles.css?tsid=\(generationID)")
                Link(rel: .icon).href("/images/favicon.svg?tsid=\(generationID)").type("image/svg+xml")
                Link(rel: .manifest).href("/manifest.webmanifest?tsid=\(generationID)")
                if let preload {
                    Link(rel: .preload).href("\(preload)?tsid=\(generationID)").attribute("as", "image")
                }
            },
        ]
        super.init(children)
    }
}
