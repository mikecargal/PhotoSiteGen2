//
//  PhotoSiteGen2Tests.swift
//  PhotoSiteGen2Tests
//
//  Created by Mike Cargal on 12/26/24.
//

import Foundation
import Testing
import OSLog



struct PhotoSiteGen2Tests {
    private static let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: String(describing: Self.self)
        )
    
    @Test func encodeDecodePhoto() async throws {
        let photo = try Photo(
            url: URL(
                string:
                    "file:///Users/mike/Sites/photos.mikecargal.com/2024Jaguars/_CR57613.jpg"
            )!, genName: "2024Jaguars")
        #expect(photo != nil)

        let encoded = try JSONEncoder().encode(photo)
        #expect(encoded != nil)

        let decoded = try JSONDecoder().decode(Photo.self, from: encoded)
        #expect(decoded != nil)
    }

    @Test func encodeDecodeURLPhotoDirctionary() async throws {
        let url = URL(
            string:
                "file:///Users/mike/Sites/photos.mikecargal.com/2024Jaguars/_CR57613.jpg"
        )!
        let dict = [url: try Photo(url: url, genName: "2024Jaguars")]

        let encoded = try JSONEncoder().encode(dict)
        #expect(encoded != nil)

        let decoded = try JSONDecoder().decode([URL: Photo].self, from: encoded)
        #expect(decoded != nil)

    }

    @Test func encodeDecodeUUIDURLPhotoDictionary() async throws {
        let uuid = UUID()
        let url = URL(
            string:
                "file:///Users/mike/Sites/photos.mikecargal.com/2024Jaguars/_CR57613.jpg"
        )!
        let dict: [UUID: [URL: Photo]] = [uuid: [url: try Photo(url: url, genName: "2024Jaguars")]]

        let encoded = try JSONEncoder().encode(dict)
        #expect(encoded != nil)

        let decoded = try JSONDecoder().decode(
            [UUID: [URL: Photo]].self, from: encoded)
        #expect(decoded != nil)
    }

    @Test func cropInfoGeneration() async throws {
        let cropRenderer = CropRenderer(
            imageW: 4870,
            imageH: 3247,
            angle: 2.49,
            cropTop: 0.00012,
            cropBottom: 0.99988,
            cropLeft: 0.044335,
            cropRight: 0.955665,
            imageSrc: "2011MachuPicchu/w0512/_MG_8665.jpg",
            orientation: .orient0)

        let cropInfo = cropRenderer.getCropInfo(maxWH: 200)
        Self.logger.debug( "\(try! JSONEncoder().encode(cropInfo))")
        
        #expect(cropInfo != nil)
        #expect(floor(cropInfo.br.v1.x) == 0)
        #expect(floor(cropInfo.br.v1.y) == 40)
        #expect(floor(cropInfo.br.v2.x) == 194)
        #expect(floor(cropInfo.br.v2.y) == 31)
        #expect(floor(cropInfo.br.v3.x) == 200)
        #expect(floor(cropInfo.br.v3.y) == 161)
        #expect(floor(cropInfo.br.v4.x) == 5)
        #expect(floor(cropInfo.br.v4.y) == 169)
        #expect(floor(cropInfo.img.pos.x) == 8)
        #expect(floor(cropInfo.img.pos.y) == 39)
        #expect(floor(cropInfo.img.wh.w) == 182)
        #expect(floor(cropInfo.img.wh.h) == 121)

    }

    @Test func cropInfoGenerationNoAngle() async throws {
        let cropRenderer = CropRenderer(
            imageW: 4870,
            imageH: 3247,
            angle: 0,
            cropTop: 0.00012,
            cropBottom: 0.99988,
            cropLeft: 0.044335,
            cropRight: 0.955665,
            imageSrc: "2011MachuPicchu/w0512/_MG_8665.jpg",
        orientation: .orient0)

        let cropInfo = cropRenderer.getCropInfo(maxWH: 500)

        Self.logger.debug( "\(try! JSONEncoder().encode(cropInfo))")
        
        #expect(cropInfo != nil)
        #expect(floor(cropInfo.br.v1.x) == 0)
        #expect(floor(cropInfo.br.v1.y) == 98)
        #expect(floor(cropInfo.br.v2.x) == 500)
        #expect(floor(cropInfo.br.v2.y) == 98)
        #expect(floor(cropInfo.br.v3.x) == 500)
        #expect(floor(cropInfo.br.v3.y) == 401)
        #expect(floor(cropInfo.br.v4.x) == 0)
        #expect(floor(cropInfo.br.v4.y) == 401)
        #expect(floor(cropInfo.img.pos.x) == 22)
        #expect(floor(cropInfo.img.pos.y) == 98)
        #expect(floor(cropInfo.img.wh.w) == 455)
        #expect(floor(cropInfo.img.wh.h) == 303)
    }
    
    @Test(.disabled())
    func cropInfoGenerationPortrait() async throws {
        let cropRenderer = CropRenderer(
            imageW: 2823,
            imageH: 3384,
            angle: 0,
            cropTop: 0.0,
            cropBottom: 1.0,
            cropLeft: 0.113932,
            cropRight: 0.913612,
            imageSrc: "2023Delhi\\w0512\\_CR56970.jpg",
            orientation: .orient0)
        
        let cropInfo = cropRenderer.getCropInfo(maxWH: 200)
        Self.logger.debug( "\(try! JSONEncoder().encode(cropInfo))")
        
        #expect(cropInfo != nil)
        #expect(floor(cropInfo.br.v1.x) == 0)
        #expect(floor(cropInfo.br.v1.y) == 98)
        #expect(floor(cropInfo.br.v2.x) == 500)
        #expect(floor(cropInfo.br.v2.y) == 98)
        #expect(floor(cropInfo.br.v3.x) == 500)
        #expect(floor(cropInfo.br.v3.y) == 401)
        #expect(floor(cropInfo.br.v4.x) == 0)
        #expect(floor(cropInfo.br.v4.y) == 401)
        #expect(floor(cropInfo.img.pos.x) == 22)
        #expect(floor(cropInfo.img.pos.y) == 98)
        #expect(floor(cropInfo.img.wh.w) == 455)
        #expect(floor(cropInfo.img.wh.h) == 303)
    }
}
