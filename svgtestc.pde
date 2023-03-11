import processing.svg.*;
import java.util.*;

MCorner[][] corners;
color [][] center;
int[][] domCount;

PImage test;

String imageToLoad = "t4.png";

void setup(){
  size(1000, 1000);
  
  
  noSmooth();
  background(0);
  generateSVG(imageToLoad);
  
  //todo:
  // add contour cases for image edges within cells [x]
  // generate contour from cells [x]
     // - create contour polygons [x]
     // - decimate useless vertexes.
     // - create hierachy of polygon being 'enclosed' in other polygons for holes and polygons within polygons
        // - some kind of color flood approach?
     // - finally draw clean polygon with appropriate backward contours for holes
   // export to svg [x]
   

}

void draw(){

}

void generateSVG(String imageloc){
  test = loadImage(imageloc);
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
  float scl = 8;
  //drawSquares(scl,corners,test,center,domCount);
  fill(0,100);
  rect(0,0,width,height);
  
  var cells = generateCells(scl,corners,test,center,domCount);
  
  beginRecord(SVG,imageloc.split("\\.")[0]+".svg");
  boolean[][] mapped = new boolean[test.width][test.height];
  for (int x = 0; x<test.width-1; x++) {
    for (int y = 0; y<test.height-1; y++) {
      if(!mapped[x][y] && cells[x][y].hasRoute && alpha(test.pixels[x+y*test.width])>0){
        var contour = getContour(cells,x,y,test.pixels[x+y*test.width],mapped);
        if(contour!=null){
           contour.draw(scl);
        }
      }
    }
  }
  endRecord();
}


Contour getContour(MSCell[][] cells, int x,int y, color c, boolean[][] mapped){
  var origin = cells[x][y];
  var current = origin;
  int cdir = -1;
  for(int i = 0;i<4;i++){
    if(origin.route[i]!=-1 && origin.corners[(i+3)%4].c == c){
      cdir = i;
    }
  }
  if(cdir==-1){
    return null;
  }
  int l = 0;
  ArrayList<PVector> contour = new ArrayList();
  while(true){
    contour.add(current.getVert(cdir));
    if(current == origin && l>1){
      break;
    }
    if(current.routeStops[cdir]!=null){
      contour.addAll(Arrays.asList(current.routeStops[cdir]));
    }
    
    for(int i = 0;i<4;i++){
      if(origin.corners[i].c == c){
        mapped[origin.corners[i].x][origin.corners[i].y] = true;
      }
    }
    cdir = current.route[cdir];
    
    if(cdir==-1){
      break;
    }
    //we went out of bound so traverse edge until we find a way back
    if(!inBounds(current.x ,current.y ,cdir ,cells)){
      int ax = current.x + dir[cdir][0];
      int ay = current.y + dir[cdir][1];
      contour.add(current.getAntiVert(cdir));
      int dd = getBoundsDir(ax,ay,cells.length,cells[0].length);
      while(true){
        ax+= dir[dd][0];
        ay+= dir[dd][1];
        if(inBounds(ax ,ay ,(dd+1)%4 ,cells)){
          var candidate = cells[ax + dir[(dd+1)%4][0]][ay + dir[(dd+1)%4][1]];
          if(candidate.hasRoute && candidate.route[(dd+1)%4]!=-1){
            current=candidate;
            cdir=(dd+1)%4;
            break;
          }
        }
        int pd = dd;
        dd = getBoundsDir(ax,ay,cells.length,cells[0].length);
        if(dd!=pd){
          contour.add(new PVector(constrain(ax,0,cells.length)+0.5,constrain(ay,0,cells.length)+0.5));
        }
      }
    }else{
      current = cells[current.x + dir[cdir][0]][current.y + dir[cdir][1]];
    }
    l++;
  }
  return new Contour(contour,c);

}

int getBoundsDir(int x,int y, int w,int h){
  if(y==-1 && x!= w){
    return 0;
  }
  if(y!=h && x== w){
    return 1;
  }
  if(y==h && x!= -1){
    return 2;
  }
  if(y!=-1 && x== -1){
    return 3;
  }
  return -1;
}

class Contour{
  color c;
  ArrayList<PVector> contour = new ArrayList();
  Contour(ArrayList<PVector> contour, color c){
    this.contour = contour;
    this.c=c;
  }
  
  void draw(float scl){
    fill(c);
    noStroke();
    beginShape(POLYGON);
    
    for(var v:contour){
      vertex(v.x*scl,v.y*scl);
    }
    endShape(CLOSE);
  }
}
