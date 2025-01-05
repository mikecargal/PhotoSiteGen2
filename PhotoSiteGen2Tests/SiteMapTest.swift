//
//  SiteMapTest.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 12/26/24.
//

import Foundation
import OSLog
import Testing

struct SiteMapTests {
    private static let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: String(describing: Self.self)
        )
    
    @Test func testSiteMap() throws {
        let mySite = URL(string: "https://photos.mikecargal.com")!
        let galleries: [SiteMapGallery] = [
            .init(
                genName: "gallery1",
                images: [
                    .init(name: "image1.jpg"),
                    .init(name: "image2.jpg"),
                ]),
            .init(
                genName: "gallery2",
                images: [
                    .init(name: "image3.jpg"),
                    .init(name: "imag42.jpg"),
                ]),
        ]
        let siteMap = SiteMap(rootURL: mySite, galleries: galleries)
        let doc = siteMap.getXMLDocument()
        Self.logger.debug("\(doc.xmlString)")
        let xmlString = doc.xmlString
        #expect(
            xmlString.starts(
                with:
                    "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\" xmlns:image=\"http://www.google.com/schemas/sitemap-image/1.1\">"
            ))

        #expect(
            xmlString.contains(
                "<url><loc>https://photos.mikecargal.com/index.html</loc></url>"
            ))

        #expect(
            xmlString.contains(
                "<url><loc>https://photos.mikecargal.com/gallery1.html</loc>"
            ))

        #expect(
            xmlString.contains(
                "<image:image><image:loc>https://photos.mikecargal.com/gallery1/image1.jpg</image:loc></image:image>"
            ))

        #expect(
            xmlString.contains(
                "<image:image><image:loc>https://photos.mikecargal.com/gallery1/image2.jpg</image:loc></image:image>"
            ))
    }
}
