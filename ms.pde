import processing.svg.*;

int[][] border = {{0, 0}, {-1, 0}, {-1, -1}, {0, -1}};
int[][] dir =  {{1, 0}, {0, 1}, {-1, 0}, {0, -1}};
// ->  v  <-  ^
int[][] corner =  {{1, 0}, {1, 1}, {0, 1}, {0, 0}};

class BorderedImage {
  PImage p ;
  color[][] pixels;
  BorderedImage(PImage p) {
    this.p=p;
    pixels = new color[p.width+2][p.height+2];
    for (int i = 0; i<p.pixels.length; i++) {
      int x = i % p.width;
      int y = i / p.width;
      pixels[x+1][y+1] = p.pixels[i];
    }
    for (int i = -1; i<=p.width; i++) {
      findNearest(i, -1);
      findNearest(i, pixels[0].length-2);
    }
    for (int i = -1; i<=p.height; i++) {
      findNearest(-1, i);
      findNearest(pixels.length-2, i);
    }
  }

  void findNearest(int x, int y) {
    pixels[x+1][y+1] = get(constrain(x, 0, pixels.length-2), constrain(y, 0, pixels[0].length-2));
  }

  color get(int x, int y) {
    return pixels[constrain(x+1, 0, pixels.length-1)][constrain(y+1, 0, pixels[0].length-1)];
  }
}

color getDominant(MCorner[] t) {
  HashMap<Integer, int[]> count  = new HashMap<>();
  for (int i = 0; i<t.length; i++) {
    if (!count.containsKey(t[i].c)) {
      count.put(t[i].c, new int[]{1});
    } else {
      count.get(t[i].c)[0] ++;
    }
  }
  color winner = t[0].c;
  for (int i = 1; i<t.length; i++) {
    if (count.get(t[i].c)[0] > count.get(winner)[0]) {
      winner = t[i].c;
    }
  }
  return winner;
}


int countMostFrequentColor(MCorner[] t) {
  HashMap<Integer, int[]> count  = new HashMap<>();
  color winner = t[0].c;
  for (int i = 0; i<t.length; i++) {
    if (!count.containsKey(t[i].c)) {
      count.put(t[i].c, new int[]{1});
    } else {
      count.get(t[i].c)[0] ++;
    }
    if (count.get(t[i].c)[0] > count.get(winner)[0]) {
      winner = t[i].c;
    }
  }
  return count.get(winner)[0];
}


class MSCell {
  MCorner[] corners;
/*
          ?              ▼
          ▲              │
          │              │
        ┌─┴┐             │
route──►│  ├─►?    ┌─────┴───
        └─┬┘       │     ▼
          │        │     │
          ▼   ── ◄─├─────┘
          ?        │
*/
//clockwise route of contour thru this cell
  int[] route;
  PVector[][] routeStops = new PVector[4][];
  color centerFill;
  boolean hasCenterFill;
  PVector centerPos;
  float px, py;
  int x,y;
  boolean hasRoute = true;
  MSCell(MCorner[] corners){
    this.corners = new MCorner[4];
    for(int i = 0;i<4;i++){
      this.corners[i] = corners[i];
    }
    x = corners[0].x;
    y = corners[0].y;
    px = x+1f;
    py = y+1f;
    route = new int[]{-1,-1,-1,-1};
  }
  
  //has vertex
  boolean hasVert(int i){
    return corners[i].vpos[i]>0;
  }
  
  PVector getVert(int d){
    d = (d+2)%4;
    return new PVector(px+dir[d][0]*0.5f,py+dir[d][1]*0.5f);
  }
  PVector getAntiVert(int d){
    return new PVector(px+dir[d][0]*0.5f,py+dir[d][1]*0.5f);
  }
}

PVector getVert(int x,int y,int d){
  d = (d+2)%4;
  return new PVector(x+0.5+dir[d][0]*0.5f,y+0.5+dir[d][1]*0.5f);
}

class MCorner {
  int x, y;
  float[] vpos = new float[4];
  color c;
  boolean isEmpty = true;
  boolean isCorner = false;

  public MCorner(BorderedImage p, int x, int y) {
    vpos[0]=-1;
    vpos[1]=-1;
    vpos[2]=-1;
    vpos[3]=-1;
    this.x=x;
    this.y=y;
    c = p.get(x, y);

    for (int i = 0; i<4; i++) {
      int ax = x;
      int ay = y;
      ax = dir[i][0]+x;
      ay = dir[i][1]+y;
      if (p.get(ax, ay)==c) {
        continue;
      } else {
        vpos[i] = 0.5f;
        isEmpty = false;
      }
    }
    if((x==0 && y == 0) || (x==p.p.width-1 && y == 0) || (x==p.p.width-1 && y == p.p.height-1) || (x==0 && y == p.p.height-1)){
      isCorner = true;
    }
    
  }
}

boolean inBounds(int x,int y,int d,Object[][] grid){
  x += dir[d][0];
  y += dir[d][1];
  return (x>=0 && y>=0 && x<grid.length && y<grid[x].length);
}

boolean inBounds(int x,int y,Object[][] grid){
  return (x>=0 && y>=0 && x<grid.length && y<grid[x].length);
}

MSCell[][] generateCells(float scl, MCorner[][] corners, PImage test, color[][] center, int domCount[][]) {
  MSCell[][] cells = new MSCell[corners.length-1][corners[0].length-1];
  MCorner quad[] = new MCorner[4];
   /*
 
              pixel boundaries
    
                    │
     ┌───────┐      │       ┌───────┐
     │quad[0]├──────┼──────►│quad[1]│
     └───┬───┘      │       └───┬───┘
         ▲          │           │
         │          │           │
         │          │           │
─────────┼────────── ───────────┼───────
         │          │           │
         │          │           ▼                       
     ┌───┴───┐      │       ┌───────┐
     │quad[3]│◄─────┼───────┤quad[2]│
     └───────┘      │       └───────┘
 
 
 */
 ArrayList<PVector> detours= new ArrayList();
  for (int x = 0; x<test.width-1; x++) {
    for (int y = 0; y<test.height-1; y++) {
      for (int z = 0; z<4; z++) {
        int forw = (z+3)%4;
        quad[z] = corners[x+corner[forw][0]][y+corner[forw][1]];
      }
      MSCell m = new MSCell(quad);
      boolean hasCenter =
        !(quad[0].vpos[0]>0 && quad[1].vpos[1]<0 && quad[2].vpos[2]>0 && quad[3].vpos[3]<0) &&
        !(quad[0].vpos[0]<0 && quad[1].vpos[1]>0 && quad[2].vpos[2]<0 && quad[3].vpos[3]>0);
      for (int z = 0; z<4; z++) {
        int back = (z+3)%4;
        int forw = (z+1)%4;
        // opposite sides so geometry goes thru center. thus center doesnt have a color
        if(m.hasVert(back) && !m.hasVert(z) && m.hasVert(forw)){
          hasCenter = false;
        }
      }
      if (domCount[x][y] == 1) {
        hasCenter = false;
      }
      m.hasCenterFill = false;
      if(hasCenter){
        m.hasCenterFill = true;
        m.centerFill = center[x][y];
      }
      cells[x][y] = m;
      if (quad[0].vpos[0]<0 && quad[1].vpos[1]<0 && quad[2].vpos[2]<0 && quad[3].vpos[3]<0) {
        //cell is filled square
        m.hasRoute = false;
      } else{
        calcRoute(m,cells);
      }
    }
  }
  
  for (int x = 0; x<test.width-1; x++) {
    for (int y = 0; y<test.height-1; y++) {
      for (int z = 0; z<4; z++) {
        int forw = (z+3)%4;
        quad[z] = corners[x+corner[forw][0]][y+corner[forw][1]];
      }
      MSCell m = cells[x][y];
      if (quad[0].vpos[0]<0 && quad[1].vpos[1]<0 && quad[2].vpos[2]<0 && quad[3].vpos[3]<0) {
        //cell is filled square
      } else{
         for (int z = 0; z<4; z++) {
          final int cz = z;
          final int back = (z+3)%4;
          final int forw = (z+1)%4;
          final int invz = (z+2)%4;
          if(!m.hasCenterFill){
            if(m.route[z] == forw && domCount[x][y] == 1){
              boolean bottom = check(x,y,invz, c->{return c.route[back] == cz && c.hasCenterFill;},cells);
              boolean side =  check(x,y,forw, c->{return c.route[forw] == invz && c.hasCenterFill;},cells);
              if(side && bottom){
                m.centerFill = quad[back].c;
                m.hasCenterFill = true;
              }
              
            }else if(m.route[z] == z){
              if(m.hasVert(z)){
                boolean top =    check(x,y,z,    c->{return c.route[cz] == forw && c.hasCenterFill;},cells);
                boolean bottom = check(x,y,invz, c->{return c.route[back] == cz && c.hasCenterFill;},cells);
                boolean side =   check(x,y,back, c->{return c.route[cz] == forw;},cells) || check(x,y,back, c->{return c.route[back] == cz;},cells);
                if((top && bottom)||(side && top)||(side && bottom)){
                  m.centerFill = quad[back].c;
                  m.hasCenterFill = true;
                }
              }
              else{
                boolean top =    check(x,y,z,    c->{return c.route[cz] == forw && c.hasCenterFill;},cells);
                boolean bottom = check(x,y,invz, c->{return c.route[back] == cz && c.hasCenterFill;},cells);
                if((top && bottom)){
                  m.centerFill = quad[back].c;
                  m.hasCenterFill = true;
                }
              }
            }
          }
          if(!m.hasCenterFill){
            boolean recentered = true;
            /*
            edge case
                 /
                /
            ___/____
             
            */
            if(m.route[z] == forw){
              if(m.route[back] == back
                && check(x,y,forw, c->{return c.route[back] == back;},cells)
                && check(x,y,invz, c->{return c.route[back] == cz;},cells)){
                  recentered = false;
                  m.centerPos = m.getAntiVert(back);
              }else if(m.route[invz] == invz
                && check(x,y,z, c->{return c.route[invz] == invz;},cells)
                && check(x,y,forw, c->{return c.route[cz] == back;},cells)){
                  recentered = false;
                  m.centerPos =(m.getAntiVert(z));
              }else if(m.route[invz] == invz
                && check(x,y,invz, c->{return c.route[cz] == cz;},cells)
                && check(x,y,forw, c->{return c.route[forw] == invz;},cells)){
                  recentered = false;
                  m.centerPos =(m.getAntiVert(z));
              }  
            }
            
            
            
            if(m.centerPos==null){
               m.centerPos = (new PVector(m.px,m.py));
            }
            
          }
        }
        for (int z = 0; z<4; z++) {
          final int cz = z;
          final int back = (z+3)%4;
          final int forw = (z+1)%4;
          final int invz = (z+2)%4;
          detours.clear();
          if(!m.hasCenterFill){
            detours.add(m.centerPos);
          }else{
            //route goes clockwise
            if(m.route[z] == forw){
              if(m.centerFill == quad[back].c && m.hasVert(back)){
                detours.add(m.getAntiVert(back));
                if(m.corners[forw].isCorner){
                 detours.add(new PVector(m.corners[forw].x+0.5f,m.corners[forw].y+0.5f));
                }
                detours.add(m.getAntiVert(z));
              }
            }else if(m.route[z] == z){
              if(m.hasCenterFill){
                detours.add(m.getAntiVert(m.centerFill==quad[back].c?back:forw));
              }
            }
          }
          m.routeStops[z] = detours.toArray(new PVector[]{});
        }
      }
    }
  }
  return cells;
}

boolean check(int x,int y,int d,Boolf<MSCell> cond, MSCell[][] grid){
  if(!inBounds(x,y,d,grid)){
    return false;
  }
  return cond.check(grid[x+dir[d][0]][y+dir[d][1]]);
}

boolean check(int x,int y,Boolf<MSCell> cond, MSCell[][] grid){
  if(!inBounds(x,y,grid)){
    return false;
  }
  return cond.check(grid[x][y]);
}

interface Boolf<T>{
  public boolean check(T t);
}


void calcRoute(MSCell m,MSCell[][] cells){
  var quad = m.corners;
  for (int z = 0; z<4; z++) {
    int back = (z+3)%4;
    int forw = (z+1)%4;
    int invz = (z+2)%4;
    color pivotColor = quad[z].c;
    //corner
    if(quad[back].c == quad[invz].c && m.hasVert(back)  && m.hasVert(forw)){
      m.route[z] = z;
    }else
    if(m.hasVert(invz) && m.hasVert(back)){
      if(!(m.hasCenterFill && m.centerFill == quad[back].c && m.centerFill == quad[forw].c)){ // if not cutting across a central block of color
        m.route[z] = forw;
      }else{
        m.route[z] = back;
        if(!inBounds(m.x,m.y,back,cells)){
          m.route[z] = forw;
        }
      }
      
    }else
    if(m.hasVert(back) && m.hasVert(z)){
      if(m.hasCenterFill && m.centerFill == pivotColor && quad[(z+2)%4].c == pivotColor){
        /*
              ┌─┐            ┌────┐
              │z├───────────►│forw│
              └─┘            └────┘
               ▲
               │    ┌──────┐
        ──z──► ├───►│center│
               │    │fill  │
               │    └──┬───┘
            ┌──┴─┐     │
            │back│     │
            └────┘     ▼
                      forw
                       │
                       ▼
        */
        m.route[z] = forw;
        //m.route[(forw + 2)%4] = (z + 2)%4;
      }else{
        /*
                      ▲
                      │
              ┌─┐    back    ┌────┐
              │z├───────────►│forw│
              └─┘     ▲      └────┘
               ▲      │
               │      │
        ──z──► ├──────┘
               │
               │
            ┌──┴─┐
            │back│
            └────┘
        */
        m.route[z] = back;
        //m.route[forw] = (z + 2)%4;
      }
    }else if(m.hasVert(back) && m.hasVert(forw)){
      m.route[z] = z;
    }
  }
}

void drawSquares(float scl, MCorner[][] corners, PImage test, color[][] center, int domCount[][]) {
  strokeWeight(scl/8);
  for (int i = 0; i<test.pixels.length; i++) {
    int x = i % test.width;
    int y = i / test.width;
    MCorner m = corners[x][y];
    if (!m.isEmpty) {
      stroke(x%2==0?255:0, 0, y%2==0?255:0);
      for (int z = 0; z<4; z++) {
        int forw = (z+1)%4;
        if (m.vpos[z] < 0 || m.vpos[forw] < 0) {
          continue;
        }
        line(scl*(x+dir[z][0]*m.vpos[z] +0.5), scl*(y+dir[z][1]*m.vpos[z] +0.5), scl*(x+dir[forw][0]*m.vpos[forw] +0.5), scl*(y+dir[forw][1]*m.vpos[forw] +0.5));
      }
    }
  }
  noStroke();
stroke(0);
  MCorner quad[] = new MCorner[4];
  for (int x = 0; x<test.width-1; x++) {
    for (int y = 0; y<test.height-1; y++) {
      for (int z = 0; z<4; z++) {
        int forw = (z+3)%4;
        quad[z] = corners[x+corner[forw][0]][y+corner[forw][1]];
      }
      boolean hasCenter =
        !(quad[0].vpos[0]>0 && quad[1].vpos[1]<0 && quad[2].vpos[2]>0 && quad[3].vpos[3]<0) &&
        !(quad[0].vpos[0]<0 && quad[1].vpos[1]>0 && quad[2].vpos[2]<0 && quad[3].vpos[3]>0);

      if (quad[0].vpos[0]<0 && quad[1].vpos[1]<0 && quad[2].vpos[2]<0 && quad[3].vpos[3]<0) {

        fill(center[x][y]);
        rect((x+0.5)*scl, (y+0.5)*scl, scl, scl);
      } else if (hasCenter) {
        if (domCount[x][y] > 1) {
          //todo: case for 2
            // check if its a corner
          
          //center
          beginShape(POLYGON);
          fill(center[x][y]);
          for (int z = 0; z<4; z++) {
            int forw = (z+1)%4;
            int back = (z+3)%4;
            if (quad[z].vpos[z]>0) {
              vertex(scl*(quad[z].x+dir[z][0]*quad[z].vpos[z]  +0.5), scl*(quad[z].y+dir[z][1]*quad[z].vpos[z] +0.5 ));
            }
            if (!(quad[z].vpos[z]>0 && quad[forw].vpos[forw]>0)) {
              vertex(scl*(quad[forw].x +0.5), scl*(quad[forw].y +0.5));
            }
          }
          endShape();
        }

        //corners
        beginShape(TRIANGLES);
        for (int z = 0; z<4; z++) {
          int forw = (z+1)%4;
          if ((quad[z].vpos[z]>0 && quad[forw].vpos[forw]>0)) {
            fill(quad[forw].c);
            vertex(scl*(quad[z].x+dir[z][0]*quad[z].vpos[z]  +0.5), scl*(quad[z].y+dir[z][1]*quad[z].vpos[z] +0.5 ));
            vertex(scl*(quad[forw].x +0.5), scl*(quad[forw].y +0.5));
            vertex(scl*(quad[forw].x+dir[forw][0]*quad[forw].vpos[forw]  +0.5), scl*(quad[forw].y+dir[forw][1]*quad[forw].vpos[forw] +0.5 ));
          }
        }
        endShape();
      } else {
        //edges.
        beginShape(QUADS);
        if ((quad[0].vpos[0]>0 && quad[1].vpos[1]<0 && quad[2].vpos[2]>0 && quad[3].vpos[3]<0)) {
          fill(quad[0].c);
          vertex(scl*(quad[0].x +0.5), scl*(quad[0].y +0.5));
          vertex(scl*(quad[0].x+dir[0][0]*quad[0].vpos[0]  +0.5), scl*(quad[0].y+dir[0][1]*quad[0].vpos[0] +0.5 ));
          vertex(scl*(quad[2].x+dir[2][0]*quad[2].vpos[2]  +0.5), scl*(quad[2].y+dir[2][1]*quad[2].vpos[2] +0.5 ));
          vertex(scl*(quad[3].x +0.5), scl*(quad[3].y +0.5));

          fill(quad[1].c);

          vertex(scl*(quad[0].x+dir[0][0]*quad[0].vpos[0]  +0.5), scl*(quad[0].y+dir[0][1]*quad[0].vpos[0] +0.5 ));
          vertex(scl*(quad[1].x +0.5), scl*(quad[1].y +0.5));
          vertex(scl*(quad[2].x +0.5), scl*(quad[2].y +0.5));
          vertex(scl*(quad[2].x+dir[2][0]*quad[2].vpos[2]  +0.5), scl*(quad[2].y+dir[2][1]*quad[2].vpos[2] +0.5 ));
        } else {
          fill(quad[1].c);
          vertex(scl*(quad[1].x +0.5), scl*(quad[1].y +0.5));
          vertex(scl*(quad[1].x+dir[1][0]*quad[1].vpos[1]  +0.5), scl*(quad[1].y+dir[1][1]*quad[1].vpos[1] +0.5 ));
          vertex(scl*(quad[3].x+dir[3][0]*quad[3].vpos[3]  +0.5), scl*(quad[3].y+dir[3][1]*quad[3].vpos[3] +0.5 ));
          vertex(scl*(quad[0].x +0.5), scl*(quad[0].y +0.5));

          fill(quad[2].c);

          vertex(scl*(quad[1].x+dir[1][0]*quad[1].vpos[1]  +0.5), scl*(quad[1].y+dir[1][1]*quad[1].vpos[1] +0.5 ));
          vertex(scl*(quad[2].x +0.5), scl*(quad[2].y +0.5));
          vertex(scl*(quad[3].x +0.5), scl*(quad[3].y +0.5));
          vertex(scl*(quad[3].x+dir[3][0]*quad[3].vpos[3]  +0.5), scl*(quad[3].y+dir[3][1]*quad[3].vpos[3] +0.5 ));
        }
        endShape();
      }
    }
  }
}
