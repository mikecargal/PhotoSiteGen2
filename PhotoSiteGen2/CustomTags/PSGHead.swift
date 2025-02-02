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
                Text("<link rel=\"me\" href=\"https://mastodon.social/@Mikecargal\" />")
                Meta().name("fediverse:creator").content("@Mikecargal@mastodon.social")
                Link(rel: .stylesheet).href("css/styles.css?tsid=\(generationID)")
                Link(rel: .icon).href("/images/favicon.svg?tsid=\(generationID)").type("image/svg+xml")
                Link(rel: .manifest).href("/manifest.webmanifest?tsid=\(generationID)")
                for preload in preloads {
                    preload.link(generationID: generationID)
                }
            },
        ]
        super.init(children)
    }
}
