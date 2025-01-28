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
                Img(src: "/images/burger.svg", alt: "menu")
                    .id("menuIcon")
                    .onClick(
                        "document.getElementById('menu').classList.toggle('hide')"
                    )
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
                }
                .id("socialLinks")
            }
            .id("menu")
            .class("hide"),
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
