//
//  PSGJSFiles.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 12/11/23.
//

import Foundation
import SwiftHtml

class PSGJSFiles: GroupTag {
    public init(_ jsFiles: [String]) {
        super.init(jsFiles.map { Script().src($0) })
    }
}
