"use strict";

class FadeInImage extends HTMLElement {
  static _masonrySizing;

  masonrySizing() {
    if (!FadeInImage._masonrySizing) {
      const GUTTER = "4px";
      const bodyMargin = window.innerWidth - document.body.clientWidth;
      const cutoff3col = 1000 + bodyMargin;
      const cutoff4col = 1500 + bodyMargin;
      const cutoff5col = 2000 + bodyMargin;
      const sizing_by_col_count = {};
      const ar = this.ar
      for (let col_count of [2, 3, 4, 5]) {
        sizing_by_col_count[col_count] =
          `img {
             width: calc(((100vw - ${bodyMargin}px) / ${col_count}) - ${GUTTER}); 
             max-height: calc((((100vw - ${bodyMargin}px) / ${col_count}) - ${GUTTER}) * ${ar});
           }`;
      }
      const additionalSizing = `${sizing_by_col_count[2]}
       @media screen and (min-width: ${cutoff3col}px) {${sizing_by_col_count[3]}}
       @media screen and (min-width: ${cutoff4col}px) {${sizing_by_col_count[4]}}
       @media screen and (min-width: ${cutoff5col}px) {${sizing_by_col_count[5]}}
      `;
      const sizes = `sizes="(min-width: ${cutoff5col}px) 20vw, (min-width: ${cutoff4col}px) 25vw, (min-width: ${cutoff3col}px) 34vw, 50vw" `;
      FadeInImage._masonrySizing = [additionalSizing, sizes];
    }
    return FadeInImage._masonrySizing;
  }

  constructor() {
    super();
    this.blurred = true;
    this.explicitSizing = this.hasAttribute("explicitSizing");
    const [additionalSizing, sizes] = this.hasAttribute("masonrySizing")
      ? this.masonrySizing()
      : ["", ""];

    this.attachShadow({ mode: "open" }).innerHTML = `
<!--      <link rel=stylesheet href="css/fadeIn.css"> -->
<style>
.fadein {
    overflow: hidden;
}

/*=============== blurred ==================*/
.background:has(.blurred) {
    filter: blur(var(--blur-px, 15px));
    background-size: 100%;
}

img.blurred {
    opacity: 0;
}

/*=============== NOT blurred ==================*/
.background:not(:has(.blurred)) {
    transition:
        opacity 500ms ease,
        filter 500ms ease;
}

img:not(.blurred) {
    object-fit: contain;
    opacity: 1;
}

</style>
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
    }, 500);
  }

  blur() {
    this.blurred = true;
    this.img.classList.add("blurred");
    this.background.style.backgroundImage = `url("${this.thumbsrc}")`;
  }

  static get observedAttributes() {
    return [
      "src",
      "alt",
      "ar",
      "srcset",
      "thumbpct",
      "w",
      "thumbsrc",
      "explicitSizing",
    ];
  }

  // attribute change
  attributeChangedCallback(property, oldValue, newValue) {
    if (oldValue === newValue) return;
    this[property] = newValue;
    if (this.shadowRoot) {
      //  this.implicitWidth = this.img?.clientWidth;

      if (this.img) {
        if (property === "src") {
          this.img.src = this.src;
        }
        if (property === "alt") {
          this.img.alt = this.alt;
        }
        if (property === "srcset") {
          this.img.srcset = this.srcset;
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

    this.srcset =
      `${this.galleryName}\\w0512\\${this.imagesrc} 512w, ` +
      `${this.galleryName}\\w1024\\${this.imagesrc} 1024w, ` +
      `${this.galleryName}\\w2048\\${this.imagesrc} 2048w, ` +
      `${this.galleryName}\\${this.imagesrc}`;

    this.img = this.div.querySelector("fade-in-image");
    this.img.setAttribute("srcset", this.srcset);
    this.img.setAttribute("alt", this.altText);
    this.img.setAttribute("thumbsrc", this.thumbsrc);
  }

  getGalleryName() {
    return this.closest("[data-gallery-name]")?.attributes["data-gallery-name"]
      ?.nodeValue;
  }

  getThumbSrc() {
    return this.closest("[thumbsrc]")?.attributes["thumbsrc"]?.nodeValue;
  }

  getImage() {
    return this.closest("fade-in-image");
  }

  // component attributes
  static get observedAttributes() {
    return ["imagesrc", "alt", "top", "left", "caption", "idx", "thumbpct"];
  }

  // attribute change
  attributeChangedCallback(property, oldValue, newValue) {
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
<!--     <link rel=stylesheet href="css/galleryLink.css"> -->
<style>
div {
    position: absolute;
    transition: all 500ms ease;
    content: "";
    background-size: 100%;
}

a {
    display: flex;
    flex-direction: row;
    justify-content: center;
}

a>div {
    flex-grow: 1;
    position: absolute;
    background-color: transparent;
    height: 100%;
    width: 100%;
    color: transparent;
    border: transparent;
    display: flex;
    flex-direction: column;
    justify-content: center;
}

a>div:hover {
    background-color: rgba(0, 0, 0, 0.4);
    color: white;
}

a>div>* {
    align-self: center;
}

hr {
    display: none;
}

a>div:hover>hr {
    display: block;
    width: 80%;
    transition: all 0.3s cubic-bezier(0.175, 0.885, 0.320, 1.275);
    border: 0;
    border-bottom: 2px solid white;
}

@media (hover: none) {
    a>div {
        color: white;
        background-color: rgba(0, 0, 0, 0.2)
    }

    h2,
    span {
        font-size: 0.8rem;
    }

    hr {
        display: block;
        width: 80%;
        border: 0;
        border-bottom: 2px solid white;
    }
}

</style>
    <div style="top:${this.top}px;left:${this.left}px;">
       <a href="${this.gallery}.html">
         <fade-in-image ar="${this.ar}" thumbpct="${this.thumbpct}" masonrySizing></fade-in-image>
         <div><h2>${this.linkTxt}</h2><hr>${categoriesHTML}</div>
       </a>
    </div>`;
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
    this.ar = this.attributes["ar"].nodeValue;
    this.thumbpct = this.getAttribute("thumbpct");

    const caption = this.getAttribute("caption");
    let captionDiv = caption ? `<div class="caption">${caption}</div>` : "";

    this.attachShadow({ mode: "open" }).innerHTML = `
<!--     <link rel=stylesheet href="css/galleryImage.css"> -->
<style>
.galleryImage {
    position: absolute;
    transition: all 500ms ease-in-out;
    content: "";
    background-size: 100%;
    cursor: pointer;
}

.caption {
    text-align: center;
/*    width: 100%;*/
    width: min-content;
    min-width: 100%;
    color: white;
    background-color: rgba(0, 0, 0, 0.3);
    font-weight: lighter;
    padding-top: 0.1rem;
    padding-bottom: 0.3rem;
}

</style>
    <div class="galleryImage"  onclick="window.slideShow.showImage(event)">
        <fade-in-image ar="${this.ar}" thumbpct="${this.thumbpct}" masonrySizing></fade-in-image>
        ${captionDiv}
    </div>`;
  }
}

customElements.define("gallery-image", GalleryImage);

//===================================================

class SiteLogo extends HTMLElement {
  // connect component
  constructor() {
    super().attachShadow({ mode: "open" }).innerHTML = `
<!--     <link rel=stylesheet href="css/siteLogo.css"> -->
<style>
a {
    text-decoration: none;
}

#logoicon {
    width: 4rem;
    height: 4rem;
}

#logotext {
    width: 20rem;
    height: 2rem;
}

#logoicon,
#logotext {
    background: linear-gradient(to left, #ff6a00, #ee0979);
    display: inline-block;
    opacity: 0;
}

#logoicon.loaded,
#logotext.loaded {
    opacity: 1;
    transition: opacity 1000ms ease;
}
</style>
    <header>
      <a href="index.html">
        <div id="logoicon"><img src="images/HummingBirdtransparentOnDarkGrey.svg" alt="HummingBirdLogo"></div>
        <div id="logotext"><img src="images/MikeCargalPhotography.svg" alt="Mike Cargal Photography"></div>
      </a>
    </header>`;
  }
  connectedCallback() {
    const logoImgLoaded = (e) => {
      e.target.parentNode.classList.add("loaded");
    };
    const icon = this.shadowRoot.querySelector("#logoicon img");
    if (icon.complete) logoImgLoaded({ target: icon });
    else icon.onload = logoImgLoaded;

    const text = this.shadowRoot.querySelector("#logotext img");
    if (text.complete) logoImgLoaded({ target: text });
    else text.onload = logoImgLoaded;
  }
}

customElements.define("site-logo", SiteLogo);
