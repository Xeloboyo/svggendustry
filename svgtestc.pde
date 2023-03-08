
MCorner[][] corners;
color [][] center;
int[][] domCount;

PImage test;

void setup(){
  size(800, 800);
  test = loadImage("t2.png");
  test.loadPixels();
  noSmooth();
  background(0);
  corners = new MCorner[test.width][test.height];
  center = new color[corners.length-1][corners[0].length-1];
  domCount = new int[center.length][center[0].length];
  BorderedImage bimg = new BorderedImage(test);
  for (int i = 0; i<test.pixels.length; i++) {
    int x = i % test.width;
    int y = i / test.width;
    corners[x][y] = new MCorner(bimg, x, y);
  }
  MCorner quad[] = new MCorner[4];
  for (int x = 0; x<test.width-1; x++) {
    for (int y = 0; y<test.height-1; y++) {
      for (int z = 0; z<4; z++) {
        int forw = (z+3)%4;
        quad[z] = corners[x+corner[forw][0]][y+corner[forw][1]];
      }
      center[x][y] = getDominant(quad);
      domCount[x][y] = countMostFrequentColor(quad);
    }
  }
  drawSquares(8,corners,test,center,domCount);
  
  var cells = generateCells(8,corners,test,center,domCount);
  //todo:
  // add contour cases for image edges within cells
  // generate contour from cells
     // - create contour polygons
     // - decimate useless vertexes.
     // - create hierachy of polygon being 'enclosed' in other polygons for holes and polygons within polygons
        // - some kind of color flood approach?
     // - finally draw clean polygon with appropriate backward contours for holes
   // export to svg
}

void draw(){

}
