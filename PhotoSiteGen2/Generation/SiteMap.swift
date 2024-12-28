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
    let siteMapNameSpaceURI = "http://www.sitemaps.org/schemas/sitemap/0.9"
    let imageNameSpaceURI = "http://www.google.com/schemas/sitemap-image/1.1"

    func getXMLDocument() -> XMLDocument {
        let rootElement = getRootElement()

        let document = XMLDocument(rootElement: rootElement)
        rootElement.addChild(getIndexUrlNode())

        let imageNSPrefix = rootElement.resolvePrefix(
            forNamespaceURI: imageNameSpaceURI)
        for gallery in galleries {
            rootElement.addChild(
                getGalleryUrlNode(
                    gallery: gallery, imageNSPrefix: imageNSPrefix!))
        }

        return document
    }

    func getRootElement() -> XMLElement {
        let rootElement = XMLElement(name: "urlset", uri: siteMapNameSpaceURI)
        rootElement.addNamespace(
            XMLNode.namespace(withName: "", stringValue: siteMapNameSpaceURI)
                as! XMLNode)
        rootElement.addNamespace(
            XMLNode.namespace(withName: "image", stringValue: imageNameSpaceURI)
                as! XMLNode)
        return rootElement
    }

    func getIndexUrlNode() -> XMLNode {
        let urlNode = XMLElement(name: "url", uri: siteMapNameSpaceURI)
        let locNode = XMLElement(name: "loc", uri: siteMapNameSpaceURI)
        urlNode.addChild(locNode)
        let textNode =
            XMLNode.text(
                withStringValue:
                    rootURL
                    .appendingPathComponent("index.html")
                    .absoluteString) as! XMLNode
        locNode.addChild(textNode)
        return urlNode
    }

    func getGalleryUrlNode(
        gallery: SiteMapGallery,
        imageNSPrefix: String
    )
        -> XMLElement
    {
        let urlNode = XMLElement(name: "url", uri: siteMapNameSpaceURI)
        let locNode = XMLElement(name: "loc", uri: siteMapNameSpaceURI)
        urlNode.addChild(locNode)

        let textNode =
            XMLNode.text(
                withStringValue:
                    rootURL
                    .appendingPathComponent("\(gallery.genName).html")
                    .absoluteString) as! XMLNode
        locNode.addChild(textNode)

        for image in gallery.images {
            urlNode.addChild(
                getGalleryImageNode(
                    gallery: gallery,
                    image: image,
                    imageNSPrefix: imageNSPrefix
                ))
        }
        return urlNode
    }

    private func getGalleryImageNode(
        gallery: SiteMapGallery,
        image: SiteMapImage,
        imageNSPrefix: String
    ) -> XMLElement {
        let imageNode = XMLElement(
            name: "\(imageNSPrefix):image",
            uri: imageNameSpaceURI)

        let locNode = XMLElement(
            name: "\(imageNSPrefix):loc",
            uri: imageNameSpaceURI)
        imageNode.addChild(locNode)

        locNode.addChild(
            XMLNode.text(
                withStringValue:
                    rootURL
                    .appendingPathComponent(
                        "\(gallery.genName)/\(image.name)"
                    )
                    .absoluteString) as! XMLNode)

        return imageNode
    }
}
