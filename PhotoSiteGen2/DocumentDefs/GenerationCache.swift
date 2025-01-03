//
//  GenerationCache.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 12/27/24.
//

import Foundation

struct GenerationCache: Codable {
    let galleryPhotosCache: [UUID: [URL: Photo]]

    func photos(for galleryId: UUID) -> [URL: Photo]? {
        galleryPhotosCache[galleryId]
    }

    func getCameras() -> [String: URL] {
        var cameras = [String: URL]()
        galleryPhotosCache.forEach { (uuid, dict) in
            dict.forEach { (url, photo) in
                if let camera = photo.metadata.camera {
                    if cameras[camera] == nil {
                        cameras[camera] = url
                    }
                }
            }
        }
        debugPrint("Cameras: \(cameras)")
        return cameras
    }
}
