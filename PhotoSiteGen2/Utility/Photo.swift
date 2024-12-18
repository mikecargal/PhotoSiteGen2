//
//  Photo.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 12/15/23.
//

import AppKit
import Foundation

enum PhotoReadError: Error {
    case ImageSourceReadError(url: URL)
}

final class Photo: Identifiable, Comparable, Sendable {
    let url: URL
    let image: CGImage
    let smallImage: CGImage
    let aspectRatio: Double
    let metadata: ImageMetaData

    init(url: URL) throws {
        self.url = url
        let smallImageURL =
            url.deletingLastPathComponent()
            .appendingPathComponent("w0512")
            .appendingPathComponent(url.lastPathComponent)

        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)
        else {
            debugPrint("Couldn't create image source for \(url)")
            throw PhotoReadError.ImageSourceReadError(url: url)
        }
        guard
            let smallImageSource = CGImageSourceCreateWithURL(
                smallImageURL as CFURL, nil)
        else {
            debugPrint("Couldn't create image source for \(smallImageURL)")
            throw PhotoReadError.ImageSourceReadError(url: url)
        }
        metadata = ImageMetaData(url: url)
        aspectRatio = Double(metadata.pixelWidth) / Double(metadata.pixelHeight)

        let img = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        image = img!
        smallImage = CGImageSourceCreateImageAtIndex(smallImageSource, 0, nil)!
    }

    static func == (lhs: Photo, rhs: Photo) -> Bool {
        let lhStar = lhs.metadata.starRating
        let rhStar = rhs.metadata.starRating
        if lhStar != rhStar {
            return false
        }
        let lhDate = lhs.metadata.captureTime ?? ""
        let rhDate = rhs.metadata.captureTime ?? ""
        if lhDate != rhDate {
            return false
        }
        return lhs.filteredFileName() == rhs.filteredFileName()
    }

    static func < (lhs: Photo, rhs: Photo) -> Bool {
        let lhStar = lhs.metadata.starRating
        let rhStar = rhs.metadata.starRating
        if lhStar != rhStar {
            return lhStar > rhStar
        }
        let lhDate = lhs.metadata.captureTime ?? ""
        let rhDate = rhs.metadata.captureTime ?? ""
        if lhDate != rhDate {
            return lhDate < rhDate
        }
        return lhs.filteredFileName() < rhs.filteredFileName()
    }

    func filteredFileName() -> String {
        Self.filteredFileName(url)
    }

    func filteredFileNameWithExtension() -> String {
        Self.filteredFileNameWithExtension(url)
    }

    func srcset(genName: String) -> String {
        let imgName = filteredFileNameWithExtension()
        return
            "\(genName)\\w0512\\\(imgName) 512w, \(genName)\\w1024\\\(imgName) 1024w, \(genName)\\w2048\\\(imgName) 2048w, \(genName)\\\(imgName)"
    }

    static func filteredFileName(_ url: URL) -> String {
        let inParts = url.deletingPathExtension().lastPathComponent.split(
            separator: "-")

        var rest = inParts[1..<inParts.endIndex]
            .filter {
                $0.count < 3  // sequence numbers 2 digits at most (other will be date that Dxo puts on it)
                    && CharacterSet.decimalDigits.isSuperset(
                        of: CharacterSet(charactersIn: String($0)))
            }
        rest.insert(inParts.first!, at: 0)

        return rest.joined(separator: "-")
    }

    static func filteredFileNameWithExtension(_ url: URL?) -> String? {
        guard let url else { return nil }
        return filteredFileNameWithExtension(url)
    }

    static func filteredFileNameWithExtension(_ url: URL) -> String {

        return "\(Self.filteredFileName(url)).\(url.pathExtension)"
    }

    func heightOfImage(ofWidth width: Int) -> Int {
        return Int(ceil(Double(width) / aspectRatio))
    }
}
