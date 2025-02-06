//
//  Header.swift
//  PhotoSiteGen2
//
//  Created by Mike Cargal on 1/23/25.
//

import Foundation
import SwiftHtml

class SiteHeader: GroupTag {
    public init(canShowCaptions: Bool) {
        super.init([
            Header {
                SiteLogo()
                Button().id("menuIcon").attribute("popovertarget", "menu")
            },
            Div {
                if canShowCaptions {
                    Label {
                        Input().type(.checkbox)
                            .id("showCaptions")
                            .onClick("showCaptions(this.checked)")
                        Text("Show Captions")
                    }
                    Hr()
                }
                Div {
                    Self.instagramLink()
                    Self.pixelFedLink()
                    Img(src: "/images/photositeqr.svg", alt: "show QR Code")
                        .onClick("showQR()")
                }
                .id("socialLinks")
            }
            .id("menu")
            .flagAttribute("popover"),
            Div {
                Img(
                    src: "/images/photositeqr.svg",
                    alt: "QR Code for https://photos.mikecargal.com")
            }.id("QR").flagAttribute("popover").onClick("dismissQR()"),
        ])
    }

    private static func instagramLink() -> A {
        A {
            Img(
                src: "/images/instagramOnTransparent.svg",
                alt: "link to Instagram @mikecargal")
            Text(" @mikecargal")
        }
        .id("igLink")
        .href("https://www.instagram.com/mikecargal/")
        .target(.blank)
    }

    private static func pixelFedLink() -> A {
        A {
            Img(
                src: "/images/pixelfed.svg",
                alt:
                    "Link to PixelFed @mikecargal@pixelfed.social"
            )
            Text(" @mikecargal")
        }
        .id("pfLink")
        .href("https://pixelfed.social/mikecargal")
        .target(.blank)
    }

}
