//
//  Gallery.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 7/1/24.
//

import Foundation
import SwiftUI
//
//@Observable
//@MainActor
//class GalleryModel: Identifiable {
//    struct GenerationInfo {
//        var sequenceNumber: Int
//        var titleImageFileName: String?
//        var title: String
//        var name: String
//        var categories: [String]
//    }
//
//    func getGenerationInfo() -> GenerationInfo {
//        GenerationInfo(sequenceNumber: sequenceNumber,
//                       titleImageFileName: titleImageFileName,
//                       title: title,
//                       name: name,
//                       categories: categories)
//    }
//
//    let id: String
//    var categories: [String]
//    var title: String
//    var name: String
//    var sequenceNumber: Int
//    private(set) var generationProgress = 0.0
//
//    private var siteSrcDirectory: URL?
//    private var jsonName: String?
//    private var renamer: Renamer?
//    private var cachedImageURL: URL?
//
//    var titleImageURL: URL? {
//        get {
//            if let cachedImageURL {
//                return cachedImageURL
//            }
//            guard let siteSrcDirectory else { return nil }
//            do {
//                cachedImageURL = try? FileManager.default.contentsOfDirectory(
//                    at: siteSrcDirectory
//                        .appendingPathComponent(name)
//                        .appendingPathComponent("w0512"),
//                    includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
//                    options: [.skipsHiddenFiles])
//                    .filter { !$0.hasDirectoryPath }
//                    .first {
//                        print("jsonName: \(String(describing: jsonName))")
//                        print("$0 \($0.path()) (\(String(describing: renamer?($0))) (\($0.deletingPathExtension().lastPathComponent))")
//                        return jsonName == renamer?($0) ?? $0.deletingPathExtension().lastPathComponent
//                    }
//            }
//            return cachedImageURL
//        }
//        set {
//            cachedImageURL = newValue
//        }
//    }
//
//    var titleImageFileName: String? {
//        guard let titleImageURL else { return nil }
//        return Photo.filteredFileNameWithExtension(titleImageURL)
//    }
//
//    convenience init() {
//        self.init(name: "", title: "")
//    }
//
//    convenience init(name: String,
//                     title: String,
//                     categories: [String] = [],
//                     sequenceNumber: Int = 0,
//                     jsonName: String? = nil,
//                     siteSrcDirectory: URL,
//                     renamer: Renamer?) {
//        self.init(name: name,
//                  title: title,
//                  categories: categories,
//                  sequenceNumber: sequenceNumber)
//        self.jsonName = jsonName
//        self.siteSrcDirectory = siteSrcDirectory
//        self.renamer = renamer
//    }
//
//    init(name: String,
//         title: String,
//         categories: [String] = [],
//         titleImageURL: URL? = nil,
//         sequenceNumber: Int = 0) {
//        id = name
//        cachedImageURL = titleImageURL
//        self.categories = categories
//        self.title = title
//        self.name = name
//        self.sequenceNumber = sequenceNumber
//        jsonName = jsonName
//    }
//
//    func titleImage(siteSrcDirectory: URL, renamer: Renamer? = nil) -> AsyncImage<some View> {
//        let url = titleImageURL(siteSrcDirectory: siteSrcDirectory, jsonName: jsonName)
//        return AsyncImage(url: url) { phase in
//            if let image = phase.image {
//                image // Displays the loaded image.
//            } else if phase.error != nil {
//                Color.red // Indicates an error.
//            } else {
//                Color.blue // Acts as a placeholder.
//            }
//        }
//    }
//
//    private func titleImageURL(siteSrcDirectory: URL, jsonName: String?, renamer: Renamer? = nil) -> URL? {
//        do {
//            let results = try? FileManager.default.contentsOfDirectory(
//                at: siteSrcDirectory.appendingPathComponent(name),
//                includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
//                options: [.skipsHiddenFiles])
//                .filter { !$0.hasDirectoryPath }
//                .filter {
//                    print("\(String(describing: jsonName)) \(renamer?($0.deletingPathExtension()) ?? "no renamer")")
//                    return jsonName == renamer?($0) ?? $0.deletingPathExtension().lastPathComponent
//                }
//            if results?.count == 1 {
//                return results!.first
//            }
//        }
//        return nil
//    }
//}
