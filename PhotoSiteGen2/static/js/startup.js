"use strict";

function startup() {
  if (layout) layout();
  const ss = new SlideShow();
  window.slideShow = ss;
  ss.checkURL();
  const debouncedLayout = debounce(layout);

  const wall = document.querySelector(".wall");
  if (wall) {
    const resizeObserver = new ResizeObserver(() => {
      debouncedLayout();
    });
    resizeObserver.observe(wall);
  }
}

// debounce to not allow calls to stack up
function debounce(func, timeout = 2) {
  let timer;
  return (...args) => {
    clearTimeout(timer);
    timer = setTimeout(() => {
      func.apply(this, args);
    }, timeout);
  };
}

// We can startup immediately after document is loaded
//   Don't need to wait for images
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", startup);
} else {
  startup();
}
