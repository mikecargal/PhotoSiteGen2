//
//  WSPage.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 11/21/23.
//

import Foundation
import SwiftHtml

class PSGPage: GroupTag {
    public init(generationID: TSID, jsFiles: [String], preload: String? = nil, @TagBuilder _ builder: @escaping () -> Tag) {
        let content = builder()
        let children = [
            Html {
                PSGHead(preload: preload, generationID: generationID)
                Body {
                    SiteLogo()
                    Main { content }
                }
                PSGJSFiles(jsFiles)
            }.lang("en-US"),
        ]
        super.init(children)
    }
}
