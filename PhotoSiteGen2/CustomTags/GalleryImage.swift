//
//  GalleryImage.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 11/24/23.
//

import Foundation
import SwiftHtml

open class GalleryImage: Tag {
    open override class func createNode() -> Node {
        Node(type: .standard, name: "gallery-image")
    }
}

