//
//  ContentView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI

struct ContentView: View {
    @Binding var websiteDocument: WebSiteDocument
    @State private var showConfiguration = false
    @State private var showGenerationSheet = false

    var body: some View {
        NavigationStack {
            TextField("Wbbsite Name", text: $websiteDocument.websiteName)
                .textFieldStyle(.plain)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
            if showConfiguration || !websiteDocument.configured {
                SiteConfigEditView(websiteDocument: $websiteDocument)
            }
            GalleryGridView(webSiteDocument: $websiteDocument)
        }
        .toolbar {
            Button {
                showGenerationSheet = true
            } label: {
                Text("Generate")
                Image(systemName: "wand.and.sparkles")
            }

            Button {
                showConfiguration.toggle()
            } label: {
                Image(systemName: "gear")
            }
        }
        .sheet(isPresented: $showGenerationSheet) {
            GenerationSheetView(
                websiteDocument: websiteDocument,
                showSheet: $showGenerationSheet)
        }
    }
}

#Preview {
    ContentView(websiteDocument: .constant(WebSiteDocument.mock))
}
