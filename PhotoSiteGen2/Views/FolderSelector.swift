//
//  FolderSelector.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI

struct FolderSelector: View {
    let label: String
    @Binding var selectedFolder: URL?
    var defaultFolder: URL? = URL.currentDirectory()
    var validate: ((URL) throws -> Void)? = nil
    @State var panelDelegate: PanelDelegate?

    var body: some View {
        HStack {
            LabeledContent(label) {
                Button {
                    let panel = NSOpenPanel()
                    panel.directoryURL = selectedFolder ?? defaultFolder
                    panel.allowsMultipleSelection = false
                    panel.canChooseFiles = false
                    panel.canChooseDirectories = true
                    panel.canCreateDirectories = true
                    if let validate {
                        panelDelegate = PanelDelegate(validate: validate)
                        panel.delegate = panelDelegate
                    }
                    if panel.runModal() == .OK {
                        if let url = panel.url {
                            selectedFolder = url
                        }
                    }
                } label: {
                    Image(systemName: "folder")
                }
                Text(
                    selectedFolder?.absoluteString ?? defaultFolder?
                        .absoluteString ?? "Select Folder")
            }
        }
    }

    class PanelDelegate: NSObject, NSOpenSavePanelDelegate {
        private var validate: (URL) throws -> Void

        init(validate: @escaping (URL) throws -> Void) {
            self.validate = validate
        }

        func panel(_ sender: Any, validate url: URL) throws {
            guard url.hasDirectoryPath else {
                throw NSError(domain: "Must be a directory", code: 1)
            }
            try validate(url)
        }
    }
}

#Preview {
    FolderSelector(
        label: "Select Folder",
        selectedFolder: .constant(
            FileManager.default.homeDirectoryForCurrentUser)
    )
}
