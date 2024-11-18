//
//  FadeInImage.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 12/19/23.
//

import SwiftHtml

open class FadeInImage: Tag {
    open override class func createNode() -> Node {
        Node(type: .standard, name: "fade-in-image")
    }
}


