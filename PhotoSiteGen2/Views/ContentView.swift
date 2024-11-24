//
//  ContentView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI

struct ContentView: View {
    @Binding var websiteDocument: WebSiteDocument
    @State var reRender = false
    @State private var showConfiguration = false

    var body: some View {
        NavigationStack {
            TextField("Wbbsite Name", text: $websiteDocument.websiteName)
                .textFieldStyle(.plain)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
            if showConfiguration || !websiteDocument.configured {
                SiteConfigEditView(websiteDocument: $websiteDocument)
            }
            if reRender {
                GalleryGridView(webSiteDocument: $websiteDocument)
            }

        }
        .toolbar {
            Button(action: generate) {
                Text("Generate")
                Image(systemName: "wand.and.sparkles")
            }

            Button {
                showConfiguration.toggle()
            } label: {
                Image(systemName: "gear")
            }
        }
        .onAppear {
            websiteDocument.adoptGalleries()
            reRender = true
        }
    }

    func generate() {
        Task {
            let logger = Logger()
            let generator = websiteDocument.getWebsiteGenerator(logger: logger)
            guard let generator else {
                debugPrint("No generator")
                return
            }
            await generator.generate(
                inlineWebComponentCSS: true,
                cleanBuild: true,
                minify: true)

        }

    }
}

#Preview {
    ContentView(websiteDocument: .constant(WebSiteDocument.mock))
}
