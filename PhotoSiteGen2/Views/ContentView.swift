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
                webSiteDocument: $websiteDocument, selection: $selection
            )
            .frame(minWidth: 250)
        } detail: {
            if let selection {
                selection.viewForDocument($websiteDocument)
            } else {
                EmptyView()
            }
        }
        .onAppear {
            websiteDocument.adoptGalleries()
            selection = .siteConfiguration  // forces rerender after adoption
        }
    }
}

#Preview {
    ContentView(websiteDocument: .constant(WebSiteDocument.mock))
}
