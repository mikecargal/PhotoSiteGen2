//
//  GalleryLink.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 12/12/23.
//

import Foundation
import SwiftHtml

open class GalleryLink: Tag {
    open override class func createNode() -> Node {
        Node(type: .standard, name: "gallery-link")
    }
}


