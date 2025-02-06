"use strict";

function layout() {
  const wall = document.querySelector(".wall");
  if (!wall) return;
  const bricks = document.querySelectorAll("[class=brick]");
  const width = wall.clientWidth;
  const columnCount = getColumnsForWidth(width);
  const columnYIndices = Array(columnCount).fill(0);
  const imgWidth = width / columnCount;

  for (let idx = 0; idx < bricks.length; idx++) {
    const img = bricks[idx];
    img.setAttribute("idx", `${idx}`);

    const minY = Math.min(...columnYIndices);
    const minYIdx = columnYIndices.indexOf(minY);

    img.setAttribute("top", `${minY}`);
    img.setAttribute("left", `${imgWidth * minYIdx}`);
    img.setAttribute("imgWidth", `${imgWidth}`);

    const newMinY = minY + img.getHeight();
    columnYIndices[minYIdx] = newMinY;
  }
}

function showCaptions(showThem) {
  Array.from(document.getElementsByTagName("gallery-image")).forEach((image) =>
    image.setCaptionShow(showThem)
  );
  layout();
}
function showQR() {
  document.getElementById("QR").showPopover();
  document.getElementById("menu").hidePopover();
}

function dismissQR() {
  document.getElementById("QR").hidePopover();
}

function getColumnsForWidth(viewWidth) {
  if (viewWidth > 2000) return 5;
  if (viewWidth > 1500) return 4;
  if (viewWidth > 1000) return 3;
  return 2;
}
