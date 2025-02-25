"use strict";

class FadeInImage extends HTMLElement {
  static _masonrySizing;

  masonrySizing(ar) {
    const GUTTER = "4px";
    const bodyMargin = window.innerWidth - document.body.clientWidth;
    const cutoff3col = 1000 + bodyMargin;
    const cutoff4col = 1500 + bodyMargin;
    const cutoff5col = 2000 + bodyMargin;
    const sizing_by_col_count = {};
    for (let col_count of [2, 3, 4, 5]) {
      sizing_by_col_count[col_count] = `img {
             width: calc(((100vw - ${bodyMargin}px) / ${col_count}) - ${GUTTER}); 
             max-height: calc((((100vw - ${bodyMargin}px) / ${col_count}) - ${GUTTER}) / ${ar}); 
           }`;
    }
    const additionalSizing = `${sizing_by_col_count[2]}
       @media screen and (min-width: ${cutoff3col}px) {${sizing_by_col_count[3]}}
       @media screen and (min-width: ${cutoff4col}px) {${sizing_by_col_count[4]}}
       @media screen and (min-width: ${cutoff5col}px) {${sizing_by_col_count[5]}}
      `;
    const sizes = `sizes="(min-width: ${cutoff5col}px) 20vw, (min-width: ${cutoff4col}px) 25vw, (min-width: ${cutoff3col}px) 34vw, 50vw" `;
    return [additionalSizing, sizes];
  }

  constructor() {
    super();
    this.blurred = true;
    this.explicitSizing = this.hasAttribute("explicitSizing");
    const [additionalSizing, sizes] = this.hasAttribute("masonrySizing")
      ? this.masonrySizing(parseFloat(this.getAttribute("ar")))
      : ["", ""];

    this.attachShadow({ mode: "open" }).innerHTML = `
     <link rel=stylesheet href="css/fadeIn.css">
     <style>
       ${additionalSizing}
     </style>
     <div class="fadein">
       <div class="background">
         <img class="blurred" ${sizes}>
       </div>
     </div>`;
  }

  connectedCallback() {
    this.background = this.shadowRoot.querySelector("div.background");
    this.img = this.background.querySelector("img");
    this.img.addEventListener("load", () => {
      this.unblur();
    });

    this.ar = parseFloat(this.getAttribute("ar"));
    this.img.style.aspectRatio = `${this.ar}`;
    this.background.style.aspectRatio = `${this.ar}`;
  }

  unblur() {
    this.blurred = false;
    this.img.classList.remove("blurred");
    const savedBkgImg = this.background.style.backgroundImage;
    setTimeout(() => {
      if (this.background.style.backgroundImage === savedBkgImg) {
        this.background.style.backgroundImage = "none";
      }
    }, 100);
  }

  blur() {
    this.blurred = true;
    this.img.classList.add("blurred");
    this.background.style.backgroundImage = `url("${this.thumbsrc}")`;
  }

  getSrcForWidth() {
    let imgWidth = parseInt(this.imgwidth);
    if (imgWidth <= 512) {
      return this.src.replace("/", "/w0512/");
    } else if (imgWidth <= 1024) {
      return this.src.replace("/", "/w1024/");
    } else if (imgWidth <= 2048) {
      return this.src.replace("/", "/w2048/");
    }
    return this.src;
  }

  checkForLoadSrc() {
    if (this.src && this.imgwidth) {
      this.img.src = this.getSrcForWidth();
    }
  }

  static get observedAttributes() {
    return [
      "src",
      "alt",
      "ar",
      "thumbpct",
      "w",
      "thumbsrc",
      "explicitSizing",
      "imgwidth",
    ];
  }

  attributeChangedCallback(property, oldValue, newValue) {
    if (oldValue === newValue) return;
    this[property] = newValue;
    if (this.shadowRoot) {
      if (this.img) {
        if (property === "src") {
          this.checkForLoadSrc();
        }
        if (property === "alt") {
          this.img.alt = this.alt;
        }
        if (property === "ar") {
          this.ar = parseFloat(this.ar);
          this.img.style.aspectRatio = `${this.ar}`;
          this.background.style.aspectRatio = `${this.ar}`;
        }
        if (property === "w") {
          const w = parseFloat(newValue);
          this.img.style.width = `${w}px`;
        }
        if (property === "imgwidth") {
          this.checkForLoadSrc();
        }
      }
    }
    if (this.background && this.thumbsrc) {
      if (this.blurred) {
        this.background.style.backgroundImage = `url("${this.thumbsrc}")`;
        this.background.style.backgroundPositionY = `${this.thumbpct}`;
      }
    }
  }
}

customElements.define("fade-in-image", FadeInImage);

//===================================================

class GalleryBase extends HTMLElement {
  // connect component
  connectedCallback() {
    this.div = this.shadowRoot.querySelector("div");
    this.div.style.top = `${this.top}px`;
    this.div.style.left = `${this.left}px`;

    this.galleryName = this.getGalleryName();
    this.thumbsrc = this.getThumbSrc();
    this.altText = this.caption || this.imagesrc;

    this.img = this.div.querySelector("fade-in-image");
    this.src = `${this.galleryName}/${this.imagesrc}`;
    this.setAttribute("src", this.src);
    this.img.setAttribute("src", this.src);
    this.img.setAttribute("alt", this.altText);
    this.img.setAttribute("thumbsrc", this.thumbsrc);
  }

  getGalleryName() {
    return this.closest("[data-gallery-name]")?.getAttribute(
      "data-gallery-name"
    );
  }

    getThumbSrc() {
      return (
        this.closest("[thumbsrc]")?.getAttribute("thumbsrc") ||
        this.closest("[data-thumbsrc]")?.getAttribute("data-thumbsrc")
      );
    }

  getImage() {
    return this.closest("fade-in-image");
  }

  setCaptionShow(showIt) {
    if (this.captionDiv) {
      if (showIt) {
        this.captionDiv.classList.remove("hide");
      } else {
        this.captionDiv.classList.add("hide");
      }
    }
  }

  // component attributes
  static get observedAttributes() {
    return [
      "imagesrc",
      "alt",
      "top",
      "left",
      "caption",
      "idx",
      "thumbpct",
      "imgwidth",
    ];
  }

  // attribute change
  attributeChangedCallback(property, oldValue, newValue) {
    // console.log({ property, oldValue, newValue });
    if (oldValue === newValue) return;
    this[property] = newValue;
    if (this.shadowRoot) {
      const div = this.shadowRoot.querySelector("div");
      if (property === "top") {
        div.style.top = `${newValue}px`;
      }
      if (property === "left") {
        div.style.left = `${newValue}px`;
      }
      if (property === "imgwidth") {
        this.fadeInImage.setAttribute("imgwidth", newValue);
      }
    }
  }

  getHeight() {
    return this.div.clientHeight;
  }
}

//===================================================
class GalleryLink extends GalleryBase {
  constructor() {
    super();
    this.ar = this.getAttribute("ar");
    this.thumbpct = this.getAttribute("thumbpct");
    this.gallery = this.getAttribute("gallery");
    this.linkTxt = this.getAttribute("linkTxt");
    this.categories = this.getAttribute("categories").split("|");
    const categoriesHTML = this.categories.reduce(
      (accum, cat) => `${accum}<span>${cat}</span>`,
      ""
    );

    this.attachShadow({ mode: "open" }).innerHTML = `
    <link rel=stylesheet href="css/galleryLink.css"> 
    <div style="top:${this.top}px;left:${this.left}px;">
       <a href="${this.gallery}.html?ssidx=0">
         <fade-in-image ar="${this.ar}" thumbpct="${this.thumbpct}" masonrySizing></fade-in-image>
         <div>
           <h2>${this.linkTxt}</h2>
           <hr>
           ${categoriesHTML}
         </div>
       </a>
    </div>`;
    this.fadeInImage = this.shadowRoot.querySelector("fade-in-image");
  }

  getGalleryName() {
    return this.gallery;
  }
}

customElements.define("gallery-link", GalleryLink);

//===================================================

class GalleryImage extends GalleryBase {
  constructor() {
    super();
    this.ar = this.getAttribute("ar");
    this.thumbpct = this.getAttribute("thumbpct");

    const caption = this.getAttribute("caption");
    let captionDiv = caption
      ? `<div class="caption hide">${caption}</div>`
      : "";

    this.attachShadow({ mode: "open" }).innerHTML = `
    <link rel=stylesheet href="css/galleryImage.css">
    <div class="galleryImage" onclick="window.slideShow.showImage(event)">
        <fade-in-image ar="${this.ar}" thumbpct="${this.thumbpct}" masonrySizing></fade-in-image>
        ${captionDiv}
    </div>`;

    this.fadeInImage = this.shadowRoot.querySelector("fade-in-image");
    this.captionDiv = this.shadowRoot.querySelector(".caption");
  }
}

customElements.define("gallery-image", GalleryImage);

//===================================================

class SiteLogo extends HTMLElement {
  // connect component
  constructor() {
    super().attachShadow({ mode: "open" }).innerHTML = `
    <link rel=stylesheet href="css/siteLogo.css">
    <a id="homeLink" href="index.html">
     <img src="images/mikecargalphotographycombinedlogo.svg" alt="Mike Cargal Photography Logo" id="logo">
    </a>`;
  }

  connectedCallback() {
    const logoImgLoaded = (e) => {
      e.target.classList.add("loaded");
    };
    const icon = this.shadowRoot.querySelector("#logo");
    if (icon.complete) logoImgLoaded({ target: icon });
    else icon.onload = logoImgLoaded;
  }
}

customElements.define("site-logo", SiteLogo);
