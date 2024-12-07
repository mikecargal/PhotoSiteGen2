//
//  PreLoad.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 12/7/24.
//

import Foundation

struct PreLoad {
   let src: String
   let srcset: String?
   let asType: String
    
   init(src: String, srcset: String? = nil, asType: String = "image") {
        self.src = src
        self.srcset = srcset
        self.asType = asType
    }
}
