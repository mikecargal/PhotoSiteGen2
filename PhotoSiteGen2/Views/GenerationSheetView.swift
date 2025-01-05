//
//  GenerationSheetView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/25/24.
//

import AVKit
import OSLog
import SwiftUI

struct GenerationSheetView: View {
    private static let logger = Logger(
            subsystem: Bundle.main.bundleIdentifier!,
            category: String(describing: Self.self)
        )

    @Binding var websiteDocument: WebSiteDocument
    @Binding var showSheet: Bool

    @State private var generating = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var generationTask: Task<Void, Error>?

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
                if generating {
                    Button("Cancel") {
                        generationTask?.cancel()
                    }
                }

                Spacer()
                Button("Dismiss") {
                    showSheet = false
                }
                .disabled(generating)
            }
        }
        .padding()
        .onAppear {
            if let path = Bundle.main.path(
                forResource: "notification.mp3", ofType: nil)
            {
                let url = URL(fileURLWithPath: path)
                audioPlayer = try? AVAudioPlayer(contentsOf: url)
            }
        }
    }

    func generate() {
        generating = true
        generationTask = Task {
            Self.logger.info("\(Date()) - Generating website")
            generator = websiteDocument.getWebsiteGenerator(
                cleanBuild: cleanBuild)
            guard
                let generator
            else {
                Self.logger.error("No generator")
                return
            }
            websiteDocument.generationCache =
                await generator.generate(
                    inlineWebComponentCSS: inlineWebComponentCSS,
                    cleanBuild: cleanBuild,
                    minify: minify,
                    skipStaticContent: skipStaticContent)
            generating = false
            Self.logger.info("\(Date()) - Generation complete")
            audioPlayer?.play()
        }

    }
}

#Preview {
    GenerationSheetView(
        websiteDocument: .constant(WebSiteDocument.mock),
        showSheet: .constant(true))
}
