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

  show(idx) {
    this.showing = true;
    this.setCurrentIdx(idx);
    this.ssDiv.classList.remove("slideShowHidden");
    this.ssDiv.classList.add("slideShow");
  }

  showImage(e) {
    this.show(parseInt(e.target.getRootNode().host.idx));
  }

  hide() {
    this.showing = false;
    this.moveCurrentImgIntoView();
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
    this.currentImg.setAttribute("srcset", currentGalleryImage.srcset);
    this.currentImg.setAttribute("thumbpct", currentGalleryImage.thumbpct);
    this.currentImg.setAttribute("ar", currentGalleryImage.ar);

    this.resize();

    document.getElementById("infoContainer").classList.add("hide");

    const nextImage = this.images[this.nextIdx];
    this.nextImg.setAttribute("src", nextImage.src);
    this.nextImg.setAttribute("srcset", nextImage.srcset);
    this.nextSmallImg.setAttribute(
      "src",
      nextImage.src.replace("/", "/w0512/")
    );
    fetch(this.nextImg.src.replace(".jpg", ".html"));

    const prevImage = this.images[this.prevIdx];
    this.prevImg.setAttribute("src", prevImage.src);
    this.prevImg.setAttribute("srcset", prevImage.srcset);
    this.prevSmallImg.setAttribute(
      "src",
      prevImage.src.replace("/", "/w0512/")
    );
    fetch(this.prevImg.src.replace(".jpg", ".html"));

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
    this.currentImg.setAttribute("w", width);
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
          const parms = {
            width: parseInt(canvas.getAttribute("data-width")),
            height: parseInt(canvas.getAttribute("data-height")),
            top: parseInt(canvas.getAttribute("data-croptop")),
            bottom: parseInt(canvas.getAttribute("data-cropbottom")),
            left: parseInt(canvas.getAttribute("data-cropleft")),
            right: parseInt(canvas.getAttribute("data-cropright")),
            angle: parseInt(canvas.getAttribute("data-cropangle")),
            imageSrc: canvas.getAttribute("data-imagesrc"),
          };
          this.drawCrop(canvas, parms);
        });
      });
    } catch (error) {
      console.debug(error);
    }
  }

  drawCrop(canvas, crop) {
    const { width, height, top, bottom, left, right, angle, imageSrc } = crop;
    const cropW = right - left;
    const cropH = bottom - top;
    const img = new Image();
    img.onload = function () {
      if (canvas.getContext) {
        const ctx = canvas.getContext("2d");
        ctx.fillStyle = "rgb(100,100,100)";
        ctx.fillRect(0, 0, width, height);
        ctx.clearRect(left, top, cropW, cropH);
        ctx.drawImage(img, left, top, cropW, cropH);
      }
    };
    img.src = imageSrc;
  }
}
