//
//  ContentView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI

struct ContentView: View {
    @Binding var websiteDocument: WebSiteDocument

    @State var selection: DetailViewEnum?

    var body: some View {
        NavigationSplitView {
            ListingView(
                websiteDocument: $websiteDocument, selection: $selection
            )
            .frame(minWidth: 250)
        } detail: {
            switch selection {
            case .gallerySelection(let id):
                GalleryView(
                    galleryDocument: $websiteDocument.galleries.first(
                        where: { $0.id == id })!)
            default:  // .siteConfiguration:
                SiteConfigEditView(websiteDocument: $websiteDocument)
            }
        }
    }
}

#Preview {
    ContentView(websiteDocument: .constant(WebSiteDocument.mock))
}
