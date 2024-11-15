//
//  PhotoSiteGen2App.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI

@main
struct PhotoSiteGen2App: App {
    var body: some Scene {
        DocumentGroup(newDocument: WebSiteDocument()) { file in
            ContentView(websiteDocument: file.$document)
        }
    }
}
