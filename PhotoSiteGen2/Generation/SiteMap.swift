//
//  SiteMap.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 12/26/24.
//

import Foundation

struct SiteMapImage {
    let name: String
}

struct SiteMapGallery {
    let genName: String
    let images: [SiteMapImage]
}

struct SiteMap {
    let rootURL: URL
    let galleries: [SiteMapGallery]


    func getXMLDocument() -> XMLDocument {
        let siteMapNameSpaceURI = "http://www.sitemaps.org/schemas/sitemap/0.9"
        let imageNameSpaceURI = "http://www.google.com/schemas/sitemap-image/1.1"

        let rootElement = XMLElement(name: "urlset", uri: siteMapNameSpaceURI)

        rootElement.addNamespace(
            XMLNode.namespace(withName: "", stringValue: siteMapNameSpaceURI)
                as! XMLNode)
        rootElement.addNamespace(
            XMLNode.namespace(withName: "image", stringValue: imageNameSpaceURI)
                as! XMLNode)
        let document = XMLDocument(rootElement: rootElement)

        let urlNode = XMLElement(name: "url", uri: siteMapNameSpaceURI)
        rootElement.addChild(urlNode)

        let locNode = XMLElement(name: "loc", uri: siteMapNameSpaceURI)
        locNode.addChild(
            XMLNode.text(
                withStringValue:
                    rootURL
                    .appendingPathComponent("index.html")
                    .absoluteString) as! XMLNode)
        urlNode.addChild(locNode)

        for gallery in galleries {
            let galleryNode = XMLElement(name: "url", uri: siteMapNameSpaceURI)
            rootElement.addChild(galleryNode)

            let locNode = XMLElement(name: "loc", uri: siteMapNameSpaceURI)
            locNode.addChild(
                XMLNode.text(
                    withStringValue:
                        rootURL
                        .appendingPathComponent("\(gallery.genName).html")
                        .absoluteString) as! XMLNode)
            galleryNode.addChild(locNode)

            let imageNSPrefix = rootElement.resolvePrefix(
                forNamespaceURI: imageNameSpaceURI)!
            for image in gallery.images {

                let imageNode = XMLElement(
                    name: "\(imageNSPrefix):image",
                    uri: imageNameSpaceURI)
                galleryNode.addChild(imageNode)

                let locNode = XMLElement(
                    name: "\(imageNSPrefix):loc",
                    uri: imageNameSpaceURI)
                locNode.addChild(
                    XMLNode.text(
                        withStringValue:
                            rootURL
                            .appendingPathComponent(
                                "\(gallery.genName)/\(image.name)"
                            )
                            .absoluteString) as! XMLNode)
                imageNode.addChild(locNode)
            }
        }

        return document
    }
}
