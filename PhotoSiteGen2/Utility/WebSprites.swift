//
//  WebSprites.swift
//  PhotoSiteGen
//
//  Created by Mike Cargal on 1/6/24.
//

import Foundation
import SwiftUI

enum SpriteGenerationError: Error {
    case ColorSpaceError, ContextCreationError
}

func generateSpritesImage(
    thumbPhotos: [Photo],
    width: Int,
    filename: URL,
    errorHandler: ErrorHandler,
    generationStatus: GalleryGenerationStatus?
) async -> [Double] {
    var percentages = [Double]()
    let totalHeight = thumbPhotos.reduce(0) {
        $0 + $1.heightOfImage(ofWidth: width)
    }

    guard
        let context = CGContext(
            data: nil,
            width: width,
            height: totalHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB)!,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
    else {
        await errorHandler.handleError(
            "creating CGContext for thumbnames\n\(filename)\nwidth: \(width), height: \(totalHeight)",
            SpriteGenerationError.ContextCreationError)
        return []
    }

    var top = totalHeight
    for photo in thumbPhotos {
        let height = photo.heightOfImage(ofWidth: width)
        percentages.append(
            getBackgroundYPositionPct(
                top: Double(top), totalHeight: Double(totalHeight),
                imgHeight: Double(height)))
        top -= height
        if let smallImage = photo.smallImage {
            context.draw(
                smallImage,
                in: CGRect(x: 0, y: top, width: width, height: height),
                byTiling: false)
        }
       async let _ = generationStatus?.progressTick()
    }
    writeJpegFromContext(context: context, filename: filename)
    return percentages
}

func getBackgroundYPositionPct(
    top: Double, totalHeight: Double, imgHeight: Double
) -> Double {
    let epsilon = 0.1 / totalHeight
    let bottom = top - imgHeight

    var minYPct = (totalHeight - top) / totalHeight
    var maxYPct = (totalHeight - bottom) / totalHeight

    var guessYPct = (maxYPct + minYPct) / 2
    var calculatedTop = calcTop(
        totalHeight: totalHeight, yPct: guessYPct, height: imgHeight)

    while abs(top - calculatedTop) > epsilon {
        if calculatedTop < top {
            maxYPct = guessYPct
        } else {
            minYPct = guessYPct
        }
        guessYPct = (maxYPct + minYPct) / 2
        calculatedTop = calcTop(
            totalHeight: totalHeight, yPct: guessYPct, height: imgHeight)
    }

    return guessYPct * 100
}

func calcTop(totalHeight: Double, yPct: Double, height: Double) -> Double {
    let pctAsPx = (totalHeight * yPct)
    let adjust = yPct * height
    return totalHeight - (pctAsPx - adjust)
}

func writeJpegFromContext(context: CGContext, filename: URL) {
    let cgImage = context.makeImage()!
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    let jpegData = bitmapRep.representation(
        using: NSBitmapImageRep.FileType.jpeg, properties: [:])!
    try! jpegData.write(to: filename)
}
