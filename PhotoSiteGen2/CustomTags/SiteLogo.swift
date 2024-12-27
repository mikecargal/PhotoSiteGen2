//
//  SiteIcon.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 12/11/23.
//

import SwiftHtml

open class SiteLogo: Tag {
    open override class func createNode() -> Node {
        Node(type: .standard, name: "site-logo")
    }
}
