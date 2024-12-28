//
//  PSGJSFiles.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 12/11/23.
//

import Foundation
import SwiftHtml

class PSGJSFiles: GroupTag {
    public init(_ jsFiles: [String], generationID: TSID) {
        super.init(
            jsFiles
                .map {
                    Script().src("\($0)?tsid=\(generationID)")
                })
    }
}
