//
//  CategoryView.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI

struct GalleryEditView: View {
    @Binding var galleryDocument: GalleryDocument
    var webSiteDocument: WebSiteDocument

    @State private var showTitleImageName: Bool = false

    @State var panelDelegate: PanelDelegate?

    var body: some View {
        Form {
            Spacer()
            titleImageEditView()
            Spacer()
            TextField("Title", text: $galleryDocument.title)
            sourceDirectorySelector()

            Spacer()
        }
        .padding()
    }

    @ViewBuilder
    func sourceDirectorySelector() -> some View {
        FolderSelector(
            label: "Source Directory",
            selectedFolder: Binding(
                get: {
                    galleryDocument.gallerySourceUrl
                },
                set: { url in
                    $galleryDocument.wrappedValue.directory =
                        url.relativePath(from: webSiteDocument.sourceFolder)!
                }
            ),
            selectedPathIsRelative: true
        )
    }

    @ViewBuilder
    func titleImageEditView() -> some View {
        let imageUrl = galleryDocument.titleImageUrl
        HStack(alignment: .bottom) {
            if let imageUrl {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: imageUrl) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        case .failure:
                            Image(systemName: "photo")
                                .resizable()
                                .frame(width: 200, height: 200)
                        @unknown default:
                            EmptyView()
                        }
                    }

                    Button {
                        showTitleImageName.toggle()
                    } label: {
                        Image(systemName: "info.circle")
                    }
                }
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .frame(width: 200, height: 200)
            }
            imagePicker()
        }
        if showTitleImageName {
            Text(galleryDocument.titleImageName)
        }
    }

    @ViewBuilder
    func imagePicker() -> some View {
        Button {
            let panel = NSOpenPanel()
            let imageDirectory = galleryDocument.gallerySourceUrl
            panel.directoryURL = imageDirectory
            panel.allowsMultipleSelection = false
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.canCreateDirectories = false
            panel.allowedContentTypes = [.image]
            panel.isAccessoryViewDisclosed = false
            panel.title = "Select Image"
            panelDelegate = PanelDelegate(imageDirectory.absoluteString)
            panel.delegate = panelDelegate!

            if panel.runModal() == .OK {
                if let url = panel.url {
                    $galleryDocument.wrappedValue
                        .titleImageName = url.lastPathComponent
                }
            }
        } label: {
            Image(systemName: "photo")
        }
    }

    class PanelDelegate: NSObject, NSOpenSavePanelDelegate {
        var galleryImageDirectoryPath: String
        
        init(_ galleryImageDirectoryPath: String) {
            self.galleryImageDirectoryPath = galleryImageDirectoryPath
        }
        
        func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
            return url.hasDirectoryPath
                ? galleryImageDirectoryPath.starts(with: url.absoluteString)
                : url.deletingLastPathComponent().absoluteString
                    == galleryImageDirectoryPath
        }
    }
}

#Preview {
    GalleryEditView(
        galleryDocument: .constant(GalleryDocument.mock), webSiteDocument: .mock
    )
}
