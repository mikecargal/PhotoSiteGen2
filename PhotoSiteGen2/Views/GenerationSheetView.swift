//
//  GenerationSheetView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/25/24.
//

import SwiftUI

struct GenerationSheetView: View {
    var websiteDocument: WebSiteDocument
    @Binding var showSheet: Bool

    @State private var generating = false

    @AppStorage("Inline Web Component CSS") private var inlineWebComponentCSS =
        true
    @AppStorage("Clean Build") private var cleanBuild = false
    @AppStorage("Minify Build") private var minify = false
    @AppStorage("Skip Static Content") private var skipStaticContent = false
    
    @State var generator: WebSiteGenerator?

    var body: some View {
        VStack {
            Form {
                Toggle(
                    "Inline CSS for Web Components",
                    isOn: $inlineWebComponentCSS)
                Toggle("Clean Build", isOn: $cleanBuild)
                Toggle("Minify", isOn: $minify)
                Toggle("Skip Static Content", isOn: $skipStaticContent)
            }
            .disabled(generating)
            Button(action: generate) {
                Text("Generate")
                Image(systemName: "wand.and.sparkles")
            }
            Spacer()
            if let generator {
                WebsiteGenStatusView(wsGenStatus: generator.generationStatus)
            }

            HStack {
                Spacer()
                Button("Dismiss") {
                    showSheet = false
                }
                .disabled(generating)
            }
        }
        .padding()
    }

    func generate() {
        generating = true
        Task {
            generator = websiteDocument.getWebsiteGenerator()
            guard
                let generator
            else {
                debugPrint("No generator")
                return
            }
            await generator.generate(
                inlineWebComponentCSS: inlineWebComponentCSS,
                cleanBuild: cleanBuild,
                minify: minify,
                skipStaticContent: skipStaticContent)
            generating = false
        }

    }
}

#Preview {
    GenerationSheetView(
        websiteDocument: WebSiteDocument.mock, showSheet: .constant(true))
}
