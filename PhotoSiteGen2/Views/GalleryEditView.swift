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
//        let galleryDir = webSiteDocument.sourceFolder!.appending(
//            path: "galleries/")
        FolderSelector(
            label: "Source Directory",
            selectedFolder: Binding(
                get: {
                    galleryDocument.gallerySourceUrl(
                        webSiteDocument: webSiteDocument)
                },
                set: {
                    if let url = $0 {
                        let relativeURL = url.relativePath(from:webSiteDocument.sourceFolder!)!
                        print(relativeURL)
                        print(URL(fileURLWithPath: relativeURL, relativeTo: webSiteDocument.sourceFolder).absoluteString)
                        $galleryDocument.wrappedValue.directory =
                            url.lastPathComponent
                    }
                }
            ) //,
//            validate: { url in
//                if url.deletingLastPathComponent().deletingPathExtension()
//                    != galleryDir
//                {
//                    throw NSError(
//                        domain: "Must be a folder within 'galleries' folder",
//                        code: 2)
//                }
//            }
        )
    }

    @ViewBuilder
    func titleImageEditView() -> some View {
        let imageUrl = galleryDocument.titleImageUrl(
            webSiteDocument: webSiteDocument)
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
            let imageDirectory = galleryDocument.gallerySourceUrl(
                webSiteDocument: webSiteDocument)
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
        func panel(
            _ sender: Any,
            shouldEnable url: URL
        ) -> Bool {
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

//extension URL {
//    /// SwiftyRelativePath: Creates a path between two paths
//    ///
//    ///     let u1 = URL(fileURLWithPath: "/Users/Mozart/Music/Nachtmusik.mp3")!
//    ///     let u2 = URL(fileURLWithPath: "/Users/Mozart/Documents")!
//    ///     u1.relativePath(from: u2)  // "../Music/Nachtmusik.mp3"
//    ///
//    /// Case (in)sensitivity is not handled.
//    ///
//    /// It is assumed that given URLs are absolute. Not relative.
//    ///
//    /// This method doesn't access the filesystem. It assumes no symlinks.
//    ///
//    /// `"."` and `".."` in the given URLs are removed.
//    ///
//    /// - Parameter base: The `base` url must be an absolute path to a directory.
//    ///
//    /// - Returns: The returned path is relative to the `base` path.
//    ///
//    public func relativePathFrom(base: URL) -> String? {
//        // Original code written by Martin R. https://stackoverflow.com/a/48360631/78336
//
//        // Ensure that both URLs represent files
//        guard self.isFileURL && base.isFileURL else {
//            return nil
//        }
//
//        // Ensure that it's absolute paths. Ignore relative paths.
//        guard self.baseURL == nil && base.baseURL == nil else {
//            return nil
//        }
//
//        // Remove/replace "." and "..", make paths absolute
//        let destComponents = self.standardizedFileURL.pathComponents
//        let baseComponents = base.standardizedFileURL.pathComponents
//
//        // Find number of common path components
//        var i = 0
//        while i < destComponents.count && i < baseComponents.count
//            && destComponents[i] == baseComponents[i] {
//                i += 1
//        }
//
//        // Build relative path
//        var relComponents = Array(repeating: "..", count: baseComponents.count - i)
//        relComponents.append(contentsOf: destComponents[i...])
//        return relComponents.joined(separator: "/")
//    }
//}
