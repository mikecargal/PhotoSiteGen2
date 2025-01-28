"use strict";

class SlideShow {
  constructor() {
    this.ssDiv = document.querySelector("#slideShow");
    if (!this.ssDiv) return;
    this.images = document.getElementsByTagName("gallery-image");
    this.currentIdx = -1;
    this.galleryName =
      document.querySelector("#gallery")?.attributes[
        "data-gallery-name"
      ]?.nodeValue;
    this.currentImg = document.querySelector("#current");
    this.prevImg = document.querySelector("#prev");
    this.prevSmallImg = document.querySelector("#prevSmall");
    this.nextImg = document.querySelector("#next");
    this.nextSmallImg = document.querySelector("#nextSmall");

    document
      .querySelector("#gotoPrev")
      .addEventListener("click", () => this.prevSlide());
    document
      .querySelector("#gotoNext")
      .addEventListener("click", () => this.nextSlide());
    const rsz = this.resize.bind(this);
    const debouncedResize = debounce((entry) => rsz(entry), 2);

    const resizeObserver = new ResizeObserver((entries) => {
      debouncedResize(entries[0]);
    });
    resizeObserver.observe(this.ssDiv);

    document.addEventListener("keydown", (event) => {
      if (this.showing) {
        switch (event.key) {
          case "ArrowLeft":
            this.prevSlide();
            event.stopPropagation();
            break;
          case "ArrowRight":
            this.nextSlide();
            event.stopPropagation();
            break;
          case "i":
            this.toggleInfo();
            break;
          case "ArrowUp":
          case "Escape":
          case "x":
          case "X":
            this.hide();
            break;
          // default: console.log(event.key);
        }
      }
    });
  }

  hideHeaderAndMenu() {
    const menu = document.getElementById("menu");
    this.menuWasVisible = !menu.classList.contains("hide");
    document.getElementsByTagName("header")[0].classList.add("hide");
    menu.classList.add("hide");
  }

  restoreHeaderAndMenu() {
    if (this.menuWasVisible) {
      document.getElementById("menu").classList.remove("hide");
    }
    document.getElementsByTagName("header")[0].classList.remove("hide");
  }

  show(idx) {
    this.showing = true;
    this.setCurrentIdx(idx);
    this.hideHeaderAndMenu();
    this.ssDiv.classList.remove("slideShowHidden");
    this.ssDiv.classList.add("slideShow");
  }

  showImage(e) {
    this.show(parseInt(e.target.getRootNode().host.idx));
  }

  hide() {
    this.showing = false;
    this.moveCurrentImgIntoView();
    this.restoreHeaderAndMenu();
    this.ssDiv.classList.add("slideShowHidden");
    this.ssDiv.classList.remove("slideShow");
    this.deleteSSIdx();
  }

  moveCurrentImgIntoView() {
    const scrollToImage = this.images[this.currentIdx];
    const scrollToImageTop = parseInt(scrollToImage.getAttribute("top"));
    const scrollToImageHeight = scrollToImage.getHeight();

    const galleryOffsetTop = parseInt(
      document.getElementById("gallery").offsetTop
    );

    const middleOffset = (window.innerHeight - scrollToImageHeight) / 2;

    window.scrollTo({
      top: scrollToImageTop + galleryOffsetTop - middleOffset,
      behavior: "smooth",
    });
  }

  nextSlide() {
    this.setCurrentIdx(this.nextIdx);
  }

  prevSlide() {
    this.setCurrentIdx(this.prevIdx);
  }

  setCurrentIdx(idx) {
    if (this.currentIdx === idx) {
      return;
    }
    this.currentIdx = idx;
    this.nextIdx = (idx + 1) % this.images.length;
    this.prevIdx = (idx + this.images.length - 1) % this.images.length;

    const currentGalleryImage = this.images[this.currentIdx];
    this.currentImg.blur();
    this.currentImg.setAttribute("src", currentGalleryImage.src);
    this.currentImg.setAttribute("thumbpct", currentGalleryImage.thumbpct);
    this.currentImg.setAttribute("ar", currentGalleryImage.ar);

    this.resize();

    document.getElementById("infoContainer").classList.add("hide");

    const nextImage = this.images[this.nextIdx];
    this.nextSmallImg.setAttribute(
      "src",
      nextImage.src.replace("/", "/w0512/")
    );
    fetch(nextImage.src.replace(".jpg", ".html"));
    let nextSrc = this.getSrcForWidth(
      nextImage.src,
      this.widthFromAR(window.innerWidth, window.innerHeight, nextImage.ar)
    );
    fetch(nextSrc);

    const prevImage = this.images[this.prevIdx];
    this.prevImg.setAttribute("src", prevImage.fadeInImage.getSrcForWidth());
    this.prevSmallImg.setAttribute(
      "src",
      prevImage.src.replace("/", "/w0512/")
    );
    fetch(prevImage.src.replace(".jpg", ".html"));
    let prevSrc = this.getSrcForWidth(
      prevImage.src,
      this.widthFromAR(window.innerWidth, window.innerHeight, prevImage.ar)
    );
    fetch(prevSrc);

    this.setSSIdx();
    this.moveCurrentImgIntoView();
    this.loadInfo(currentGalleryImage.src);
  }

  resize(entry) {
    if (this.currentIdx < 0) {
      return;
    }

    const ar = this.images[this.currentIdx].ar;
    let width;
    if (entry) {
      const cbs = entry.contentBoxSize[0]
        ? entry.contentBoxSize[0]
        : entry.contentBoxSize;
      width = this.widthFromAR(cbs.inlineSize, cbs.blockSize, ar);
    } else {
      width = this.widthFromAR(window.innerWidth, window.innerHeight, ar);
    }
    this.currentImg.setAttribute("imgwidth", width);
    this.currentImg.setAttribute("w", width);
    return width;
  }

  getSrcForWidth(src, imgWidth) {
    if (imgWidth <= 512) {
      return src.replace("/", "/w0512/");
    } else if (imgWidth <= 1024) {
      return src.replace("/", "/w1024/");
    } else if (imgWidth <= 2048) {
      return src.replace("/", "/w2048/");
    }
    return src;
  }

  widthFromAR(w, h, ar) {
    const war = w / h;
    const aspectRatio = parseFloat(ar);

    return war > aspectRatio // is wider than aspect ration?
      ? h * aspectRatio // size to height
      : w; // size to width
  }

  checkURL() {
    const ssIdx = this.readSSIdx();
    if (!isNaN(ssIdx)) {
      this.show(ssIdx);
    }
  }

  deleteSSIdx() {
    const url = new URL(window.location);
    url.searchParams.delete("ssidx");
    window.history.pushState(null, "", url.toString());
  }

  readSSIdx() {
    const url = new URL(window.location);
    return parseInt(url.searchParams.get("ssidx"));
  }

  setSSIdx() {
    const url = new URL(window.location);
    url.searchParams.set("ssidx", this.currentIdx);
    window.history.pushState(null, "", url.toString());
  }

  toggleInfo() {
    document.getElementById("infoContainer").classList.toggle("hide");
  }

  loadInfo(imgSrc) {
    if (!imgSrc) {
      return;
    }
    const infoHtmlURL = imgSrc.replace(/\.jpg$/, ".html");

    try {
      const fetchPromise = fetch(infoHtmlURL);
      fetchPromise.then((response) => {
        const htmlPromise = response.text();
        htmlPromise.then((html) => {
          const infoContainer = document.getElementById("infoContainer");
          infoContainer.innerHTML = html;
          const infoDiv = document.getElementById("info");
          const canvas = document.getElementById("cropCanvas");
          if (!canvas) {
            return;
          }
          this.drawCrop(canvas);
        });
      });
    } catch (error) {
      console.debug(error);
    }
  }

  drawCrop(canvas) {
    const ctx = canvas.getContext("2d");

    const cropData = JSON.parse(document.getElementById("cropInfo").innerHTML);
    ctx.fillStyle = "grey";
    ctx.beginPath();
    const original = cropData.original;
    ctx.moveTo(original.tl.x, original.tl.y);
    ctx.lineTo(original.tr.x, original.tr.y);
    ctx.lineTo(original.br.x, original.br.y);
    ctx.lineTo(original.bl.x, original.bl.y);
    ctx.lineTo(original.tl.x, original.tl.y);
    ctx.fill();

    const img = new Image();
    img.onload = function () {
      ctx.drawImage(
        img,
        cropData.img.pos.x,
        cropData.img.pos.y,
        cropData.img.wh.w,
        cropData.img.wh.h
      );
    };
    img.src = cropData.img.src;
  }
}
