//
//  FolderSelector.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 11/10/24.
//

import SwiftUI

struct FolderSelector: View {
    let label: String
    var selectedFolder: URL
    var onChange: (URL) -> Void

    var body: some View {
        HStack {
            Text(label)
            Button {
                let panel = NSOpenPanel()
                panel.directoryURL = selectedFolder
                panel.allowsMultipleSelection = false
                panel.canChooseFiles = false
                panel.canChooseDirectories = true
                panel.canCreateDirectories = true

                if panel.runModal() == .OK {
                    if let url = panel.url {
                        onChange(url)
                    }
                }
            } label: {
                Image(systemName: "folder")
            }
            Text(selectedFolder.absoluteString)
        }
    }
}

#Preview {
    FolderSelector(
        label: "Select Folder",
        selectedFolder: FileManager.default.homeDirectoryForCurrentUser
    ) { url in }
}
