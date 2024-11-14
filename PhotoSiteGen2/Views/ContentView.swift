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
            if let selection {
                switch selection {
                case .noSelection:
                    Text("Select a page to edit")
                case .siteConfiguration:
                    SiteConfigEditView(websiteDocument: $websiteDocument)
                case .gallerySelection(let id):
                    GalleryView(
                        galleryDocument: $websiteDocument.galleries.first(
                            where: { $0.id == id })!)
                }
            } else {
                Text("Select a page to edit")
            }

        }
    }
}

#Preview {
    ContentView(websiteDocument: .constant(WebSiteDocument.mock))
}
