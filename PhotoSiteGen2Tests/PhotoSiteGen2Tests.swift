//
//  PhotoSiteGen2Tests.swift
//  PhotoSiteGen2Tests
//
//  Created by Mike Cargal on 12/26/24.
//

import Testing
import Foundation

struct PhotoSiteGen2Tests {

    @Test func encodeDecodePhoto() async throws {
        let photo = try Photo(url: URL(string: "file:///Users/mike/Sites/photos.mikecargal.com/2024Jaguars/_CR57613.jpg")!)
        #expect(photo != nil)
        
        let encoded = try JSONEncoder().encode(photo)
        #expect(encoded != nil)
        
        let decoded = try JSONDecoder().decode(Photo.self, from: encoded)
        #expect(decoded != nil)
    }
    
    @Test func encodeDecodeURLPhotoDirctionary() async throws {
        let url = URL(string: "file:///Users/mike/Sites/photos.mikecargal.com/2024Jaguars/_CR57613.jpg")!
        let dict = [url:try Photo(url: url)]
        
        let encoded = try JSONEncoder().encode(dict)
        #expect(encoded != nil)
        
        let decoded = try JSONDecoder().decode([URL:Photo].self, from: encoded)
        #expect(decoded != nil)
        
    }
    
    @Test func encodeDecodeUUIDURLPhotoDictionary() async throws {
        let uuid = UUID()
        let url = URL(string: "file:///Users/mike/Sites/photos.mikecargal.com/2024Jaguars/_CR57613.jpg")!
        let dict: [UUID:[URL:Photo]] = [uuid: [url:try Photo(url: url)]]
        
       let encoded = try JSONEncoder().encode(dict)
        #expect(encoded != nil)
        
        let decoded = try JSONDecoder().decode([UUID:[URL:Photo]].self, from: encoded)
        #expect(decoded != nil)
    }

}
